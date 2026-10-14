# Attribute catalog

`catalog.json` defines listing attributes: type (`bool`, `int`, `range`, `enum`, `set`, `text`),
group, Czech and English labels, whether it is a search filter, options for `enum`/`set`, units and
the unit kinds it applies to. `keywords` feed the offline mock extractor.

The api embeds this file and upserts it into the `filter_schemas` table at startup. New option
values found by AI ingest become proposals in the backoffice queue and are added to
`filter_schemas` only after a human approves them (ADR 0003). To change the catalog itself, edit
this file and run `make gen` (copies it into the api) — never edit `filter_schemas` by hand.
