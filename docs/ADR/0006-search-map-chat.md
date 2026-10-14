# ADR 0006: Search, map and chat-first search

Status: accepted (M3, 2026-10-14)

## Decisions

1. **Search index from approved versions only.** `listing_search` holds one row per published listing,
   built from its approved snapshot when staff approve a version and when the owner pauses,
   resumes, rents out or archives it (`search.Indexer`). Working copies never leak into search.
   `terractl reindex` rebuilds it.
2. **Approximate location.** Unless the owner chooses the exact address, the indexed point is moved
   150–350 m in a direction derived from the listing id (stable, but does not reveal the building).
   The public detail shows the address only for exact listings.
3. **Administrative hierarchy** in `admin_units` (ltree paths): region > municipality > district
   (městský obvod) > part (část obce). Production imports real boundaries as GeoJSON
   (`terractl admin import`, from OSM or RÚIAN VFR); dev and tests derive outlines from the RÚIAN
   sample. Addresses get the deepest covering unit on creation.
4. **Dynamic SQL for search.** The search builder (`internal/search/query.go`) composes filters with
   bound parameters; this is the one place outside sqlc, because the filter combination is open.
   Facets use a generated `facets text[]` column of `key=value` tokens (GIN), which brought p95 from
   214 ms to 162 ms on 50 000 listings (p50 93 ms). Each facet ignores its own filter.
5. **Chat-first search = rules + one LLM call.** A deterministic Czech parser (layouts, prices,
   areas, places with locative endings, catalog keywords) always runs; when the Spark is reachable,
   one tool-calling request (`set_filters`, `move_map`) adds what rules miss. The reply is a template,
   so each user message costs at most one LLM request (Spark budget: 4 parallel). When the LLM is
   down (07:00–13:00 GPU schedule) the rules answer and the UI says so.

## Deviations from the plan

- **SSE streaming** for chat is replaced by a single JSON response: with one non-streamed tool call
  and a template reply there is nothing to stream. Revisit if the reply becomes LLM-generated text.
- **PMTiles/tippecanoe** are not used yet: the API returns simplified area outlines as GeoJSON and up
  to 2000 points that MapLibre clusters client-side. Enough for the MVP scale; PMTiles when listings
  exceed ~100k or for a self-hosted basemap. The basemap is OpenFreeMap (`MAP_STYLE`).
- **Embeddings** (bge-m3) are deferred until the Spark operator and owner decide where bge-m3 runs
  (infra/spark/README.md). `listing_search.embedding` and similarity by embedding are in place;
  "similar listings" falls back to kind, price ±25 % and distance ≤ 5 km.
- **"From region to street"**: drill-down goes region → municipality → district → part; below that the
  map zooms to individual listing points (streets come from the basemap, not from an admin level).
