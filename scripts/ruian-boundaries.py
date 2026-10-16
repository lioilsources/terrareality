"""Merges the layers exported by ruian-boundaries.sh into one FeatureCollection with the properties
code, level, name, parent that search.ImportGeoJSON expects. Standard library only."""
import json
import os
import sys
from collections import Counter, defaultdict

PRAHA = 554782


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
    dup = Counter((r[3], r[2]) for r in obec_rows)
    for r in obec_rows:
        if dup[(r[3], r[2])] > 1:
            r[2] = f"{r[2]} (okres {okres_name[r[5]]})"
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
    dup = Counter((r[3], r[2]) for r in ku_rows)
    for r in ku_rows:
        if dup[(r[3], r[2])] > 1:
            r[2] = f"{r[2]} ({r[0][1:]})"
        units.append(r)

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
