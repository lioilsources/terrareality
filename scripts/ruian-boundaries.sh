#!/usr/bin/env bash
# Builds the administrative units GeoJSON for `terractl import-ruian --boundaries` from the official
# RÚIAN VFR export of the whole state with generalized boundaries (ČÚZK, CC BY 4.0):
#   https://vdp.cuzk.cz/vymenny_format/soucasna/<YYYYMMDD>_ST_UKSG.xml.zip
# Levels: 1 kraj (VÚSC), 2 obec, 3 správní obvod (Praha 1–22) / městský obvod či část (Momc of the
# other statutory cities), 4 katastrální území (polygons of "části obce" are not published; in Praha
# and most towns the cadastral areas match them: Dejvice, Bubeneč, ...).
# Needs Docker (GDAL image) and python3. Usage: scripts/ruian-boundaries.sh <ST_UKSG.xml.zip> <out.geojson>
set -euo pipefail
zip=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
out=$2
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
gdal=ghcr.io/osgeo/gdal:ubuntu-small-3.11.4
export_layer() { # layer geometry-field fields (GeoJSON keeps one geometry: select it)
  docker run --rm -v "$(dirname "$zip"):/in:ro" -v "$work:/out" "$gdal" \
    ogr2ogr -f GeoJSON -lco RFC7946=YES -lco COORDINATE_PRECISION=6 -simplify 5 -t_srs EPSG:4326 \
    -nlt PROMOTE_TO_MULTI -dialect OGRSQL -sql "SELECT $3, $2 FROM $1" \
    "/out/$1.geojson" "/vsizip//in/$(basename "$zip")" ||
    { echo "ogr2ogr failed for $1" >&2; exit 1; }
}
export_layer Vusc GeneralizovaneHranice Kod,Nazev
export_layer Okresy GeneralizovaneHranice Kod,Nazev,VuscKod
export_layer Obce GeneralizovaneHranice Kod,Nazev,OkresKod
export_layer SpravniObvody OriginalniHranice Kod,Nazev,ObecKod
export_layer Momc OriginalniHranice Kod,Nazev,ObecKod
export_layer KatastralniUzemi GeneralizovaneHranice Kod,Nazev,ObecKod
python3 -I "$(dirname "$0")/ruian-boundaries.py" "$work" "$out"
