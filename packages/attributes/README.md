# Attribute catalog

`catalog.json` defines listing attributes: type (`bool`, `int`, `range`, `enum`, `set`, `text`),
group, Czech and English labels, whether it is a search filter, options for `enum`/`set`, units and
the unit kinds it applies to. `keywords` feed the offline mock extractor.

The api embeds this file and upserts it into the `filter_schemas` table at startup. New option
values found by AI ingest become proposals in the backoffice queue and are added to
`filter_schemas` only after a human approves them (ADR 0003). To change the catalog itself, edit
this file and run `make gen` (copies it into the api) — never edit `filter_schemas` by hand.

## Lease templates

`templates/cz/*.typ` are the Czech lease templates (Typst): `byt_doba_urcita`, `byt_doba_neurcita`,
`spolecny_najem`, `pokoj`, sharing `_base.typ`. Each renders a bilingual PDF (Czech, then English)
from JSON the api passes in `sys.inputs.data`; `sample.json` shows the shape. Preview locally with

    typst compile --ignore-system-fonts --root templates/cz \
      --input data="$(cat templates/cz/sample.json)" templates/cz/spolecny_najem.typ /tmp/lease.pdf

`make gen` copies the templates into the api (`internal/leasing/templates`). They are drafts until
the customer's lawyer reviews them (docs/legal-questions.md, Q-LEASE-1); bump
`leasing.TemplateVersion` whenever the text changes.
