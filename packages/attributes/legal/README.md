# Legal texts

Public legal documents of the platform, one Markdown file per document and language:

| File | Web route | Version source |
| --- | --- | --- |
| `{cs,en}/terms.md` | `/podminky` | api `TERMS_VERSION` (consent log) |
| `{cs,en}/privacy.md` | `/soukromi` | api `PRIVACY_VERSION` (consent log) |
| `{cs,en}/cookies.md` | `/cookies` | front matter only |
| `{cs,en}/dsa.md` | `/dsa` | front matter only |

Each file starts with front matter (`title`, `version`, `draft`). The web app (`apps/web`) reads the files
at build time and renders a small Markdown subset: headings, paragraphs, `-` and `1.` lists, `**bold**`
and `[links](url)`. Keep to that subset.

All texts are **drafts** until the customer's lawyer reviews them (docs/legal-questions.md, Q-LEGAL-*).
When the terms or the privacy policy change materially, bump `version` here **and** the api default
(`TERMS_VERSION` / `PRIVACY_VERSION` in `services/api/internal/platform/config/config.go`) in the same
change, so new consents are recorded against the text users actually saw. Set `draft: false` only after
legal sign-off.
