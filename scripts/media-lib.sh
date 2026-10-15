# shellcheck shell=bash
# Shared helpers for scripts/media-replicate.sh and scripts/media-restore.sh (sourced).
# rclone runs in a container (no host install); remotes are configured through
# RCLONE_CONFIG_<NAME>_* environment variables, passed to `docker run` by name only so
# secrets never show up in the process list.
#   src: primary media bucket   (S3_ENDPOINT / S3_REGION / S3_BUCKET / S3_ACCESS_KEY / S3_SECRET_KEY)
#   dst: replica bucket         (MEDIA_REPLICA_*, keys of the separate backup project; review V-16)
# Layout of the replica bucket:
#   <same keys as the primary>                 mirror of the primary (usable as a bucket on its own)
#   _replica-archive/<YYYYMMDDTHHMMSSZ>/<key>  objects the primary deleted or overwrote in that run
# Media keys never start with "_" (orgs/, leases/, invoices/, passports/, conversations/).

ENV_FILE="${ENV_FILE:-/opt/terra/infra/hetzner/compose/.env}"
RCLONE_IMAGE="${RCLONE_IMAGE:-rclone/rclone:1.71.0}"
# shellcheck disable=SC2034 # used by the scripts that source this file
ARCHIVE_PREFIX="_replica-archive"

mlog() { echo "[$(date -u +%FT%TZ)] $*"; }

# Loads .env (unless the variables are already set, e.g. in a drill) and exports the rclone remotes.
media_env() {
  if [ -z "${S3_BUCKET:-}" ] || [ -z "${MEDIA_REPLICA_BUCKET:-}" ]; then
    [ -r "$ENV_FILE" ] || { mlog "cannot read $ENV_FILE"; return 1; }
    set -a
    # shellcheck disable=SC1090
    . "$ENV_FILE"
    set +a
  fi
  : "${S3_ENDPOINT:?S3_ENDPOINT missing}" "${S3_BUCKET:?S3_BUCKET missing}"
  : "${S3_ACCESS_KEY:?S3_ACCESS_KEY missing}" "${S3_SECRET_KEY:?S3_SECRET_KEY missing}"
  : "${MEDIA_REPLICA_ENDPOINT:?MEDIA_REPLICA_ENDPOINT missing}" "${MEDIA_REPLICA_BUCKET:?MEDIA_REPLICA_BUCKET missing}"
  # The replica must not be deletable with the media keys the app VM holds (review V-16).
  if [ -z "${MEDIA_REPLICA_ACCESS_KEY:-}" ] || [ "${MEDIA_REPLICA_ACCESS_KEY:-}" = "$S3_ACCESS_KEY" ]; then
    if [ "${MEDIA_REPLICA_ALLOW_SHARED_KEYS:-0}" != 1 ]; then
      mlog "MEDIA_REPLICA_ACCESS_KEY is empty or equals S3_ACCESS_KEY: use keys of the separate backup project (docs/runbooks/backup.md) or set MEDIA_REPLICA_ALLOW_SHARED_KEYS=1 for a drill"
      return 1
    fi
    mlog "warning: replica uses the media keys (MEDIA_REPLICA_ALLOW_SHARED_KEYS=1)"
  fi

  export RCLONE_CONFIG_SRC_TYPE=s3 RCLONE_CONFIG_SRC_PROVIDER=Other
  export RCLONE_CONFIG_SRC_ENDPOINT="https://${S3_ENDPOINT#https://}"
  export RCLONE_CONFIG_SRC_REGION="${S3_REGION:-fsn1}"
  export RCLONE_CONFIG_SRC_ACCESS_KEY_ID="$S3_ACCESS_KEY"
  export RCLONE_CONFIG_SRC_SECRET_ACCESS_KEY="$S3_SECRET_KEY"
  export RCLONE_CONFIG_SRC_NO_CHECK_BUCKET=true

  export RCLONE_CONFIG_DST_TYPE=s3 RCLONE_CONFIG_DST_PROVIDER=Other
  export RCLONE_CONFIG_DST_ENDPOINT="https://${MEDIA_REPLICA_ENDPOINT#https://}"
  export RCLONE_CONFIG_DST_REGION="${MEDIA_REPLICA_REGION:-nbg1}"
  export RCLONE_CONFIG_DST_ACCESS_KEY_ID="${MEDIA_REPLICA_ACCESS_KEY:-$S3_ACCESS_KEY}"
  export RCLONE_CONFIG_DST_SECRET_ACCESS_KEY="${MEDIA_REPLICA_SECRET_KEY:-$S3_SECRET_KEY}"
  export RCLONE_CONFIG_DST_NO_CHECK_BUCKET=true
}

rclone() {
  local envs=() v
  for v in $(compgen -e | grep '^RCLONE_'); do envs+=(-e "$v"); done
  docker run --rm --network host "${envs[@]}" "$RCLONE_IMAGE" "$@"
}
