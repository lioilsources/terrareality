#!/usr/bin/env bash
# Restores media from the replica bucket (see scripts/media-replicate.sh, docs/runbooks/restore.md
# scenario E). Never deletes anything on the target: it uses `rclone copy`, so restoring into a live
# bucket only adds/overwrites the selected objects.
#
#   scripts/media-restore.sh check
#       replica reachable and listable: prints object count/size of mirror and archive runs. Exit 1 if
#       the replica cannot be listed or the mirror is empty. Cheap; used by the weekly check and drills.
#   scripts/media-restore.sh list-archive [<prefix>]
#       archive runs (_replica-archive/<UTC stamp>/), or objects under <prefix> in the archive.
#   scripts/media-restore.sh restore [--from mirror|<archive stamp>] [--prefix <key prefix>]
#                                    [--to <bucket>] [--dry-run]
#       copies mirror (default) or one archive run back to the primary bucket (S3_BUCKET) or to
#       --to <bucket> on the primary endpoint (e.g. a fresh bucket after the old one was lost).
#       --prefix limits it to e.g. orgs/<org id>/ or leases/<lease id>/.
#
# Runs on the DB VM as deploy (Docker + jq, .env as for the replication). Always run with --dry-run
# first and read the list.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source-path=SCRIPTDIR source=media-lib.sh
. "$here/media-lib.sh"

usage() { sed -n '2,20p' "$0" >&2; exit 2; }

media_env
DST="dst:$MEDIA_REPLICA_BUCKET"
cmd="${1:-}"; [ $# -gt 0 ] && shift

case "$cmd" in
  check)
    mlog "listing replica $DST"
    mirror=$(rclone size --json --fast-list --exclude "/$ARCHIVE_PREFIX/**" "$DST") || { mlog "FAIL: replica not listable"; exit 1; }
    objects=$(jq -r .count <<<"$mirror")
    mlog "mirror: $objects objects, $(jq -r .bytes <<<"$mirror") bytes"
    runs=$(rclone lsf --dirs-only "$DST/$ARCHIVE_PREFIX/" 2>/dev/null | wc -l | tr -d ' ')
    mlog "archive runs kept: $runs (newest: $(rclone lsf --dirs-only "$DST/$ARCHIVE_PREFIX/" 2>/dev/null | sort | tail -1))"
    mlog "sample objects:"; rclone lsf -R --files-only --max-depth 4 --exclude "/$ARCHIVE_PREFIX/**" "$DST" 2>/dev/null | head -5 | sed 's/^/  /' || true
    [ "$objects" -gt 0 ] || { mlog "FAIL: mirror is empty"; exit 1; }
    mlog "ok"
    ;;
  list-archive)
    if [ $# -eq 0 ]; then
      rclone lsf --dirs-only "$DST/$ARCHIVE_PREFIX/" | sort
    else
      rclone lsf -R --files-only --format tsp "$DST/$ARCHIVE_PREFIX/" --include "/*/${1#/}**"
    fi
    ;;
  restore)
    from=mirror prefix="" to="$S3_BUCKET" dry=()
    while [ $# -gt 0 ]; do
      case "$1" in
        --from) from="$2"; shift 2 ;;
        --prefix) prefix="${2#/}"; shift 2 ;;
        --to) to="$2"; shift 2 ;;
        --dry-run) dry=(--dry-run); shift ;;
        *) usage ;;
      esac
    done
    if [ "$from" = mirror ]; then
      src="$DST/$prefix"
      filter=(--exclude "/$ARCHIVE_PREFIX/**")
    else
      [[ "$from" =~ ^[0-9]{8}T[0-9]{6}Z$ ]] || { mlog "--from must be 'mirror' or an archive stamp (list-archive)"; exit 2; }
      src="$DST/$ARCHIVE_PREFIX/$from/$prefix"
      filter=()
    fi
    target="src:$to/$prefix"
    mlog "restore $src -> $target ${dry[*]:-}"
    rclone copy "$src" "$target" "${filter[@]}" --checksum --fast-list --transfers 8 --checkers 16 \
      --retries 3 --log-level INFO --stats 1m --stats-one-line "${dry[@]}"
    mlog "done; verify in the app (listing photos via imgproxy, a lease PDF) and run media-replicate.sh --dry-run"
    ;;
  *) usage ;;
esac
