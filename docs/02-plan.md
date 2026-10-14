# TerraReality – implementační plán pro Opus (v1, 2026-10-14)

Vstup: [01-scope.md](01-scope.md) (v0.3, rozhodnutí v sekci 13). Tento dokument je zadání pro implementaci. Platí pořadí milníků; každý milník má acceptance kritéria a končí commitem s popisem a zelenou CI.

---

## 0. Pevná rozhodnutí (neměnit bez dohody)

- **Stack**: Go (modulární monolit) + Python worker (jen vision/OCR, přes frontu) + SvelteKit (web) + Astro (SEO/marketing) + Flutter (mobil) + PostgreSQL 17 (PostGIS, pgvector) + Temporal + River + Centrifugo + Caddy.
- **Peníze**: platforma **nikdy nedrží peníze**. Jen generuje QR/pokyny a páruje příchozí platby. Žádný escrow, žádné přeposílání, žádné krypto v této fázi.
- **AI**: každé AI rozhodnutí (moderace, extrakce atributů, generované texty, skóre zájemce) je **návrh ke schválení člověkem**. Nic se nepublikuje ani neodmítne automaticky.
- **Trh**: Praha, soukromí majitelé 1–5 bytů, dlouhodobý nájem bytů a pokojů. Jurisdikce `CZ` jediná implementovaná, ale model je multi-jurisdikční od začátku.
- **Blockchain**: žádný. Hash chain událostí ano.
- **Hosting**: dev Mac, staging NAS, produkce Hetzner (EU). LLM přes AiStack gateway na Sparku (OpenAI-compatible), cloud fallback za feature flagem.
- **Jazyky UI**: cs, en od začátku (klíče i18n všude), uk, sk připravené. Měna CZK, model umí více měn.

---

## 1. Cíl fáze 1 (MVP) a metriky

Do ~4 měsíců veřejně běžící produkt v Praze:
- Majitel vytvoří inzerát bytu nebo pokoje s AI asistencí, dostane zájemce, vybere ho, podepíše smlouvu přes BankID a vidí, zda přišel nájem.
- Hledající najde byt na mapě nebo přes chat, napíše majiteli, podá žádost (sám nebo jako skupina), podepíše.

Metriky, které produkt musí umět měřit od prvního dne (PostHog self-host + vlastní tabulky): nové inzeráty/týden, kontakt rate (konverzace/inzerát), žádosti/inzerát, % smluv dotažených digitálně, podíl pokojů, čas do obsazení, NPS majitelů.

---

## 2. Struktura repozitáře

```
terrareality/
  apps/web            SvelteKit: /  (hledání), /admin (majitel), /tenant (nájemní portál), /backoffice (my)
  apps/site           Astro: landing, blog, /pronajem-bytu/<obec>, /pronajem-pokoje/<obec>
  apps/mobile         Flutter: hledání, chat, žádost, podpis (webview), platby (QR), protokol (fáze 2)
  services/api        Go: HTTP API + Centrifugo publisher
  services/worker     Go: River jobs + Temporal workers (stejný modul jako api, jiný main)
  services/vision     Python: FastAPI/worker: tagování fotek, blur SPZ/obličejů, OCR dokumentů; volá Spark
  packages/contracts  openapi.yaml (zdroj pravdy), generované klienty: ts/, dart/
  packages/ui         sdílené Svelte komponenty + design tokens (web + site)
  packages/attributes katalog atributů a filter schémat (JSON), šablony smluv (Typst), i18n zdroje
  infra/dev           docker-compose (db, temporal, centrifugo, imgproxy, minio, mailpit)
  infra/nas           compose pro staging + Caddyfile
  infra/hetzner       terraform + compose pro produkci, WireGuard k Sparku
  infra/spark         modul pro AiStack (routy `terra`, `terra-embed`, `terra-vision`)
  docs/               01-scope, 02-plan, ADR/ (architektonická rozhodnutí), runbooks/
  Makefile            make dev, make test, make gen (openapi → klienty), make migrate, make seed
```

Go modulová struktura (`services/api/internal/<module>`), každý modul má `domain/`, `repo/` (sqlc), `service/`, `http/`, `jobs/`, `workflows/`:
`identity, org, catalog, media, geo, search, ai, messaging, applications, leasing, payments, billing, promo, notifications, moderation, audit, jurisdiction`.

Konvence: `sqlc` pro dotazy, `pgx` v5, migrace `goose` (SQL), `oapi-codegen` pro server stuby i TS klienta, `openapi-generator` pro Dart, `slog` logování, `otel` tracing, chyby jako `problem+json`, všechny ID `uuid v7`, čas v UTC, peníze jako `bigint` minor units + `currency`.

---

## 3. Milníky

### M0 – Scaffold a infrastruktura (týden 1–2)
Úkoly:
- Monorepo, Makefile, `infra/dev` compose: Postgres 17 (postgis + pgvector image), Temporal dev server, Centrifugo, imgproxy, MinIO, Mailpit.
- Go api: chi router, config (env), healthz, otel, slog, problem+json middleware, goose migrace 0001 (extensions, uuid v7 fn), sqlc config.
- Go worker: River + Temporal worker boot, sdílený `internal/`.
- `packages/contracts/openapi.yaml` s `/healthz`, generování TS a Dart klientů v CI.
- SvelteKit app (adapter-node, Tailwind, i18n přes `paraglide` nebo `svelte-i18n`), route groups `(public)`, `(admin)`, `(tenant)`, `(backoffice)`.
- Astro app s jednou landing stránkou a sdíleným `packages/ui`.
- Flutter app: go_router, Riverpod, generovaný Dart klient, splash + login screen.
- Python `services/vision`: FastAPI skeleton, klient na Spark gateway, mock režim.
- CI: Go test+vet+golangci-lint, `svelte-check`, `flutter analyze/test`, `ruff`, build obrazů, `make gen` diff check.
- `docs/ADR/0001-stack.md`, `0002-no-money-holding.md`, `0003-human-in-the-loop-ai.md`.
Acceptance: `make dev` nastartuje vše, `curl /healthz` OK, web a Flutter zobrazí stav API, CI zelená.

### M1 – Identita, organizace, jurisdikce (týden 2–4)
Úkoly:
- Users, sessions (cookie pro web, bearer pro mobil), e-mail+heslo (argon2id), magic link, Google/Apple OIDC, TOTP 2FA, WebAuthn později.
- `VerificationLevel`: email → phone (SMS přes adaptér, mock) → identity. Adaptér `IdentityProvider` s implementacemi `bankid` (OIDC CONNECT, scope profile/address/birthdate) a `mock`.
- Organizations, Memberships, Roles (`owner, admin, agent, accountant, maintenance, viewer`), pozvánky. Každý uživatel má implicitně „osobní“ organizaci (majitel 1 bytu nezakládá firmu).
- RLS politiky v Postgres podle `org_id` + `app.current_user`.
- `jurisdiction` modul: tabulka `jurisdictions` (CZ seed: měna, limit kauce 3×, výpovědní lhůty, formát adresy, podpisový provider), čtené službami, ne hardcoded.
- GDPR základ: export dat uživatele (job), žádost o výmaz (pseudonymizace, zachování smluvních dokumentů po zákonnou dobu), consent log.
- Backoffice: seznam uživatelů, impersonace s auditem.
Acceptance: E2E (Playwright) registrace → 2FA → vytvoření org → pozvánka člena; BankID mock flow projde; RLS test, že org A nevidí data org B.

### M2 – Katalog: nemovitosti, jednotky, inzeráty, média, atributy (týden 4–7)
Úkoly:
- Tabulky `properties`, `units(kind: apartment|house|room|parking|storage|commercial, parent_id)`, `listings`, `listing_versions`, `listing_attributes (jsonb)`, `media`, `addresses`.
- Katalog atributů `packages/attributes/catalog.json`: ≥ 60 atributů s typem (`bool|int|range|enum|set|text`), skupinou, i18n labelem, zda je filtr. Loader do DB tabulky `filter_schemas` (jako ChatShop, ale seedovaný + rozšiřovaný ingestem).
- Média: upload přes presigned URL (S3/MinIO), job: varianty (imgproxy), EXIF strip, ClamAV, vision job (tagy, blur SPZ/obličejů) → návrhy ke schválení.
- Ingest atributů: `ai` modul volá Spark (OpenAI-compatible, JSON schema output) nad textem + tagy z fotek → `attribute_suggestions`; UI majitele je zobrazí jako „navrženo, potvrď“. Nové hodnoty enum/set → návrh rozšíření filter schématu do backoffice fronty (člověk schválí).
- AI návrh textu inzerátu (cs + en) ze strukturovaných dat; vždy editovatelný, nikdy auto-publikovaný.
- Stavy inzerátu: `draft → review → published → paused → rented → archived`; `review` = moderační fronta (člověk). Verzování při každé publikované změně.
- Admin UI (SvelteKit): průvodce inzerátem (adresa → jednotka → atributy → fotky → text → náhled → odeslat ke schválení), seznam inzerátů, duplikace.
- Adresy: RÚIAN import (CSV adresních míst, open data ČÚZK) do `ruian_places` + autocomplete endpoint; volba „přesná / přibližná poloha“.
Acceptance: majitel vytvoří inzerát bytu i pokoje s fotkami, dostane AI návrhy atributů a textu, odešle ke schválení; backoffice schválí; verze se uloží; vision mock i reálný Spark fungují přes stejný kontrakt.

### M3 – Geo, vyhledávání, mapa, chat-first hledání (týden 7–11)
Úkoly:
- Admin hierarchie: import OSM admin boundaries (kraje, okresy, obce, části obce; CZ) + ulice z RÚIAN → `admin_units(path ltree, geom)`; každý listing dostane `admin_path` při uložení adresy (PostGIS `ST_Within`).
- PMTiles pipeline (tippecanoe) pro hranice a pro „listing dots“ vrstvu; publikace na object storage; job denně.
- Agregace: materialized view `listing_aggregates(level, unit_id, filter_hash)` nejdřív jen bez filtrů (počet, medián nájmu, min/max) + online dotaz s filtry do 200 ms na 50k inzerátů (test s generovanými daty).
- Search API: `GET /search` s facety (počty per hodnota), rozsahy, geo bbox/polygon, fulltext (`tsvector` cs + `pg_trgm`), řazení (relevance, cena, datum, promo). Facety z `filter_schemas`.
- Embeddingy inzerátů (bge-m3 přes Spark) do pgvector pro „podobné byty“ a pro chat.
- Web: mapa MapLibre + seznam (split view), drill-down po úrovních, piny s cenou, uložená hledání + e-mail notifikace (job).
- **Chat-first hledání**: horní panel (ChatShop vzor). Go `ai` modul: LLM s tool-callingem nad nástroji `set_filters`, `move_map(admin_unit|bbox)`, `search`, `explain_listing`. Odpověď streamuje přes SSE, UI aplikuje změny filtrů a mapy. Mock režim bez LLM: pravidlový parser pro čísla/dispozice/lokality.
- Astro: generované stránky `/pronajem-bytu/<obec>` a `/pronajem-pokoje/<obec>` z API (ISR/SSG build denně), s agregacemi a top inzeráty, JSON-LD.
Acceptance: p95 search < 300 ms na 50k syntetických inzerátů; mapa od kraje po ulici; chat „2+kk do 18 000 v Praze 6 se psem“ nastaví filtry a mapu; Astro build vygeneruje stránky pro všechny obce s ≥ 1 inzerátem.

### M4 – Messaging a moderace (týden 11–13)
Úkoly:
- `conversations(listing_id, participants[])`, `messages`, přílohy, read receipts; Centrifugo kanály per konverzace, server-side publish z Go; Flutter i web klienti.
- Maskování kontaktů (regex na telefon/e-mail/IBAN) s varováním, ne blokací; detekce „pošlete zálohu předem“ → flag do moderace.
- Šablony odpovědí majitele, pre-screening otázky u inzerátu (nastaví majitel).
- Nahlášení, blokace, backoffice fronta s AI návrhem verdiktu (člověk rozhodne).
- Notifikace: e-mail (Mailpit dev, Postmark/SES prod), push (FCM/APNs přes Flutter, web push), in-app; preference per uživatel; digest.
Acceptance: zpráva doručená do 1 s na druhý klient; offline klient dostane push; nahlášená konverzace se objeví v backoffice s návrhem.

### M5 – Žádosti, skupiny, profily hledajících, prohlídky (týden 13–15)
Úkoly:
- `applications(listing_id, applicant_type: user|group, status, answers, preferred_from, duration)`; `tenant_groups`, `group_members(consent)`; skupinový chat.
- `roommate_seeker_profiles` + reverzní inzerát „hledám spolubydlení“ (zobrazuje se majitelům pokojů i jiným hledajícím); matching v0 = filtr + skóre podle shody preferencí (bez ML).
- Tenant Passport v0: úroveň ověření, volitelné nahrání potvrzení o příjmu (jen soubor, člověk na straně majitele hodnotí), ISIR kontrola (veřejné API insolvenčního rejstříku) jako „bez záznamu / záznam“.
- Přehled zájemců pro majitele: řazení podle úrovně ověření, AI shrnutí žádosti (návrh), pozvání na prohlídku, odmítnutí s důvodem z číselníku (audit, antidiskriminace: chráněné údaje se nezobrazují).
- Prohlídkové sloty: majitel vypíše, zájemce rezervuje, připomínky.
Acceptance: skupina 3 lidí podá jednu žádost se souhlasem všech; majitel vybere, ostatním odejde automatická odpověď; prohlídka se zarezervuje z Flutteru.

### M6 – Leasing: smlouva, podpis, platební kalendář, QR, párování (týden 15–20)
Úkoly:
- `leases(jurisdiction, currency, state, template_version)`, `lease_parties(role: landlord|tenant|co_tenant|subtenant|guarantor, share_bps)`, `lease_events(hash, prev_hash)`, `documents`, `signatures`.
- Šablony Typst v `packages/attributes/templates/cz/`: `byt_doba_urcita`, `byt_doba_neurcita`, `spolecny_najem`, `pokoj`. Proměnné ze systému, volitelné klauzule, validace (kauce ≤ 3× nájem, povinné náležitosti). Dvojjazyčný výstup cs/en. **Právník zákazníka reviduje před M6 acceptance.**
- Temporal workflow `LeaseLifecycle`: `draft → proposed → negotiating → signed → active → notice_given → terminated → settled`; aktivita každé měsíční obligation; timery pro připomínky (D-3, D+1, D+7) a eskalaci; settlement kauce (oba potvrdí / lhůta / spor = jen stav, mediace mimo systém).
- Podpis: adaptér `SignatureProvider` s `bankid_sign` (Bank iD SIGN, PDF in/out, evidence), `upload_scan` fallback, `mock`. Podpis v Flutteru přes webview na BankID.
- Platební kalendář: `payment_schedules`, `payment_obligations(due, amount, kind: rent|services|deposit|oneoff)`, `obligation_splits(party, amount)` pro spolubydlení; QR platba CZ (SPD formát, VS = kód smlouvy) jako obrázek i Spayd string; Revolut odkaz v M7.
- Párování v0: ruční potvrzení majitelem („přišlo“) + **open banking AIS** přes GoCardless Bank Account Data (adaptér + mock): majitel propojí účet, job tahá transakce, páruje podle VS/částky/data, nejisté shody k potvrzení.
- Ledger: podvojné `ledger_entries` per smlouva (pohledávka ↔ úhrada), přehled dluhu, export CSV.
- Nájemní portál (`/tenant`) a Flutter: moje smlouva, dokumenty, co mám zaplatit, QR, historie.
- Hash chain: každý `lease_event` má `sha256(prev_hash || canonical_json(payload))`; endpoint pro ověření řetězu; export pro spor.
Acceptance: E2E majitel + 2 spolubydlící: smlouva společný nájem → oba podepíší (mock) → vznikne kalendář s dělením 50/50 → QR → simulovaná bankovní transakce se spáruje → dluh 0; řetěz hashů ověřitelný; po 7 dnech bez platby workflow pošle eskalaci.

### M7 – Promo, billing, Revolut, backoffice (týden 20–22)
Úkoly:
- Promo produkty: topování (jednorázové, naplánované), zvýraznění, balíčky; řazení v search s transparentním štítkem.
- Stripe Billing (karty) pro promo + budoucí předplatné; faktury s DPH CZ; webhooky.
- Revolut Business Merchant: platební odkaz na obligation jako druhá volba po QR (adaptér, mock).
- Backoffice: dashboard metrik, moderační fronty (inzeráty, zprávy, AI návrhy filter schémat, atributů), feature flags (tabulka + cache), správa šablon a katalogu, impersonace, audit log viewer.
Acceptance: majitel zaplatí topování kartou, inzerát se posune, faktura přijde e-mailem; Revolut odkaz vytvořen pro obligation (sandbox).

### M8 – Flutter v0 dokončení, produkce, launch (týden 22–26)
Úkoly:
- Flutter: hledání s mapou (maplibre_gl), chat, žádost, prohlídky, nájemní portál, push; Admin funkce **ne** (web). TestFlight + interní Play track.
- Hetzner: terraform (2 VM: app, db; object storage; firewall; snapshots), compose prod, Caddy TLS, WireGuard k Sparku, cloud LLM fallback (Claude přes gateway) za flagem, zálohy pgBackRest (RPO 1 h), restore test v runbooku.
- Observabilita: Grafana + Loki + Tempo, Sentry (web, Flutter), uptime check, alerty (SLO: dostupnost 99,9 %, p95 search).
- Bezpečnost: OWASP ASVS L2 checklist, rate limiting, CSP, dependency scan, penetrační test od zákazníka před launchem.
- Právní: podmínky, GDPR dokumenty, DPA s partnery (BankID, GoCardless, Stripe, Revolut, hosting), DSA kontaktní bod, cookie lišta.
- Seed Praha: import adres a hranic, 20 pilotních majitelů ručně onboardovaných, Astro stránky pro Prahu a okolí.
Acceptance: launch checklist v `docs/runbooks/launch.md` splněn, produkční E2E smoke test, restore ze zálohy ověřen.

---

## 4. Fáze 2 (po launchi, orientačně 3 měsíce) – jen osnova
Předávací protokol (Flutter: fotky, měřidla, podpis obou, hash), vyúčtování služeb (zákon 67/2013, cost pooly a alokační klíče), údržba tickety, Tenant Passport v1 (příjem přes open banking, exekuce/SOLUS přes partnera), hodnocení, výměna spolubydlícího workflow, Buildings modul (rent roll, vakance, hromadné operace, nájemní portál budovy), správcovský tier (role na budovy, XML feedy Sreality/Bezrealitky). Fáze 3: SK, co-ownership modul (cap table, waterfall, pokyny k výplatám, hlasování, výkazy), public API. Detailní plán fází 2+ vznikne po vyhodnocení metrik MVP.

---

## 5. Průřezové požadavky (platí v každém milníku)

- **Testy**: Go unit + integrační (testcontainers Postgres), kontraktní testy OpenAPI, Playwright E2E pro kritické toky (M1, M2, M5, M6, M7), Flutter widget testy, Python testy vision. Žádný milník není hotový bez testů acceptance scénáře.
- **i18n**: žádný text v kódu; klíče cs + en; právní texty z `packages/attributes`.
- **Audit**: každá mutace doménových objektů → `audit_events(actor, org, entity, action, diff)`.
- **Feature flags** pro vše AI, pro Revolut, pro cloud LLM fallback.
- **Mock adaptéry** pro každého externího partnera (BankID, GoCardless, Stripe, Revolut, SMS, e-mail, Spark) tak, aby `make dev` běžel offline.
- **Přístupnost**: WCAG 2.1 AA pro hledání, inzerát, chat, smlouvu, platby.
- **Výkon**: budget p95 search 300 ms, LCP 2,5 s na 4G; test s 50k syntetickými inzeráty od M3.
- **Dokumentace**: ADR pro každé netriviální rozhodnutí, runbooks pro deploy/restore/incident, OpenAPI jako živá dokumentace.

---

## 6. Jak pracovat (instrukce pro Opus)

1. Postupuj po milnících v pořadí; uvnitř milníku nejdřív migrace + sqlc + doména, pak API + OpenAPI, pak generování klientů, pak UI. Flutter obrazovky dělej až když je API kontrakt stabilní.
2. Každý milník = jedna větev `m<N>-<slug>`, malé commity, na konci PR s checklistem acceptance kritérií a výstupem testů.
3. Když narazíš na právní otázku (náležitosti smlouvy, lhůty), **neimprovizuj**: implementuj podle `jurisdictions` konfigurace a zapiš do `docs/legal-questions.md` k odsouhlasení právníkem.
4. Nikdy neimplementuj držení peněz, přeposílání plateb, krypto, on-chain cokoliv, ani automatické publikování/odmítání bez lidského schválení. Pokud úkol vypadá, že to vyžaduje, zastav se a zeptej.
5. Externí služby jen přes adaptéry s mock implementací; reálné klíče jen z env, nikdy v repu.
6. Před označením milníku za hotový spusť `make test`, `make e2e`, `make gen` (bez diffu) a přilož výstup.
7. Výkonnostní a bezpečnostní požadavky z sekce 5 jsou součást acceptance, ne „později“.
8. Otázky, které nejde rozhodnout z 01-scope a tohoto plánu, zapiš do `docs/open-questions.md` s navrženou odpovědí a pokračuj podle návrhu, pokud to není nevratné.

---

## 7. Externí partneři a co je třeba zařídit mimo kód (zákazník)

| Partner | K čemu | Kdy |
|---|---|---|
| Bank iD (CONNECT + SIGN) | ověření identity, podpis smluv | smlouva před M1, produkční přístup před M6 |
| GoCardless Bank Account Data (nebo Tink) | AIS párování plateb | sandbox M6, produkce M8 |
| Stripe | karty za promo, billing | M7 |
| Revolut Business Merchant | platební odkazy | M7 |
| Postmark/SES, FCM/APNs, SMS brána | notifikace | M4 |
| Hetzner, doména terrareality.cz, DNS | produkce | M8 |
| Právník | šablony smluv CZ, podmínky, GDPR, DSA | před M6 |
| Apple Developer + Google Play účty | Flutter distribuce | M8 |
| ČÚZK RÚIAN, OSM | adresy, hranice (open data, bez smlouvy) | M2–M3 |
