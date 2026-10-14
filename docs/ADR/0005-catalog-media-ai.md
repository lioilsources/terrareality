# ADR 0005: Catalog, photos and AI suggestions

Status: accepted (M2, 2026-10-14)

## Decisions

1. **Property → unit → listing.** A property is a building or house at one address (RÚIAN address
   point). Units are apartments, houses, rooms (always inside an apartment or house), parking,
   storage and commercial space. A listing offers one unit. Rooms of a shared flat are separate
   units, so the flat and each room can be listed independently.
2. **Working copy + immutable versions.** The `listings` row is what the owner edits. Submitting
   creates a `listing_versions` snapshot (texts, prices, attributes, unit, address, photo keys).
   Staff approve or reject versions; approval sets `published_version`. A published listing stays
   visible with its approved version while the owner edits and resubmits. Public search (M3) reads
   only approved snapshots. Owners cannot change review status (no UPDATE grant, only the
   `withdraw_pending_versions` SECURITY DEFINER function).
3. **Attribute catalog as data.** `packages/attributes/catalog.json` is the source; the api embeds a
   copy (`make gen`) and upserts it into `filter_schemas` at startup. Attributes are validated
   against the live schema on every save. Values that AI finds outside the schema become
   `filter_schema_proposals`; staff add them as options (source `ingest`), never automatically.
4. **Photos never pass through the api.** Clients upload to a presigned URL (the web app streams the
   file from its server, mobile uploads directly), then call `complete`. A River job scans with
   ClamAV (when configured), strips EXIF/XMP/IPTC/text chunks without re-encoding (orientation is
   kept in the database and applied by imgproxy), and runs vision. Originals stay private; browsers
   get signed imgproxy URLs (thumb 400, medium 1024, large 1920).
5. **AI is a suggestion pipeline.** Attribute extraction, text drafts, photo captions and privacy
   blur produce `ai_suggestions`. The owner accepts all, a subset (attributes) or nothing; only then
   does anything change. Feature flags `ai.attributes`, `ai.text`, `ai.vision` switch them off.
6. **LLM integration.** The api talks to the AiStack gateway on the Spark through the
   OpenAI-compatible API. Text drafts use JSON-schema guided decoding; extraction uses JSON mode and
   validation in Go, because a 60+ property optional schema made guided decoding stop after a few
   keys (measured on Qwen 3.6). The vision service downloads the image itself and sends a downscaled
   data URL, since the Spark cannot reach our object storage. Offline, a deterministic keyword mock
   replaces the LLM and the vision service answers in mock mode.
7. **Money** is stored in minor units (haléře) with the currency; the deposit is capped by
   `jurisdictions.deposit_max_months`.
