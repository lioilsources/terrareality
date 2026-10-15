# Runbook: seed Praha (addresses, boundaries, pilot owners)

Launch region for M8 is Praha and its surroundings (Praha 1–22, Praha-východ/-západ towns, Beroun, Kladno,
Mělník). Everything below runs with `terractl` against the target database (`DATABASE_URL`, `APP_ENV`,
`WEB_BASE_URL` from the environment). Nothing here needs network access unless you pass `--url`.

## 1. Addresses (RÚIAN "Adresní místa")

Official source: ČÚZK open data, monthly CSV export of all address points, one file per municipality,
semicolon separated, windows-1250:

    https://vdp.cuzk.cz/vymenny_format/csv/<YYYYMMDD>_OB_ADR_csv.zip

`<YYYYMMDD>` is the last day of the previous month (e.g. `20260930_OB_ADR_csv.zip`). The index of exports is
at https://vdp.cuzk.cz/ (Výměnný formát RÚIAN → CSV → Adresní místa). Licence: CC BY 4.0, attribute ČÚZK.

    # offline / dev: embedded sample (2 synthetic points per Praha district and nearby town)
    terractl import-ruian --region praha

    # production: download the latest export and keep only the region
    terractl import-ruian --region praha --url official

    # or from a file downloaded beforehand (ZIP or a single CSV)
    terractl import-ruian --region praha --file ~/Downloads/20260930_OB_ADR_csv.zip

The region filter keeps the municipalities listed in `services/api/internal/ruian/region.go` (Praha 554782,
Říčany, Brandýs n. L.-St. Boleslav, Úvaly, Čelákovice, Jesenice, Černošice, Roztoky, Hostivice, Rudná,
Beroun, Kladno, Mělník). ZIP entries of other municipalities are skipped without reading. The command prints
a warning listing municipalities with no rows: if one appears after a real import, its code in `region.go`
is wrong; fix it from the RÚIAN register of municipalities. Re-running is safe (upsert by address code).

Expected size: roughly 100 000 address points for Praha alone; the import runs in batches of 5 000.

## 2. Boundaries (administrative units)

Search, map aggregates and the SEO pages need units at four levels: kraj (1), obec (2), městský obvod /
městská část (3), část obce (4), imported by `search.ImportGeoJSON` from a GeoJSON FeatureCollection whose
features carry `code`, `level`, `name` and `parent` (code of the parent unit).

Source: RÚIAN VFR exchange format (ČÚZK), "základní a generalizované hranice":

    https://vdp.cuzk.cz/vymenny_format/soucasna/<YYYYMMDD>_ST_UKSG.xml.zip   # whole state, generalized

Convert with GDAL (VFR driver) and map the layers `Kraje`, `Obce`, `MomcMop`/`SpravniObvody` and
`CastiObci` to the four levels, keeping only the region (Praha + the municipalities above, with
Středočeský kraj and Hlavní město Praha as parents), e.g.:

    ogr2ogr -f GeoJSON -t_srs EPSG:4326 obce.geojson <file>.xml.zip Obce \
      -where "Kod IN (554782, 538728, ...)"
    # then add properties code/level/name/parent (jq or a short script) and merge the layers
    terractl import-ruian --region praha --file <addresses.zip> --boundaries praha-units.geojson

`--boundaries` also reassigns admin paths of all imported addresses. In `APP_ENV=dev|test` without
`--boundaries` the command derives approximate polygons around the address points (dev only, never in
production); in production it only warns.

Afterwards rebuild the search index and aggregates:

    terractl reindex

## 3. Pilot owners (20, onboarded by hand)

Each pilot owner gets a company organization with no members and an **owner invitation** e-mailed through
the outbox (the worker must run). The owner opens the link, signs in with a magic link (no password is set
by us) and becomes the organization owner. Invitations are valid 7 days; re-send from the admin
(organization → members) when one expires.

    # one owner
    terractl onboard-owner --email jana@example.cz --name "Jana Nováková" --org "Nováková Reality"

    # batch: CSV with header email,name,org[,locale][,registration_no] (comma or semicolon)
    terractl onboard-owner --csv pilot-owners.csv --dry-run
    terractl onboard-owner --csv pilot-owners.csv

Rows are validated before anything is written (e-mail format, duplicates, name). Re-running skips owners
whose existing account already owns an organization of the same name; owners who have not accepted yet get
a new organization and invitation, so check the audit log (`invitation.created`, source
`terractl onboard-owner`) before re-running a batch. Keep the CSV out of the repository (personal data).

## 4. Check

- `/v1/seo/municipalities?kind=apartment` lists Praha once owners publish listings.
- Site build (`npm run build -w site`) produces `/pronajem-bytu/praha`, `/pronajem-bytu/praha-1` … `praha-22`,
  the surrounding towns and the English `/en/apartments-for-rent/...` pages, plus `/sitemap.xml`.
