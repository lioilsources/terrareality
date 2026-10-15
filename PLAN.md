# Stav projektu (2026-10-15)

Plán a acceptance kritéria: `docs/02-plan.md`. Tento soubor říká, kde jsme a kde začít.

| Milník                                 | Stav                  | Commit / PR                                                |
| -------------------------------------- | --------------------- | ---------------------------------------------------------- |
| M1–M5                                  | hotovo, v `main`      | PR #1–#5                                                   |
| **M6 Leasing**                         | **hotovo, v `main`**  | merge `b9e01c9` (PR #6), poslední commit větve `01efa27`   |
| **M6b Portfolio a riziko**             | hotovo, čeká na merge | PR #7, větev `m6b-portfolio`, commity `f02001f`, `17a3812` |
| M7 Promo, billing, Revolut, backoffice | další na řadě         | –                                                          |

U M6 i M6b prošly `make test`, `make lint`, `make gen-check` a `make e2e` lokálně i v CI.

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

## Otevřené body

- **Právní** (`docs/legal-questions.md`):
  - Q-LEASE-1 revize šablon;
  - Q-LEASE-2 úroveň podpisu;
  - Q-LEASE-3 neměnný log vs. výmaz;
  - **Q-RISK-1** profilace a DPIA před ukázáním skóre mimo pilot;
  - Q-STR-1/2 krátkodobé pobyty.
- **Produktové** (`docs/open-questions.md`):
  - OQ-19 Bank iD SIGN;
  - OQ-20 poměrná část nájmu;
  - OQ-21 poskytovatel open bankingu (GoCardless stále přijímá klienty v CZ?);
  - OQ-22 SS přes PSD2;
  - OQ-23 segment krátkodobých pobytů s úklidem (scope §5c.1);
  - OQ-24 úroky z prodlení a penále;
  - OQ-25 kalibrace vah a hranic pásem rizika;
  - OQ-26 tržní faktor za m².
- **Technické:**
  - XLSX export používá novou závislost `github.com/xuri/excelize/v2`.
  - Dev data: smlouvy z dřívějších E2E běhů v dev DB se lokalizují až při přepočtu.

## Kde začít M7

1. Mergnout PR #7. Pak `git checkout main && git pull && git checkout -b m7-promo-billing`.
2. Přečíst sekci M7 v `docs/02-plan.md`. Acceptance:
   - majitel zaplatí topování kartou, inzerát se posune výš, faktura přijde e-mailem;
   - pro obligation vznikne odkaz Revolut (sandbox).
3. První krok je kontrakt a schéma:
   - doplnit `packages/contracts/openapi.yaml` (promo produkty, objednávky, faktury, Stripe webhook, Revolut odkaz na `obligation-shares/{id}`) a spustit `make gen`;
   - migrace `services/api/migrations/00009_billing.sql`: `promo_products`, `promotions` (inzerát, typ, od–do), `orders`, `invoices`, `payment_links`, vše s RLS přes `app_user_org_ids()`.
4. **Adaptéry vždy s mockem**, aby `make dev` fungovalo offline:
   - `internal/billing` se `StripeClient` (Checkout + webhook se signaturou) a `MockStripe`;
   - `RevolutMerchant` a `MockRevolut` pro odkaz na platbu nájmu jako druhou volbu po QR.
   - Platforma dál nedrží peníze nájemců (ADR 0002). Stripe slouží jen k platbě za služby platformy.
5. **Řazení ve vyhledávání:** topování napojit do `services/api/internal/search/query.go` (sestavení `ORDER BY`, ř. ~265). Topovaný výsledek musí mít transparentní štítek, `listing_search` potřebuje sloupec `boosted_until`.
6. **Faktury:** PDF přes Typst (stejně jako smlouvy, `internal/leasing/render.go`), DPH CZ, e-mail přes outbox (`notify`).
7. **Backoffice** je hotový zčásti v `apps/web/src/routes/(backoffice)/backoffice`: audit, filtry, moderace, recenze, uživatelé, impersonace.
   - Chybí dashboard metrik, fronta AI návrhů atributů a správa šablon a katalogu.
   - Feature flagy jsou zatím v `platform/config` (`Config.Flags`, ř. ~183). Přesunout je do tabulky s cache a editací v backoffice.
8. Postup jako u předchozích milníků:
   - E2E `apps/web/e2e/billing.e2e.ts` s mock Stripe a mock Revolut;
   - integrační test v `services/api/internal/integration`;
   - ADR 0011;
   - na konci `make test lint gen-check e2e`, PR a CI.

Pasti prostředí (staré procesy na :8080, `source .env` u ručně spuštěného API, migrace i na `terra_test`) jsou v memory `terrareality-dev-env-quirks.md`.
