# Stav projektu (2026-10-15)

Plán a acceptance kritéria: `docs/02-plan.md`. Tento soubor říká, kde jsme a kde začít.

| Milník                                     | Stav                 | Commit / PR                                              |
| ------------------------------------------ | -------------------- | -------------------------------------------------------- |
| M1–M5                                      | hotovo, v `main`     | PR #1–#5                                                 |
| **M6 Leasing**                             | **hotovo, v `main`** | merge `b9e01c9` (PR #6), poslední commit větve `01efa27` |
| **M6b Portfolio a riziko**                 | **hotovo, v `main`** | merge `f981a07` (PR #7)                                  |
| **M7 Promo, billing, Revolut, backoffice** | hotovo, čeká na PR   | větev `m7-promo-billing`                                 |
| M8 Flutter v0, produkce, launch            | další na řadě        | –                                                        |

U M6 i M6b prošly `make test`, `make lint`, `make gen-check` a `make e2e` lokálně i v CI.
U M7 prošly lokálně `make test`, `make lint` a `make e2e` (18/18); CI poběží s PR.

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

## Otevřené body

- **Právní** (`docs/legal-questions.md`):
  - Q-LEASE-1 revize šablon;
  - Q-LEASE-2 úroveň podpisu;
  - Q-LEASE-3 neměnný log vs. výmaz;
  - **Q-RISK-1** profilace a DPIA před ukázáním skóre mimo pilot;
  - Q-STR-1/2 krátkodobé pobyty;
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

## Kde začít M8

1. Otevřít PR z `m7-promo-billing`, počkat na CI a mergnout. Pak `git checkout main && git pull && git checkout -b m8-launch`.
2. Přečíst sekci M8 v `docs/02-plan.md`. Acceptance:
   - launch checklist v `docs/runbooks/launch.md` splněn;
   - produkční E2E smoke test;
   - restore ze zálohy ověřen.
3. Pořadí práce:
   - **Flutter:** hledání s mapou (maplibre_gl), chat, žádost, prohlídky, nájemní portál, push. Admin funkce zůstávají na webu. Pozor na `xcodebuild` (memory `terrareality-dev-env-quirks.md`), ověřovat přes `flutter test`.
   - **Hetzner:** terraform (app + db VM, object storage, firewall, snapshoty), compose prod, Caddy TLS, WireGuard ke Sparku, pgBackRest (RPO 1 h) a restore test v runbooku.
   - **Produkční konfigurace M7:** `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_MODE=live`, `REVOLUT_MODE=live`, `PLATFORM_*` údaje dodavatele; prod bez Stripe klíče nenastartuje. Flag `payments.revolut` zapnout v backoffice.
   - **Observabilita:** Grafana + Loki + Tempo, Sentry (web, Flutter), uptime, alerty na SLO.
   - **Bezpečnost:** OWASP ASVS L2, CSP, dependency scan; penetrační test zajišťuje zákazník.
   - **Právní:** podmínky, GDPR, DPA s partnery (včetně Stripe a Revolut), DSA kontaktní bod, cookie lišta; vyřešit Q-BILL-1..3 před ostrou fakturací.
   - **Seed Praha:** adresy a hranice, onboarding 20 pilotních majitelů, Astro stránky.

Pasti prostředí (staré procesy na :8080, `source .env` u ručně spuštěného API, migrace i na `terra_test`) jsou v memory `terrareality-dev-env-quirks.md`.
