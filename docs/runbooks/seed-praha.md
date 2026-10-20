# Runbook: seed Praha (addresses, boundaries, pilot owners, existing leases)

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

## 3b. Existing leases of a pilot owner (paper contracts)

Flats an owner already rents out on paper are imported, not drafted: the lease is created directly as
`active` (or `signed` when it starts later), with no signing round and no rendered document, and the event
log records that it was signed outside the platform (`imported`). Payments are tracked from the **cutover**
(`cutover_on`, default the first day of next month; at most 31 days back and 12 months ahead, never before
the start or after the end), so no past month becomes debt, a reminder, an escalation or risk. What a tenant
owed at the cutover goes into `opening_balance` (one obligation due on the cutover day). `deposit_held`
records a deposit the owner already has (not scheduled, counts as paid in the risk score and rent roll).
`variable_symbol` keeps the tenants' standing orders working: QR codes and bank matching use it instead of
the lease code (unique among the organization's running leases).

    # one row per tenant; rows with the same lease_ref form one lease (docs/examples/existing-leases.csv)
    terractl leases import --org "Nováková Reality" --csv existing-leases.csv --dry-run
    terractl leases import --org 0193c0de-... --csv existing-leases.csv

Columns (header required, comma or semicolon): `lease_ref, address, ruian_id, unit_label, template,
starts_on, ends_on, rent, services, deposit, deposit_held, due_day, notice_months, payee_iban, payee_name,
variable_symbol, cutover_on, tenant_name, tenant_email, share_pct, opening_balance`. Amounts in whole CZK
(decimals allowed), dates `YYYY-MM-DD` or `D.M.YYYY`, `deposit_held` ano/ne (yes/no, 1/0), `share_pct` empty
for equal shares. Lease columns are taken from the first row of a lease; later rows may leave them empty
but must not contradict it. An empty `template` means `byt_doba_neurcita` without `ends_on`, else
`byt_doba_urcita`; one tenant is `tenant`, several are `co_tenant`. `tenant_email` is optional.

Every row is checked first and all problems are printed with their line; nothing is written unless the
whole file is valid, and then all leases are imported in one transaction (all or nothing). `--dry-run`
runs the same import and rolls it back. `--org` takes the id or the exact name. The operator acts for the
organization: the landlord party is linked to its owner (unlinked while the owner has not accepted the
invitation), and the event log and audit (`lease.import`, source `terractl`) name no user. **Tenants are
not contacted**: no e-mail or push reaches a tenant of an imported lease until the owner invites them from
the lease page (`POST /v1/orgs/{orgId}/leases/{leaseId}/parties/{partyId}/invite`) and they sign in with the
invited address (Q-LEASE-5 in `docs/legal-questions.md`). The owner can attach a scan of the paper contract
there (`contract-scan`). Keep the CSV out of the repository (personal data).

## 3a. Ukázkové inzeráty (demo listings, closed beta only)

So the map is not empty before the pilot owners publish, staging can carry clearly labelled demo listings.
They show a badge "Ukázkový inzerát – nelze pronajmout" on cards, map markers and detail (web and mobile);
contacting, applying and booking a viewing are refused (409, problem code `demo_listing`). They are not
supply: SEO municipality stats, static site locality pages and the sitemap, the aggregate view, backoffice
and portfolio market statistics and saved-search digests leave them out. Allowed in every `APP_ENV`, needs
`S3_ENDPOINT` (the photos go to the object store the api serves from) and imported Praha RÚIAN addresses
(step 1). No LLM involved.

Photos directory: `manifest.json` plus one `flat-NN/` directory per flat with `living.jpg`, `kitchen.jpg`,
`bedroom.jpg` and `bathroom.jpg`:

    [{"flat": "flat-01", "type": "panel", "layout": "2+kk"},
     {"flat": "flat-02", "type": "brick", "layout": "3+1"},
     {"flat": "flat-03", "type": "new",   "layout": "1+kk"}]

    terractl demo seed --photos ./demo-photos [--org "TerraReality – ukázka"] [--count 15]
    terractl demo list
    terractl demo remove

`seed` creates (or reuses) a company organization of that name without members and publishes one listing
per flat at a distinct real Praha address (deterministic pick, approximate location on the map), with
generated area, floor, rent, deposit and availability consistent with layout and building type, a title
starting with "Ukázka: " and a description that opens with the demo disclaimer (cs and en). Photos run
through the normal media pipeline (blob store, sanitize, scan). Re-running skips flats that already have a
live demo listing. `remove` archives all demo listings, takes them out of search and deletes their photos;
re-running it is a no-op. `list` prints id, flat, status, photos, rent, title and address.

**Remove the demo listings (`terractl demo remove`) before inviting seekers** to the beta, and in any case
before launch.

## 4. Check

- `/v1/seo/municipalities?kind=apartment` lists Praha once owners publish listings.
- Site build (`npm run build -w site`) produces `/pronajem-bytu/praha`, `/pronajem-bytu/praha-1` … `praha-22`,
  the surrounding towns and the English `/en/apartments-for-rent/...` pages, plus `/sitemap.xml`.
