# Stav projektu (2026-10-15)

Plán a acceptance kritéria: `docs/02-plan.md`. Tento soubor říká, kde jsme a kde začít.

| Milník                                     | Stav                                     | Commit / PR                                              |
| ------------------------------------------ | ---------------------------------------- | -------------------------------------------------------- |
| M1–M5                                      | hotovo, v `main`                         | PR #1–#5                                                 |
| **M6 Leasing**                             | **hotovo, v `main`**                     | merge `b9e01c9` (PR #6), poslední commit větve `01efa27` |
| **M6b Portfolio a riziko**                 | **hotovo, v `main`**                     | merge `f981a07` (PR #7)                                  |
| **M7 Promo, billing, Revolut, backoffice** | **hotovo, v `main`**                     | merge `5eabb2e` (PR #8)                                  |
| **M8 Flutter v0, produkce, launch**        | kód hotový, launch čeká na externí kroky | větev `m8-launch`                                        |

U M6 i M6b prošly `make test`, `make lint`, `make gen-check` a `make e2e` lokálně i v CI.
U M7 prošly `make test`, `make lint`, `make gen-check` a `make e2e` (18/18) lokálně i v CI.
U M8 prošly lokálně `make test`, `make lint`, `make e2e` (25/25) a `make restore-test`; CI poběží s PR.

## M6 – co se změnilo oproti plánu

- **Podpis:** hotový je jen adaptér `SignatureProvider` s implementací `mock` (jednoduchý elektronický podpis s evidencí: IP, čas, SHA-256 dokumentu).
  - `bankid_sign` čeká na smlouvu s Bank iD (OQ-19). `upload_scan` je zatím jen hodnota v DB.
  - Podpis ve Flutteru přes webview BankID není, Flutter podepisuje přes mock.
- **Platební kalendář:** tabulka `payment_schedules` nevznikla. Položky se generují přímo do `payment_obligations` a `obligation_splits`.
  - Nájem a zálohy na služby jsou jedna měsíční položka `rent`.
  - První a poslední měsíc se účtuje celý, bez poměrné části (OQ-20).
- **Platební symboly:** VS je kód smlouvy (sekvence od 2600000001), SS je pořadí strany ve smlouvě. Některé banky SS přes PSD2 nepředají, taková platba skončí jako návrh ke spárování (OQ-22).
- **Šablony** mají vodoznak DRAFT, dokud právník neschválí (`LEASE_TEMPLATES_REVIEWED=true`, Q-LEASE-1). Plán počítal s revizí před acceptance; ta zatím neproběhla.
- **Eskalace po 7 dnech** se neověřuje v E2E, ale testem workflow s posunem času (Temporal time skipping, `internal/workflows/lease_test.go`).
  - Pro E2E přibyl v M6b dev endpoint `POST /dev/leases/{id}/escalate`.
- **Vypořádání kauce:** smlouva je vypořádaná, když všechny strany potvrdí. Spor znamená, že smlouva zůstane ve stavu `terminated`; lhůta pro automatické vypořádání není.
- **Kde je co:** nájemní portál pro smlouvy je `/smlouvy/[id]` (z rozcestníku `/tenant`). Typst je v CI i v Docker image.

## M6b – co se změnilo oproti plánu

- **Riziko** se nepřepočítává háčky v leasingu. Job `lease_risk` běží každou minutu a přepočítá smlouvy s novou událostí, bez skóre, se skóre starším než den nebo z jiné verze modelu. Eskalace je v portfoliu do několika minut, plán dovoloval 1 h.
- **Pravidla pro obec nebo skupinu:** připomínky, eskalace, doporučená kauce a výpovědní doba.
  - Kopírují se do `leases.terms.rules` při vytvoření a úpravě smlouvy. Workflow čte fáze připomínek ze smlouvy.
  - Penále v pravidlech není (OQ-24).
- **Poloha smlouvy:** bere se z inzerátu, z volitelného `ruian_id`, jinak z názvu obce v textu adresy.
  - Starší smlouvy se dohledají při příštím přepočtu.
  - Do dev vzorku RÚIAN přibyla Ostrava.
- **Role `investor`** vidí nájemce jen jako iniciály a ke smlouvám nemá přístup.
- **Měna:** portfolio počítá v měně jurisdikce organizace. Portfolio ve více měnách zatím není.
- **Shrnutí od AI:** bez nastaveného LLM se použije shrnutí z pravidel (`mock-rules`).
- Detaily rozhodnutí jsou v ADR 0010.

## M7 – co se změnilo oproti plánu

- **Promo produkty** (`top_7d`, `top_30d`, `highlight_30d`, balíček) jsou globální katalog v `promo_products`, ceny bez DPH, DPH 21 % se počítá při objednávce.
  - Objednávka si kopíruje cenu, typ a délku, takže pozdější úprava katalogu nemění koupené.
  - Topování lze naplánovat (`starts_at`); job `promo_recompute` každých 5 min spouští a ukončuje okna.
- **Vyhledávání:** topované inzeráty jsou první jen u výchozího řazení a relevance; explicitní řazení (cena, plocha, nejnovější) zůstává, štítek „Topováno“ se ukáže vždy.
- **Stripe:** jediný zdroj pravdy o platbě je podepsaný webhook (`stripe_events` pro idempotenci). Zaplacení, propagace, přepočet search a faktura jsou jedna transakce.
  - Hlavička `Stripe-Signature` je v kontraktu nepovinná (generátor u povinné vyráběl kód, který neprošel staticcheckem); chybějící podpis odmítne handler kódem 400.
  - Návratové URL musí mít origin z `WEB_BASE_URL` nebo z `OIDC_REDIRECT_ALLOWLIST` (E2E běží na :4173).
- **Faktury:** číslování `TR-YYYY-NNNNNN` bez mezer (`invoice_counters`), PDF přes Typst v jobu `invoice_delivery`. E-mail obsahuje odkaz na stránku fakturace, ne přílohu (outbox přílohy neumí, PDF vyžaduje přihlášení).
- **Revolut:** majitel připojí vlastní Revolut Business merchant klíč (šifrovaný), platební odkaz vzniká na obligation share, peníze jdou přímo majiteli (ADR 0002). Flag `payments.revolut` (v dev zapnutý, staging/prod se zapíná v backoffice).
- **Feature flagy** jsou v tabulce `feature_flags` s cache 30 s; výchozí hodnoty a `FEATURE_FLAGS` z configu zůstávají jako fallback. Změny jsou auditované.
- **Backoffice:** dashboard metrik, flagy, ceník propagace, fronta AI návrhů nových atributů (`attribute_suggestions`; schválení jen označí návrh, katalog v `packages/attributes` mění vývojář – ADR 0003), přehled a náhled šablon smluv.
- **SvelteKit 3:** přesměrování na platební stránku jiného originu potřebuje `redirect(303, url, { external: true })`.
- Detaily rozhodnutí jsou v ADR 0011.

## M8 – co je hotové a co se změnilo oproti plánu

- **Flutter:** hledání se seznamem a mapou (`maplibre_gl`, při nedostupném stylu spadne na seznam), detail inzerátu (zpráva, žádost, prohlídka), moje prohlídky, v nájmu QR a Revolut odkaz (vzniká až po kliknutí), proklik z push notifikací, `CrashReporter` se Sentry jen při `SENTRY_DSN`. Spodní navigace Hledat / Zprávy / Žádosti / Nájem / Profil. Nativní nastavení iOS/Android pro MapLibre a Sentry na tomto Macu ověřit nejde (`xcodebuild`).
- **Hetzner** (`infra/hetzner`): terraform (app + db VM, privátní síť, firewall, volumy, snapshoty, buckety přes provider `minio`), produkční compose, Caddy, image db s pgBackRest (stanza `terra`, WAL `archive_timeout=60`, RPO ≤ 1 h), WireGuard jen na straně Hetzneru. `terraform validate` prošel (přes Docker image), nic se neaplikovalo.
- **Obnova ze zálohy** je ověřená lokálně: `make restore-test` (full backup, PITR na čas, kontrola dat včetně PostGIS a pgvector).
- **Observabilita** (`infra/hetzner/observability`): Prometheus, Grafana, Loki, Tempo, blackbox, Alertmanager, SLO alerty (99,9 % burn rate, p95 search > 300 ms, zálohy). API a worker mají `/metrics` na `METRICS_ADDR`. Sentry pro web je vlastní malý reporter (oficiální SDK SvelteKit 3 nepodporuje).
- **Bezpečnost:** CSP v SvelteKitu (nonce) a bezpečnostní hlavičky v API, rate limity (search, chat, webhook, žádosti, zprávy, hlášení) – limiter předtím nebyl zapojený do routeru, teď je. CI job `security` (govulncheck, npm audit, pip-audit, osv-scanner, terraform fmt). ASVS L2 checklist v `docs/security/asvs-l2.md`.
- **Cloud LLM fallback:** při výpadku Sparku a zapnutém flagu `ai.cloud_fallback` se stejný požadavek pošle na cloudový gateway (`CLOUD_LLM_*`, výchozí model `claude-sonnet-5-5`). Výstupy jsou dál jen návrhy (ADR 0003); právní otázka Q-AI-1.
- **Právní texty** (koncepty pro právníka) v `packages/attributes/legal`, stránky `/podminky`, `/soukromi`, `/cookies`, `/dsa`, informační cookie lišta (jen nezbytné cookies), seznam DPA v `docs/legal/dpa-checklist.md`.
- **DSA:** tlačítko „Nahlásit inzerát“ i pro anonymní návštěvníky, případ v moderační frontě, rozhodnutí (ponechat / stáhnout / požádat o změnu) dělá člověk, e-maily s odůvodněním. Migrace 00011.
- **Seed Praha:** `terractl import-ruian --region praha`, `terractl onboard-owner [--csv]` (pozvánka s rolí `owner`, povolená jen v DB migrací 00010, API ji dál nepovoluje), 146 stránek Astro pro Prahu, městské části a 12 obcí okolí.
- **Spuštění:** checklist `docs/runbooks/launch.md`, runbooky deploy/restore/backup/incident/seed-praha, smoke testy `make smoke` (jen čtou), nahrávání images do registru v CI, ADR 0012.

## Otevřené body

- **Právní** (`docs/legal-questions.md`):
  - Q-LEASE-1 revize šablon;
  - Q-LEASE-2 úroveň podpisu;
  - Q-LEASE-3 neměnný log vs. výmaz;
  - **Q-RISK-1** profilace a DPIA před ukázáním skóre mimo pilot;
  - Q-STR-1/2 krátkodobé pobyty;
  - **Q-AI-1** přenos do cloudového LLM;
  - **Q-LEGAL-1..4**, **Q-GDPR-6** koncepty právních textů, DSA, nový souhlas při změně verze, cookie lišta, DPO;
  - **Q-BILL-1..3** daňový doklad § 29 vs. zjednodušený, reverse charge/OSS pro EU kupce, souhlas s e-fakturou.
- **Produktové** (`docs/open-questions.md`):
  - OQ-19 Bank iD SIGN;
  - OQ-20 poměrná část nájmu;
  - OQ-21 poskytovatel open bankingu (GoCardless stále přijímá klienty v CZ?);
  - OQ-22 SS přes PSD2;
  - OQ-23 segment krátkodobých pobytů s úklidem (scope §5c.1);
  - OQ-24 úroky z prodlení a penále;
  - OQ-25 kalibrace vah a hranic pásem rizika;
  - OQ-26 tržní faktor za m²;
  - OQ-27 stav platby Revolut (webhook vs. párování z banky);
  - OQ-28 úklid nezaplacených objednávek;
  - OQ-29 jazyk faktur;
  - OQ-30 dobropisy a refundace.
- **Technické:**
  - XLSX export používá novou závislost `github.com/xuri/excelize/v2`.
  - Dev data: smlouvy z dřívějších E2E běhů v dev DB se lokalizují až při přepočtu.
  - M7: stav Revolut odkazu se nesynchronizuje (zůstává `created`); selhané vytvoření Stripe session nechá objednávku `pending`; `listing_title` u objednávky je vždy česky.
  - M7: AI mock navrhuje nový atribut `sauna`, když text inzerátu obsahuje slovo „sauna“ (pro testy fronty návrhů).

## Kde pokračovat (launch)

1. Otevřít PR z `m8-launch`, počkat na CI a mergnout.
2. Projít `docs/runbooks/launch.md`: 15 položek je hotových v repu, 70 čeká, většinou mimo kód. Patří k nim:
   - účty Hetzner a registr, DNS, produkční secrets;
   - WireGuard peer od provozovatele Sparku, do té doby produkce s vypnutými AI flagy;
   - revize právních textů a DPA, penetrační test (zajišťuje zákazník);
   - TestFlight a interní Play track;
   - po prvním nasazení `make smoke` a test obnovy na produkci.
3. Doporučené úpravy před launchem (z ADR 0012 a ASVS):
   - samostatná DB role `NOSUPERUSER NOBYPASSRLS` pro api a worker;
   - minimální délka hesla 12 a kontrola uniklých hesel;
   - rotace klíčů;
   - druhá kopie médií.
4. Push zatím posílají jen zprávy a připomínky prohlídek. Notifikace pro žádosti, smlouvy a platby mají jen konstanty `kind`, odesílatele zatím nemají. Reálné FCM čeká na OQ-14.
5. Testování se živými lidmi: `docs/04-user-testing.md` (fáze T0–T4, brány, scénáře, metriky pilotu).
6. Review implementace: `docs/05-review-implementation.md` (B 7, V 17, S 45, N 50; plán oprav M8b → M8c → M8d v sekci 10).

Pasti prostředí (staré procesy na :8080, `source .env` u ručně spuštěného API, migrace i na `terra_test`) jsou v memory `terrareality-dev-env-quirks.md`.
