# TerraReality – roadmapa testování se živými lidmi (v1, 2026-10-15)

Vstup: [01-scope.md](01-scope.md) §11–12 (hypotézy), [02-plan.md](02-plan.md) §1 (metriky MVP), [03-review.md](03-review.md)
1.3 a 1.5 (distribuce, likvidita), [runbooks/launch.md](runbooks/launch.md) (launch checklist).

Cíl: než se Praha otevře veřejně, ověřit na skutečných lidech, že (1) hlavní toky projdou bez pomoci, (2) majitelé
a hledající produkt chtějí používat a (3) provoz, podpora a právní rámec unesou skutečná data a skutečné smlouvy.

Testování jde v pěti fázích. Každá končí bránou (go/no-go); další fáze začíná, až je brána splněná.

| Fáze | Co | Kdo testuje | Délka | Prostředí |
| ---- | -- | ----------- | ----- | --------- |
| **T0** | Příprava | – | 2 týdny | staging |
| **T1** | Interní dogfooding | tým + 5–8 známých | 1 týden | staging |
| **T2** | Moderované testy použitelnosti | 12 účastníků | 2 týdny | staging |
| **T3** | Uzavřený pilot Praha | 20 majitelů, 50–100 hledajících | 6 týdnů | produkce (jen na pozvánku) |
| **T4** | Otevřená beta Praha | veřejnost | 4 týdny | produkce |

Celkem zhruba 15 týdnů od začátku T0. T0 může běžet souběžně s dokončením M8b a s externími kroky launche.

---

## T0 – Příprava (2 týdny)

**Produkt a kód** (my):

- [ ] Mergnout M8 (PR #9, oprava govulncheck) a M8b (DB role, hesla, rotace klíčů, push, druhá kopie médií).
- [ ] **Staging na Hetzneru**: stejné compose jako produkce, vlastní DB a bucket, doména `staging.terrareality.cz`,
      viditelný pruh „Testovací prostředí“ ve webu i v aplikaci, `noindex`. Partneři v sandboxu: Bank iD sandbox,
      Stripe test mode, Revolut sandbox, GoCardless sandbox, e-maily do Mailpit nebo na testovací doménu.
- [ ] **Produktová analytika** (dnes chybí): PostHog self-host podle 02-plan §1, události pro trychtýře
      (registrace → inzerát → publikace; hledání → detail → zpráva → žádost → smlouva → podpis → první platba),
      bez osobních údajů v událostech, souhlas podle cookie politiky.
- [ ] **Zpětná vazba z aplikace** (dnes chybí): tlačítko „Nahlásit problém / nápad“ ve webu i ve Flutteru
      se screenshotem, URL/obrazovkou, verzí buildu a ID uživatele; ukládá se do backoffice a posílá do GitHub issues.
- [ ] **Registrace jen na pozvánku** pro T3 (feature flag), aby se pilot dal uzavřít.
- [ ] Skript na reset a naplnění stagingu testovacími daty (inzeráty v Praze, uživatelé pro každou roli).
- [ ] Build pro testery: TestFlight interní skupina, Google Play interní track, oba proti stagingu.

**Proces** (my + zákazník):

- [ ] Triáž chyb: GitHub issues se štítky `tester`, `S1`–`S4`, `web`/`mobile`/`api`; triáž 2× týdně.
- [ ] Závažnost a reakce: **S1** ztráta dat, únik dat, nejde přihlášení/podpis/platba → oprava do 24 h;
      **S2** hlavní tok nejde bez obejití → do 3 dnů; **S3** chyba s obejitím → do dalšího sprintu; **S4** kosmetika → backlog.
- [ ] Kanál pro testery (e-mail `beta@`, případně WhatsApp/Signal skupina pro pilot) a kdo odpovídá (do 1 pracovního dne).
- [ ] Testovací scénáře (sekce „Scénáře“) převedené do formuláře s výsledkem úspěch / s pomocí / neúspěch.

**Právo** (zákazník):

- [ ] Souhlas s účastí v testu a informace o zpracování osobních údajů pro testery (nahrávání obrazovky, analytika).
- [ ] Před T3 rozhodnout, zda pilot podepisuje **skutečné smlouvy**: vyžaduje revizi šablon (Q-LEASE-1),
      úroveň podpisu (Q-LEASE-2) a právní texty (Q-LEGAL-1..4). Jinak pilot končí u žádosti a smlouva se podepisuje mimo platformu.

**Brána T0 → T1:** staging běží, analytika zapisuje trychtýře, tlačítko zpětné vazby funguje, buildy jsou v TestFlightu a Play.

---

## T1 – Interní dogfooding (1 týden)

5–8 lidí z týmu a okolí projde všechny scénáře na stagingu, každý aspoň ve dvou rolích (majitel i hledající)
a aspoň na dvou zařízeních. Smyslem je odchytit chyby, kvůli kterým by externí test nedával smysl.

- Celý tok od inzerátu po první spárovanou platbu (sandbox), včetně skupinové žádosti a prohlídky.
- Backoffice: moderace inzerátu, nahlášení inzerátu (DSA), promo a faktura, schválení AI návrhu.
- Matice zařízení (sekce „Zařízení“) – každý řádek aspoň jednou.
- Provoz nanečisto: jeden simulovaný incident podle `runbooks/incident.md` a obnova stagingu ze zálohy.

**Brána T1 → T2:** žádná otevřená S1/S2, všechny scénáře prošly aspoň jednou bez obejití.

---

## T2 – Moderované testy použitelnosti (2 týdny)

12 účastníků, každý 45–60 minut, online nebo osobně, metoda „mluv nahlas“, nahrávání se souhlasem.

| Skupina | Počet | Proč |
| ------- | ----- | ---- |
| Soukromí majitelé (1–5 bytů) | 4 | primární zákazník (scope §13 #4) |
| Malý správce nebo majitel více jednotek ve více městech | 2 | portfolio a riziko (M6b), zdroj nabídky (review 1.1) |
| Hledající – Češi | 2 | základní tok hledání a žádosti |
| Hledající – cizinci (EN) | 2 | přeshraniční poptávka (scope §12 #4), angličtina |
| Skupina spolubydlících | 2 lidé spolu | skupinová žádost, dělení plateb |

Každý účastník plní 4–6 úkolů ze scénářů pro svou roli bez nápovědy. Měří se:

- úspěšnost úkolu (bez pomoci / s pomocí / neúspěch), čas, počet chyb;
- SUS dotazník na konci (cíl ≥ 70);
- 3 otevřené otázky: co bylo matoucí, co chybí, zaplatil(a) bys za X (promo, podpis, prověření – scope §12 #3).

Výstup: seznam nálezů seřazený podle dopadu, opravy S1–S3 před T3. Odměna účastníkům: voucher 500 Kč
nebo pro majitele promo inzerátu zdarma.

**Brána T2 → T3:** každý klíčový úkol zvládne bez pomoci ≥ 80 % účastníků, SUS ≥ 70, opraveny nálezy S1–S3,
splněné body launch checklistu potřebné pro produkci (infra, secrets, zálohy, observabilita, bezpečnost včetně
penetračního testu, právní texty).

---

## T3 – Uzavřený pilot Praha (6 týdnů)

Produkce, registrace jen na pozvánku. Skuteční lidé, skutečné inzeráty, skutečná data.

- **Nabídka:** 20 pilotních majitelů (M8 seed, `runbooks/seed-praha.md`), každý se 1–3 inzeráty, ručně
  onboardovaní („concierge“): pomoc s prvním inzerátem, s výběrem nájemce a se smlouvou.
- **Poptávka:** 50–100 hledajících z kanálů v review 1.3 (international office VUT/ČVUT/UK, relokační agentury,
  HR pražských IT firem, komunitní skupiny cizinců) a z waitlistu z fáze 0.
- **AI:** vypnuté, dokud nepoběží tunel na Spark (launch.md §9); cloud fallback vypnutý do odpovědi na Q-AI-1.
- **Peníze:** platforma nic nedrží (ADR 0002). Nájem jde přímo nájemci → majiteli (QR, Revolut); promo se platí
  přes Stripe skutečně, nebo se pilotním majitelům dává zdarma (rozhodne zákazník).

Rytmus:

- týdně 15minutový hovor s každým aktivním majitelem (prvních 14 dní), krátký dotazník hledajícím po žádosti;
- týdenní report: metriky níže, top 5 nálezů, co se opravilo;
- release jednou týdně (úterý), hotfix S1/S2 kdykoli; každý release prochází `make smoke` proti produkci.

Metriky pilotu (02-plan §1, review 1.5):

| Metrika | Cíl na konci pilotu |
| ------- | ------------------- |
| Aktivní inzeráty | ≥ 30 |
| Inzeráty s ≥ 1 žádostí do 7 dní | ≥ 60 % |
| Medián první odpovědi majitele | < 24 h |
| Konverzace na inzerát | ≥ 5 |
| Smlouvy dotažené digitálně (z podepsaných) | ≥ 50 % |
| Obsazené inzeráty do 30 dní | ≥ 30 % |
| NPS majitelů | ≥ 30 |
| Dostupnost / p95 hledání | 99,9 % / < 300 ms |
| Otevřené S1 | 0 |

**Brána T3 → T4:** splněné cíle aspoň u inzerátů s žádostí, první odpovědi a dostupnosti; žádná otevřená S1/S2;
podpora zvládá dotazy do 1 pracovního dne; právní texty po revizi a bez otevřených blokujících otázek
v `legal-questions.md`; zákazník odsouhlasí otevření.

---

## T4 – Otevřená beta Praha (4 týdny)

Registrace otevřená, štítek „beta“, žádná placená kampaň. Sleduje se, jak se metriky chovají bez osobní péče:
konverze trychtýřů, chybovost v Sentry, zátěž podpory, moderace (nahlášení, podvodné inzeráty).
Výstup: rozhodnutí o veřejném spuštění a vstupy pro detailní plán fáze 2 (02-plan §4).

---

## Scénáře

Každý scénář je krátký úkol se začátkem, cílem a měřením. Mapování na use cases ze scope §5.

**Hledající (web i mobil):**

1. Najdi byt 2+kk do 25 000 Kč v Praze 7 na mapě a ulož hledání (UC-01–03).
2. Zeptej se chatu „pokoj blízko ČVUT do 12 000 Kč se zvířaty“ a otevři nejlepší výsledek (UC-01, UC-28).
3. Napiš majiteli a domluv prohlídku v nabízeném termínu, pak ji přesuň (UC-05, UC-18).
4. Podej žádost sám a jako skupina dvou lidí (UC-06, UC-19).
5. Podepiš smlouvu, zaplať první nájem přes QR nebo Revolut a zkontroluj, že se platba spárovala (UC-07, UC-08).
6. Nahlas podezřelý inzerát (UC-10).
7. Mobil: otevři push o nové zprávě nebo prohlídce a dostaň se na správnou obrazovku.

**Majitel (web):**

1. Zaregistruj se, přijmi pozvánku a zapni dvoufázové ověření.
2. Vlož inzerát bytu i pokoje s fotkami, zkontroluj náhled a publikuj (UC-04).
3. Odpověz zájemcům, vypiš sloty prohlídek, porovnej žádosti a jednu přijmi (UC-05, UC-06, UC-18).
4. Vytvoř smlouvu ze šablony, pošli k podpisu, sleduj platební kalendář a označ platbu (UC-07, UC-08).
5. Portfolio: přidej jednotky ve dvou městech, podívej se na riziko nájmů, exportuj XLSX (M6b).
6. Kup topování inzerátu a stáhni fakturu (UC-09).

**Backoffice (tým):**

1. Schval nebo zamítni AI návrh atributu, zkontroluj, že se nic nepublikovalo samo (ADR 0003).
2. Vyřiď nahlášení inzerátu podle DSA včetně odůvodnění oznamovateli.
3. Spusť a ukonči promo kampaň, vystav dobropis nebo zkontroluj fakturu.

## Zařízení

| Platforma | Minimum |
| --------- | ------- |
| Web desktop | Chrome, Safari, Firefox – aktuální verze |
| Web mobil | iOS Safari, Android Chrome |
| iOS aplikace | iPhone s iOS 17+ (malý a velký displej) |
| Android aplikace | Android 11+, aspoň jeden levnější telefon |
| Přístupnost | jeden průchod hlavním tokem jen klávesnicí a se čtečkou obrazovky (WCAG 2.1 AA, scope §7) |
| Jazyk | každý scénář aspoň jednou v angličtině |

## Rizika

| Riziko | Opatření |
| ------ | -------- |
| Prázdná mapa, hledající nemají co hledat | pilot startuje až s ≥ 30 inzeráty; nábor hledajících spustit až s nabídkou |
| Skutečné smlouvy bez revize šablon | brána T0: bez revize se v pilotu nepodepisuje na platformě |
| Osobní údaje testerů | souhlas, analytika bez PII, nahrávky smazat do 90 dní |
| AI nedostupná (Spark) | AI flagy vypnuté, toky musí fungovat bez AI |
| Únava pilotních majitelů | concierge onboarding, odměna (promo zdarma), max. 1 hovor týdně |
| Chyby v produkci během pilotu | týdenní release, smoke test, rollback podle `runbooks/deploy.md` §3 |

## Kdo za co

| Oblast | My (vývoj) | Zákazník |
| ------ | ---------- | -------- |
| Staging, analytika, zpětná vazba, buildy | ✓ | |
| Nábor testerů a pilotních majitelů, odměny | | ✓ |
| Moderování testů T2 | ✓ (technická část) | ✓ (vedení rozhovorů) |
| Podpora během pilotu | ✓ (S1/S2) | ✓ (první linie) |
| Právní texty, souhlasy, revize smluv | | ✓ |
| Rozhodnutí na branách | návrh | ✓ |
