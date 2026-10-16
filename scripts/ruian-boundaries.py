"""Merges the layers exported by ruian-boundaries.sh into one FeatureCollection with the properties
code, level, name, parent that search.ImportGeoJSON expects. Standard library only."""
import json
import os
import re
import sys
import unicodedata
from collections import Counter, defaultdict

PRAHA = 554782


def label(name):
    # Same as search.label (ltree path label): unaccented, lower case, non-alphanumerics -> "_".
    t = "".join(c for c in unicodedata.normalize("NFD", name.lower()) if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9]+", "_", unicodedata.normalize("NFC", t)).strip("_")


def load(work, layer):
    with open(os.path.join(work, layer + ".geojson"), encoding="utf-8") as f:
        return [x for x in json.load(f)["features"] if x.get("geometry")]


def prop(f, k):
    v = f["properties"].get(k)
    return None if v is None else str(v)


def rings(geom):
    # MultiPolygon -> list of polygons (list of rings)
    return geom["coordinates"] if geom["type"] == "MultiPolygon" else [geom["coordinates"]]


def inside(pt, geom):
    x, y = pt
    for poly in rings(geom):
        hit = False
        for k, ring in enumerate(poly):
            c = False
            for i in range(len(ring) - 1):
                (x1, y1), (x2, y2) = ring[i][:2], ring[i + 1][:2]
                if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
                    c = not c
            if k == 0:
                hit = c
            elif c:
                hit = False  # inside a hole
        if hit:
            return True
    return False


def centroid(geom):
    # Area-weighted centroid of the largest polygon's outer ring (good enough for containment).
    best, area_best = None, -1.0
    for poly in rings(geom):
        ring = poly[0]
        a = cx = cy = 0.0
        for i in range(len(ring) - 1):
            x1, y1 = ring[i][:2]
            x2, y2 = ring[i + 1][:2]
            w = x1 * y2 - x2 * y1
            a += w
            cx += (x1 + x2) * w
            cy += (y1 + y2) * w
        if a and abs(a) > area_best:
            area_best, best = abs(a), (cx / (3 * a), cy / (3 * a))
    return best


def main(work, out):
    vusc = load(work, "Vusc")
    okresy = {prop(f, "Kod"): f for f in load(work, "Okresy")}
    obce = load(work, "Obce")
    so = load(work, "SpravniObvody")
    momc = [f for f in load(work, "Momc") if prop(f, "ObecKod") != str(PRAHA)]
    ku = load(work, "KatastralniUzemi")

    units = []  # (code, level, name, parent, geometry)
    for f in vusc:
        units.append(["K" + prop(f, "Kod"), 1, prop(f, "Nazev"), "", f["geometry"]])

    okres_name = {k: prop(f, "Nazev") for k, f in okresy.items()}
    obec_rows = []
    for f in obce:
        ok = okresy.get(prop(f, "OkresKod"))
        if prop(f, "Kod") == str(PRAHA):  # Praha belongs to no okres; it is the kraj Hlavní město Praha
            obec_rows.append([prop(f, "Kod"), 2, prop(f, "Nazev"), "K19", f["geometry"], None])
            continue
        if ok is None:
            print("skip obec without okres:", prop(f, "Nazev"), file=sys.stderr)
            continue
        obec_rows.append([prop(f, "Kod"), 2, prop(f, "Nazev"), "K" + prop(ok, "VuscKod"), f["geometry"], prop(f, "OkresKod")])
    dup = Counter((r[3], label(r[2])) for r in obec_rows)
    for r in obec_rows:
        if dup[(r[3], label(r[2]))] > 1 and r[5]:
            r[2] = f"{r[2]} (okres {okres_name[r[5]]})"
    dup = Counter((r[3], label(r[2])) for r in obec_rows)  # same name twice in one okres
    for r in obec_rows:
        if dup[(r[3], label(r[2]))] > 1:
            r[2] = f"{r[2][:-1]}, {r[0]})" if r[2].endswith(")") else f"{r[2]} ({r[0]})"
        units.append(r[:5])

    districts = defaultdict(list)  # obec code -> [(code, geometry)]
    for f, prefix in [(f, "S") for f in so] + [(f, "M") for f in momc]:
        code = prefix + prop(f, "Kod")
        units.append([code, 3, prop(f, "Nazev"), prop(f, "ObecKod"), f["geometry"]])
        districts[prop(f, "ObecKod")].append((code, f["geometry"]))

    ku_rows = []
    for f in ku:
        obec = prop(f, "ObecKod")
        parent = obec
        if districts.get(obec):
            c = centroid(f["geometry"])
            for code, g in districts[obec]:
                if c and inside(c, g):
                    parent = code
                    break
        ku_rows.append(["U" + prop(f, "Kod"), 4, prop(f, "Nazev"), parent, f["geometry"]])
    dup = Counter((r[3], label(r[2])) for r in ku_rows)
    for r in ku_rows:
        if dup[(r[3], label(r[2]))] > 1:
            r[2] = f"{r[2]} ({r[0][1:]})"
        units.append(r)

    # Paths must be unique: fail here, not halfway through the import transaction.
    parent_of = {u[0]: u[3] for u in units}
    lab = {u[0]: label(u[2]) for u in units}
    def path(code):
        return (path(parent_of[code]) + "." if parent_of.get(code) else "") + lab[code]
    seen = {}
    for u in units:
        if u[3] and u[3] not in parent_of:
            continue
        p = path(u[0])
        if p in seen:
            sys.exit(f"duplicate path {p}: {seen[p]} and {u[0]} {u[2]}")
        seen[p] = u[0]

    known = {u[0] for u in units}
    missing = [u for u in units if u[3] and u[3] not in known]
    if missing:
        print(f"{len(missing)} units with unknown parent, dropped (e.g. {missing[0][2]})", file=sys.stderr)
        units = [u for u in units if not u[3] or u[3] in known]

    fc = {"type": "FeatureCollection", "features": [
        {"type": "Feature", "properties": {"code": c, "level": lvl, "name": n, "parent": p}, "geometry": g}
        for c, lvl, n, p, g in units]}
    with open(out, "w", encoding="utf-8") as f:
        json.dump(fc, f, ensure_ascii=False, separators=(",", ":"))
    print(" ".join(f"level {k}: {v}" for k, v in sorted(Counter(u[1] for u in units).items())))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
