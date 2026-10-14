# TerraReality – scope, analýza a roadmapa (v0.3, 2026-10-14)

Stav: **návrh k diskusi**. v0.2: stack sladěn s ChatShop (Svelte/Astro/Flutter/Go, LLM na DGX Spark), doplněno spolubydlení, vícebuňkové nemovitosti a sdílené vlastnictví s revenue share. Scope odsouhlasen 2026-10-14 (sekce 13). Implementační plán: docs/02-plan.md.

---

## 1. Vize jedním odstavcem

Přeshraniční platforma pro dlouhodobé (a později střednědobé) nájmy bytů a domů ve střední Evropě (CZ → SK → PL → HU → AT/DE), která nekončí u inzerátu. Pokrývá celý životní cyklus nájmu: hledání na zoomovatelné mapě → chat → prověření → smlouva + e-podpis → kauce → nájemné → vyúčtování → předání bytu → reputace. Majitel a správce mají admin ve stylu Shopify (dashboard, „produkty“ = inzeráty, promo, fakturace, vlastní veřejná stránka). Nájemce má jednu identitu a historii, která se s ním stěhuje přes hranice. „Chytrá smlouva“ = deterministický, auditovatelný workflow nájmu s automatickými pravidly, ne nutně blockchain.

---

## 2. Konkurence (stav říjen 2026)

### 2.1 Inzertní portály (marketplace)

| Trh | Hráč | Model | Co umí navíc | Slabina pro nás využitelná |
|---|---|---|---|---|
| CZ | **Bezrealitky** | inzerce bez provize, topování (~99 Kč/boost), balíčky Optimal/Komplet | ověření profilu zájemce + potvrzení bezdlužnosti (zdarma), smlouva od právníků zdarma, řazení ověřených zájemců nahoru | jen CZ(+SK), končí podpisem smlouvy; žádné platby, kauce, vyúčtování; admin pro správce je slabý |
| CZ | **Sreality** (Seznam) | agregátor, hlavně RK | obrovský traffic, Mapy.cz | nájmy jsou vedlejší, inzeráty přes RK s provizí |
| CZ | **UlovDomov / Ideální nájemce** | garantovaný nájem (majitel dostane 84–88 % tržního nájmu), správa, prověření v 6 registrech | klientská zóna, aplikace Houmy (→ přejmenována na Livendo) | drahé, UlovDomov přebírá roli nájemce; nevhodné pro majitele, co chce kontrolu |
| CZ/EU | **Flatio** (Brno) | střednědobé nájmy 1–12 měs., bez kauce, 300+ destinací, akvizice Trawerk (HR, 2024) | platby přes platformu, digitální nájemní smlouva, nomádi/expati | ne dlouhodobé nájmy, ne lokální trh „byt v Třebíči“, provize |
| PL | **Otodom** (OLX Group), OLX | lídr nájmů v PL | reporty trhu, obrovský traffic | klasický portál, konec u kontaktu |
| SK | **Nehnuteľnosti.sk** (United Classifieds – Ringier/Axel Springer), TopReality, Reality.sk | ~1,8 M návštěv/měs. | – | klasický portál |
| HU | **ingatlan.com** (od 1997, lokálně vlastněný), Alberlet.hu | lídr | – | klasický portál |
| EU | **HousingAnywhere**, **Spotahome**, Uniplaces, Nestpick, Rentola | střednědobé, studenti/expati; Tenant Protection (HA drží 1. platbu do nastěhování), Spotahome Plus (garantovaný nájem, 8 % provize) | escrow první platby, garance | malá hloubka v CEE, hlavně velká města, drahé |

### 2.2 SaaS na správu nájmu (bez marketplace)

MojeNájmy.cz (0–499 Kč/měs., napojení na banku, AI predikce), Zvládneme.cz (free tier, párování plateb v placené verzi), Domsys (účetnictví, SVJ), Houmy/Livendo (párování bankovního účtu, hlídání splatnosti), Flatly.cz (vzory smluv), Realfree.cz (průvodce „bez realitky“). V PL: Rendin (estonský, garance nájmu, expanduje do PL), Simpl.rent (screening). V HU/SK prakticky nic silného.

### 2.3 Web3 / „smart contract rentals“

Rentberry (ICO 2017–18, BERRY token) – žádné známky živého produktu v 2026. Propy – zaměřeno na prodej nemovitostí v USA. Poučení: on-chain nájmy nikde nevzlétly, protože platby jsou ve fiatu, právo vyžaduje enforceable smlouvu v národní jurisdikci a GDPR koliduje s nesmazatelností. **Použitelný je princip (deterministická pravidla, escrow, auditní stopa), ne infrastruktura.**

### 2.4 Co z toho plyne

Nikdo v CEE nedělá **end-to-end dlouhodobý nájem přes hranice** (inzerát → smlouva → peníze → reputace) s jedním účtem pro majitele i nájemce. Portály končí u kontaktu, SaaS nemá poptávku, garanční služby jsou drahé a berou majiteli kontrolu, mezinárodní platformy dělají jen mid-term v metropolích.

---

## 3. Čím se odlišit (teze, v pořadí důležitosti)

1. **Nájem jako workflow, ne inzerát.** Stavový automat smlouvy s automatickými pravidly (připomínky, penále, uvolnění kauce, vyúčtování). Obě strany vidí stejný ledger. Důkazy (fotky při předání, odečty měřidel, podpisy) jsou hashované a časově ukotvené → méně sporů.
2. **Portable Tenant Passport.** Ověřená identita (BankID / eID), ověřený příjem, historie plateb a hodnocení z platformy, které nájemce bere s sebou z Brna do Krakova. Pro majitele = nižší riziko, pro nájemce = výhoda v řazení. Bezrealitky má ověření, ale jen pro jeden trh a jednu transakci.
3. **Mapa od státu po ulici**, s agregacemi po administrativních jednotkách (kraj → okres → obec → část obce → ulice) místo pouhých pinů. Pokrytí vesnic a malých měst, kde portály mají slabé UX.
4. **Shopify-like admin + vlastní „storefront“.** Správce/developer dostane brandovanou veřejnou stránku a embed widget se svými nabídkami, role pro tým, fakturaci, promo. To dnes v CEE nemá nikdo pro nájmy.
5. **Přeshraniční od prvního dne v datovém modelu** (jurisdikce na smlouvě, měna, jazyk, daňové/právní šablony), i když start je jen CZ.
6. **Tři segmenty, které portály ignorují**: spolubydlení se skupinovou žádostí a dělením plateb, majitelé budov s rent rollem a rozúčtováním, spoluvlastníci s automatickým dělením výnosu. Každý z nich je zároveň akviziční kanál (jeden správce = 50 inzerátů).
7. **Transparentní ceník.** Inzerce zdarma, platí se za viditelnost a za služby (podpis, screening, escrow). Žádná provize ve výši měsíčního nájmu.

Co **není** odlišení (nedělat to jako hlavní argument): „máme krypto“, „máme AI“, „máme mobilní appku“. To jsou featury, ne důvod přejít.

---

## 4. Role a rozhraní

| Role | Rozhraní | Hlavní joby |
|---|---|---|
| **Hledající / nájemce** | web (SvelteKit) + mobil (Flutter) | hledat na mapě, filtrovat, ukládat, chatovat, podat žádost, podepsat, platit, hlásit závady, hodnotit |
| **Majitel (1–5 bytů)** | admin (web, „Shopify“) | vytvořit inzerát (AI asistence), spravovat zájemce, vybrat nájemce, smlouva, kauce, sledovat platby, vyúčtování služeb |
| **Správce / správcovská firma / developer / majitel budovy** | admin + tým + storefront | portfolio, budovy a jednotky, rent roll, rozúčtování, role (makléř, účetní, údržba), hromadné operace, reporting, API, branding |
| **Spoluvlastník / investor** | vlastnický dashboard (web + Flutter) | podíl, výnos, výplaty, schvalování výdajů, hlasování, výkazy |
| **Skupina spolubydlících** | klient + skupinový chat | společná žádost, dělení plateb, výměna člena |
| **Platforma (my) – backoffice** | interní admin | moderace, fraud, podpora, promo kampaně, fakturace, feature flags, obsah šablon smluv |
| později: **servisní partneři** | partner portál | stěhování, úklid, pojištění, energie, řemeslníci |

„Shopify“ analogie (tvůj ChatShop): chat nahoře řídí mapu a galerii dole, filtry rostou z dat. Admin analogie: Organization (= merchant) → Members + Roles → Properties/Units → Listings (= products) → Channels (vlastní web, náš marketplace, export do jiných portálů) → Apps/Add-ons (screening, e-sign, escrow) → Billing (subscription + usage).

---

## 5. Use cases

### 5.1 Jádro (MVP ±)
- UC-01 Hledání na mapě s drill-down a agregací počtů/mediánu nájmu po oblastech.
- UC-02 Facetové filtrování (dispozice 1+kk…6+1, m², patro, výtah, balkon, lodžie, sklep, garáž/stání, zahrada, zvířata, kuřáci, vybavení, energetická třída, dostupnost od, min/max délka, kauce, služby v ceně, internet, bezbariérovost, MHD vzdálenost…).
- UC-03 Uložené hledání + notifikace (e-mail/push) na nové shody.
- UC-04 Tvorba inzerátu: adresa (RÚIAN/OSM autocomplete), fotky (auto-tagování, blur SPZ/obličejů), AI návrh textu, překlad do 5 jazyků, náhled.
- UC-05 Chat zájemce ↔ majitel s maskovanými kontakty, šablonami odpovědí, pre-screening otázkami, anti-spam.
- UC-06 Žádost o nájem (application) + ověřený profil nájemce + řazení zájemců.
- UC-07 Smlouva: šablona per jurisdikce → vyplnění → e-podpis (BankID SIGN v CZ) → uložení + hash.
- UC-08 Platební kalendář nájmu + párování plateb (open banking) + připomínky + stav dluhu.
- UC-09 Promo inzerátu (topování, zvýraznění, balíčky) + fakturace.
- UC-10 Nahlášení inzerátu / moderace / anti-fraud (duplicitní fotky, podezřelé ceny, požadavek zálohy před prohlídkou).

### 5.2 Rozšíření, které dává smysl doplnit
- UC-11 **Kauce v escrow** s pravidly uvolnění (obě strany potvrdí / lhůta / spor → mediace). Vyžaduje licencovaného partnera (viz 8.6).
- UC-12 **Předávací protokol** v mobilu: fotky, odečty měřidel, stav vybavení, podpis obou stran, hash → důkaz pro případ sporu.
- UC-13 **Vyúčtování služeb** (zákon 67/2013 Sb. – do 4 měsíců po období), výpočet přeplatků/nedoplatků, generování dokumentu.
- UC-14 **Hlášení závad a údržba** (ticket, fotky, přiřazení řemeslníka, náklady, kdo platí).
- UC-15 **Prodloužení / výpověď / zvýšení nájmu** jako řízené workflow s lhůtami podle zákona dané země.
- UC-16 **Tenant Passport**: ověření identity, příjmu (open banking), bezdlužnosti (ISIR veřejně, exekuce/SOLUS přes partnera), historie + rating.
- UC-17 **Cenotvorba**: odhad nájmu z našich dat + veřejných (ČSÚ, Otodom reporty), „váš byt je 12 % pod trhem“.
- UC-18 **Prohlídky**: kalendář slotů, rezervace, video prohlídka, 3D (Matterport link), hromadné prohlídky.
- UC-19 **Spolubydlení / pokoje** (room-level listing, více nájemců na jedné smlouvě, dělení plateb).
- UC-20 **Relokace přes hranice**: průvodce (registr pobytu, pojištění, banka), přepnutí jazyka smlouvy, dvojjazyčné PDF.
- UC-21 **Storefront pro správce**: vlastní subdoména/doména, branding, widget pro embed, lead routing.
- UC-22 **Export/import inzerátů** (XML feedy ve formátech Sreality/Otodom; import z vlastního CRM správce).
- UC-23 **Pojištění** (odpovědnost nájemce, domácnost, garance nájmu) jako affiliate/embedded.
- UC-24 **Daňový podklad** pro majitele (příjmy, výdaje, § 9 ZDP v CZ, obdoba v PL/HU/SK).
- UC-25 **Garantovaný nájem** jako volitelný produkt přes partnera (Rendin-style), ne vlastní bilance.
- UC-26 **Marketplace služeb** při stěhování (stěhováci, úklid, energie, internet) – provize.
- UC-27 **Public API + webhooky** pro správcovské firmy a developery.
- UC-28 **AI asistent**: vysvětlení smlouvy laicky, odpovědi na dotazy k inzerátu, draft odpovědí pro majitele, detekce podvodných inzerátů.

---

## 5b. Tři rozšířené domény (v0.2)

### 5b.1 Spolubydlení (co-living) pro klienty

**Proč:** v prvním trhu (Brno/Praha) tvoří studenti, juniorní IT a cizinci velkou část poptávky a hledají pokoj, ne byt. Portály to řeší inzerátem „pokoj v bytě“ bez nástrojů. Flatio/HousingAnywhere dělají pokoje jen krátkodobě a draze.

**Modely nájmu, které musí systém umět (CZ, obdobně SK/PL/HU):**
1. **Společný nájem** (NOZ § 2270+): všichni spolubydlící jsou nájemci na jedné smlouvě, ručí společně a nerozdílně. Odchod jednoho = dodatek, souhlas majitele.
2. **Hlavní nájemce + podnájemníci** (§ 2274+): jeden má nájemní smlouvu, ostatní podnájemní; majitel musí souhlasit, pokud hlavní nájemce v bytě nebydlí.
3. **Samostatné smlouvy na pokoje** (majitel pronajímá pokoje jednotlivě, společné prostory sdílené): nejjednodušší pro majitele vícebuňkových nemovitostí (viz 5b.2).

**Funkce:**
- Listing na úrovni **pokoje** (Unit typu `room` pod Unit typu `apartment`), s atributy pokoje (m², okno, zamykání, vlastní koupelna) i bytu (společné prostory, počet spolubydlících, pohlaví/věk preference jen jako informace, ne filtr – antidiskriminace).
- **Reverzní inzerát „hledám spolubydlení“**: profil hledajícího (rozpočet, lokalita, životní styl: noční/ranní, zvířata, kouření, home office, hluk) → matching proti volným pokojům i proti jiným hledajícím, kteří chtějí vzít byt společně.
- **Skupina nájemců (TenantGroup)**: vznikne ze skupinového chatu, společně podá žádost na byt, má vnitřní souhlas každého člena před podpisem.
- **Dělení plateb**: jedna obligation na smlouvě se dělí na podíly (rovným dílem nebo podle m² pokoje); majitel vidí, kdo zaplatil; systém upomíná jen dlužníka. Společné výdaje (energie, internet, úklid) jako interní vyrovnání mezi spolubydlícími (bez našeho držení peněz: jen evidence a QR na převod mezi lidmi).
- **Výměna spolubydlícího** jako workflow: odcházející navrhne náhradníka → ostatní schválí → majitel schválí → dodatek smlouvy + podpis → kauce: převod podílu kauce mezi odcházejícím a příchozím (evidujeme, peníze jdou přímo), předávací protokol pokoje.
- **Domovní řád a rozvrh** (úklid, hosté) jako lehká sociální vrstva; není priorita.
- **Důvěra:** Tenant Passport + vzájemné hodnocení spolubydlících (viditelné jen jako skóre, ne volný text, kvůli šikaně).

**Datový model (delta):** `Unit.kind = apartment|room|bed|parking|storage|commercial`, `Unit.parent_id`; `TenantGroup(members, status)`; `LeaseParty.role = tenant|co_tenant|subtenant|guarantor`, `LeaseParty.share_bps`; `PaymentObligation.splits[]`; `RoommateSeekerProfile`; `ReplacementWorkflow`.

### 5b.2 Vícebuňkové nemovitosti pro majitele

**Pro koho:** majitel činžáku/bytového domu, developer s nájemním portfoliem, provozovatel pokojů pro pracovníky (pozor: ubytování ≠ nájem, jiný právní režim, živnost), family office s 20 až 200 jednotkami, obec s nájemními byty.

**Co se mění oproti 1 bytu:**
- **Hierarchie** Property (budova) → Unit (byt/pokoj/garáž/sklep/nebytový prostor) → Lease; společné prostory a společná měřidla na úrovni budovy.
- **Rent roll a obsazenost**: tabulka všech jednotek s nájemcem, nájmem, splatností, koncem smlouvy, dluhem; vakance a turnover kalendář (kdy co končí, co je třeba inzerovat); automatické vytvoření inzerátu z jednotky X dní před koncem smlouvy.
- **Rozúčtování služeb** (zákon 67/2013 Sb. a vyhláška 269/2015 Sb. v CZ): náklady budovy (teplo, voda, výtah, úklid, osvětlení) alokované na jednotky podle klíče (m², osoby, podíl, měřidla, pevný podíl + spotřební složka u tepla). Engine: `CostPool → AllocationRule → UnitShare`; výstup = roční vyúčtování per nájemce s lhůtou 4 měsíce, námitky 30 dní.
- **Měřidla**: odečty (ručně z mobilu s fotkou, později import z dálkových odečtů), historie, odhad při chybějícím odečtu.
- **Údržba napříč budovou**: tickety s lokací (jednotka / společné prostory), dodavatelé, SLA, náklady → do cost poolů.
- **Hromadné operace**: zvýšení nájmu u N smluv s kontrolou zákonných limitů (CZ: max 20 % za 3 roky bez dohody, § 2249), hromadné oznámení nájemcům (odstávka vody), hromadný export.
- **Tým a role**: správce budovy, účetní, údržbář, recepce (u ubytoven), s rozsahem práv na vybrané budovy.
- **Nájemní portál budovy**: nájemci vidí oznámení, hlásí závady, rezervují společné prostory (prádelna, kolárna), stahují vyúčtování.
- **Klíče a přístup**: evidence klíčů/čipů, později integrace chytrých zámků (Nuki, Salto) pro bezkontaktní předání.
- **Reporting**: NOI per budova, výnos per m², vakance v %, dluh, cashflow, srovnání s tržním nájmem v okolí (z našich dat).
- **Komerční prostory**: jiná šablona smlouvy (není chráněný nájem bytu), DPH, indexace inflací.

Tohle je zároveň jádro **správcovského tieru** (předplatné per jednotka/měsíc) a hlavní důvod, proč správcovské firmy přijdou i s nabídkou, kterou nikde jinde nemají ve stejné kvalitě.

### 5b.3 Sdílené vlastnictví a revenue share (fragmentace investice)

**Zadání:** více majitelů vlastní jednu pronajímanou nemovitost a dělí si výnos.

**Právní rámec rozhoduje, co smíme bez licence:**

| Struktura | Jak vzniká | Náš nástroj | Licence |
|---|---|---|---|
| **Podílové spoluvlastnictví** (zapsané v katastru, NOZ § 1115+) | rodina, přátelé, dědictví, 2 až 10 lidí koupí byt | cap table, výpočet rozdělení, hlasování, výkazy | žádná (nezprostředkováváme investici, nedržíme peníze) |
| **SPV (s.r.o.) s podíly** | investoři založí firmu, ta vlastní nemovitost | totéž + výplata podílu na zisku / zápůjčky společníků, podklady pro účetní | žádná pro náš nástroj; převod podílů mimo nás |
| **Crowdfunding / veřejná nabídka podílů** (Investown, Fingood, Upvest v CZ) | platforma nabízí veřejnosti účast | my dodáme „provozní vrstvu“ nemovitosti (nájem, výnos, reporting), partner dělá nábor kapitálu | **ECSP** (nařízení EU 2020/1503) nebo MiFID – partner, ne my |
| **Tokenizace** (Brickwise AT, různé DLT piloty) | podíly jako tokeny | až po usazení EU rámce (MiCA pokrývá jen ne-cenné papíry; tokenizované podíly jsou typicky cenné papíry) | **ne v prvních 2 letech** |

**Doporučení:** fáze 3 postavit **Co-ownership modul** jako nástroj pro existující spoluvlastníky a SPV (žádná licence, reálná bolest: rodinné byty po dědictví, kamarádi co koupili byt na investici, developeři s partnerem). Fáze 5: integrace s licencovaným ECSP partnerem, kde my jsme operátor nemovitosti a oni distribuce podílů.

**Funkce Co-ownership modulu:**
- **Cap table** na Property: `OwnershipStake(party, share_bps, from, to, source=katastr|SPV|dohoda)`, verzovaná; import z katastru (dálkový přístup) pro ověření.
- **Waterfall rozdělení výnosu** (konfigurovatelný per nemovitost):
  1. hrubý nájem (z ledgeru smluv) →
  2. provozní náklady (schválené výdaje, daně, pojištění, správa) →
  3. rezervní fond (x % nebo pevná částka) →
  4. odměna správce/operátora (pokud jeden z vlastníků spravuje) →
  5. distribuovatelný zisk → podle `share_bps` → **výplatní pokyny** (nedržíme peníze: generujeme QR/hromadný příkaz pro vlastníka-správce účtu, nebo ve fázi B výplata přes licencovaného partnera).
- **Schvalování výdajů**: pravidla (do 5 000 Kč správce sám; nad to hlasování; nad 100 000 Kč jednomyslně) – odpovídá NOZ: běžná správa většinou hlasů podle podílů, významné záležitosti 2/3, změna účelu jednomyslně. Hlasování vážené podílem, s lhůtou, výsledkem a zápisem (hash).
- **Dashboard vlastníka**: moje nemovitosti, můj podíl, výnos měsíčně, výplaty, čekající hlasování, dokumenty.
- **Daňové výkazy per vlastník**: podíl na příjmech a výdajích (CZ § 9 ZDP, u SPV podklady pro účetní), roční přehled.
- **Převod podílu**: nabídka ostatním (předkupní právo, pokud sjednáno), evidence převodu, přepočet od data. Samotný převod se děje mimo platformu (notář/katastr), my evidujeme.
- **Smlouva spoluvlastníků** jako šablona (správa, rozhodování, výstup, předkupní právo) s e-podpisem; v SPV společenská smlouva mimo nás.
- **Rezervní fond a kapitálové výzvy**: když nestačí rezerva na opravu, systém spočítá doplatek per vlastník a hlídá úhrady.
- **Oddělení rolí**: spoluvlastník vs. operátor (ten, kdo komunikuje s nájemcem). Nájemce vidí jen operátora.

**Datový model (delta):** `OwnershipStake`, `Waterfall(rules[])`, `Distribution(period, lines[])`, `ExpenseClaim(status, approvals[])`, `Proposal/Vote(weight)`, `CapitalCall`, `OwnerStatement`.

**Rizika:** nesmíme vypadat jako nabídka investice (marketing: „nástroj pro spoluvlastníky“, ne „investujte do bytu“); AML při výplatách řeší partner; dvojí zdanění a mezinárodní vlastníci (PL vlastník CZ bytu) → daňový disclaimer, reporting bez poradenství.
---

## 6. Funkční požadavky (výběr, číslování pro plán)

**FR-1 Účty a identita**
- 1.1 Registrace e-mail/telefon/Google/Apple; 2FA.
- 1.2 Organizace s členy a rolemi (owner, admin, agent, accountant, maintenance, viewer).
- 1.3 Úrovně ověření uživatele: e-mail → telefon → identita (BankID CZ, eID SK, mObywatel PL, Ügyfélkapu HU nebo KYC vendor) → příjem → bezdlužnost.
- 1.4 Jeden účet může být nájemce i majitel.

**FR-2 Nemovitosti a inzeráty**
- 2.1 Property → Unit → Listing (verze). Listing má jurisdikci, měnu, jazykové mutace.
- 2.2 Strukturované atributy (≥ 60), plus volné tagy. Katalog atributů je konfigurovatelný bez deploye.
- 2.3 Média: fotky (WebP/AVIF varianty), půdorys, video, 3D link; řazení; auto-moderace.
- 2.4 Adresa normalizovaná (country → region → district → municipality → part → street → number) + geo bod + volitelně „přibližná poloha“ (nezobrazit přesné číslo).
- 2.5 Stavy: draft → review → published → paused → rented → archived. Automatické stažení po pronájmu.
- 2.6 Duplikace, hromadná editace, import/export.

**FR-3 Vyhledávání a mapa**
- 3.1 Mapa s agregacemi per zoom (clustery/choropleth po admin jednotkách), přepnutí na seznam, split view.
- 3.2 Facety s počty, rozsahy, geo polygon/kreslení oblasti, dojezd (izochrona) – později.
- 3.3 Fulltext s diakritikou a synonymy (garsonka = 1+kk), řazení (relevance, cena, datum, promo).
- 3.4 Uložená hledání, notifikace, porovnání.
- 3.5 Promo řazení transparentně označené.

**FR-4 Komunikace**
- 4.1 Konverzace vázaná na listing + účastníky, přílohy, čtení, typing, push.
- 4.2 Maskování kontaktů do fáze X; detekce vylákání mimo platformu (varování, ne blokace).
- 4.3 Šablony, rychlé odpovědi, automatické pre-screening otázky.
- 4.4 Nahlášení, blokace, moderace.

**FR-5 Žádost a výběr nájemce**
- 5.1 Application s profilem, dokumenty, preferovaným datem, délkou, spolubydlícími.
- 5.2 Majitel vidí přehled zájemců s úrovní ověření a skóre; může pozvat k prohlídce, odmítnout (s důvodem – antidiskriminační ochrana), vybrat.
- 5.3 Prohlídkové sloty.

**FR-6 Smlouvy**
- 6.1 Šablony per jurisdikce (CZ: NOZ § 2235+; PL: najem okazjonalny vs. zwykły; SK: zákon 98/2014 o krátkodobom nájme bytu vs. OZ; HU: Ptk. + Lakástörvény), verzované, s právní revizí.
- 6.2 Generování PDF (dvojjazyčné), proměnné ze systému, vlastní klauzule, limit kauce (CZ max 3× nájem) validovaný.
- 6.3 E-podpis přes adaptér: BankID SIGN (CZ), kvalifikovaný podpis (PL smlouvy >1 rok na dobu určitou vyžadují QES nebo papír), SK/HU partner. Fallback: tisk + upload skenu.
- 6.4 Stavový automat: draft → proposed → negotiating → signed → active → notice_given → terminated → settled; každý přechod = událost s aktérem, časem, hashem.
- 6.5 Dodatky, prodloužení, zvýšení nájmu s kontrolou zákonných lhůt.

**FR-7 Peníze**
- 7.1 Platební kalendář (nájem, zálohy služeb, kauce, jednorázové), splatnosti, měna.
- 7.2 Varianta A „nesaháme na peníze“: párování příchozích plateb na účtu majitele přes open banking (PSD2 AIS), platební odkazy/QR (Revolut Pay, SEPA/QR CZ, BLIK v PL), stav dluhu.
- 7.3 Varianta B „držíme peníze přes partnera“: escrow kauce, výběr nájmu a výplata majiteli (Stripe Connect / Mangopay / Lemonway / Adyen for Platforms). Krypto: stablecoin (EURC/USDC) přes MiCA-licencovaného PSP (např. Confirmo, CZ, licence 12/2025) s automatickým off-rampem – majitel vždy dostane fiat.
- 7.4 Pravidla: připomínka D-3, D+1, D+7; penále dle smlouvy; eskalace; vše konfigurovatelné per smlouva.
- 7.5 Podvojný ledger per smlouva; export CSV/účetní formáty.

**FR-8 Promo, billing, monetizace**
- 8.1 Topování, zvýraznění, balíčky, předplatné pro správce (per unit/měsíc), add-on služby (screening, podpis, escrow), affiliate.
- 8.2 Faktury s DPH per země (OSS), Stripe Billing nebo vlastní.

**FR-9 Backoffice**
- moderační fronta, fraud signály, podpora (impersonace s auditem), feature flags, správa šablon a katalogu atributů, reporting.

**FR-10 Notifikace**: e-mail, push, SMS (jen kritické), in-app; per uživatel preference; i18n.

**FR-11 i18n/l10n**: cs, sk, pl, hu, en, de, uk; měny CZK, EUR, PLN, HUF; formáty; právní texty per země.

---

## 7. Nefunkční požadavky

| Oblast | Požadavek |
|---|---|
| Výkon | vyhledávání p95 < 300 ms, mapové agregace p95 < 200 ms (cache), LCP < 2,5 s na 4G |
| Škála | cíl 2 roky: 200k aktivních inzerátů, 1M MAU, 50M zpráv/rok; architektura bez přepisování |
| Dostupnost | 99,9 % (web/API), plánované odstávky mimo špičku |
| Data | hosting v EU, zálohy RPO 1 h / RTO 4 h, PITR |
| Bezpečnost | OWASP ASVS L2, 2FA, šifrování dokumentů at rest (per-tenant klíče), rate limiting, bug bounty později |
| Soukromí | GDPR: DPIA, minimalizace, retence (dokumenty smluv 10 let dle účetních předpisů vs. právo na výmaz – pseudonymizace), DPA s partnery |
| Audit | neměnný event log, hash řetěz, exporty pro právní spory |
| Compliance | DSA (jsme online platforma → transparentnost řazení, notice & action), AML jen přes licencovaného partnera, eIDAS, spotřebitelské právo (odstoupení od placených služeb) |
| Přístupnost | WCAG 2.1 AA, klávesnice, screen reader pro klíčové toky |
| i18n | žádný hardcoded text, RTL není potřeba, pluralizace |
| Observabilita | OpenTelemetry, tracing, SLO dashboardy, alerting, Sentry |
| Testovatelnost | unit + integrační + E2E (Playwright) pro kritické toky (listing, chat, smlouva, platba) |
| Provoz | infra as code, CI/CD, preview prostředí, feature flags, blue/green |
| Náklady | infra < 1 500 EUR/měs. do 100k MAU (Hetzner + managed služby) |
| Extensibilita | public API v1, webhooky, pluginy/add-ony s verzovaným kontraktem |

---

## 8. Technická architektura (v0.2, sladěno s ChatShop)

### 8.1 Principy převzaté z ChatShop
- **Chat nahoře, obsah dole**: v TerraReality chat (RAG nad inzeráty + nástroje) řídí **mapu a galerii** pod sebou: „2+kk do 18 tisíc v Brně, kde můžu mít psa, blízko VUT“ → nastaví filtry, posune mapu, vrátí karty. Chat je vyhledávací pole, ne widget.
- **Filtry se generují z dat**: ingest pipeline z ChatShop (LLM extrakce atributů → merge do filter schémat kategorie) se přenese na inzeráty: z textu a fotek majitele se vytěží atributy (sklep, lodžie, orientace, materiál, rekonstrukce rok…) a schéma filtrů roste s nabídkou. Katalog atributů (FR-2.2) tak není ruční tabulka.
- **Inference na vlastním železe**: AiStack gateway na DGX Sparku (LiteLLM, OpenAI-compatible, `LLM_BASE_URL`), modely Qwen3-32B pro chat/extrakci, bge-m3 pro embeddingy; žádné per-token náklady. Cloudové API (Claude) jen jako fallback nebo pro moderaci s vyšší přesností, za feature flagem.
- **Mock režim** bez LLM pro vývoj UI.

### 8.2 Stack
| Vrstva | Volba | Poznámka |
|---|---|---|
| Web app (hledání, admin, nájemní portál) | **SvelteKit** + TypeScript + Tailwind, adapter-node | stejný základ jako ChatShop; admin a klient jako dvě route groups v jedné app, nebo dvě apps v monorepu |
| Marketing, SEO lokality, storefronty správců | **Astro** (SSG/SSR hybrid), Svelte islands | tisíce stránek „pronájem bytu <obec>“ a brandované stránky správců, levně a rychle; sdílené Svelte komponenty s webem |
| Mobil | **Flutter** (iOS, Android), jedna app s přepínáním role nájemce/majitel | foto protokoly, odečty, chat, push; Riverpod/Bloc, go_router, Drift pro offline cache |
| Backend | **Go** (modulární monolit) | chi nebo Echo, `sqlc` + `pgx`, migrace `goose`/`atlas`, OpenAPI 3.1 jako kontrakt (`oapi-codegen`) → generované klienty pro TS i Dart |
| Workflow („chytré smlouvy“) | **Temporal** (Go SDK je první třídy) | lease lifecycle, dunning, vyúčtování, výměna spolubydlícího, distribuce výnosu |
| Fronta / jobs | **River** (Go, nad Postgres) | bez Redis v první fázi; Redis jen pro cache map agregací, až bude potřeba |
| Realtime chat | **Centrifugo** (Go) | WebSocket/SSE, presence, historie; Go backend publikuje, Svelte/Flutter SDK existují |
| DB | **PostgreSQL 17 + PostGIS + pgvector** | jedna DB: data, geo, embeddingy, fulltext (`tsvector` + `pg_trgm`), RLS pro multi-tenancy |
| Search | Postgres FTS + facety přes SQL nad JSONB (jako ChatShop) → **Meilisearch** až při >200k inzerátů | méně komponent na startu |
| Mapa | **MapLibre GL** (web i Flutter přes `maplibre_gl`), vektorové dlaždice **PMTiles** na object storage, hranice z OSM + **RÚIAN** (CZ) | agregace per admin jednotka předpočítané Go jobem do materialized views |
| Geocoding | Photon (self-host) + RÚIAN autocomplete | |
| LLM / embeddings | AiStack gateway na Sparku; volání z Go přes OpenAI-compatible klienta | Python `brain` z ChatShop se **nepřenáší**; RAG a extrakce jdou do Go (jednodušší provoz). Pokud bude ingest pipeline složitá (vision, OCR smluv), zvážit samostatný Python worker na Sparku s frontou přes River/HTTP |
| Soubory | S3-kompatibilní (Hetzner Object Storage / MinIO na NAS), imgproxy, ClamAV | |
| PDF smluv | **Typst** (CLI z Go) nebo gotenberg | dvojjazyčné šablony v repu |
| Auth | vlastní v Go (sessions + WebAuthn/2FA) nebo **Ory Kratos**; OIDC pro BankID | |
| E-sign / KYC / open banking / platby | adaptéry v Go: BankID SIGN+CONNECT, Signi/Autenti, GoCardless Bank Account Data, Revolut Merchant, Stripe, Confirmo | rozhraní + mock implementace od začátku |
| Reverse proxy | **Caddy** | jako ChatShop |
| Observabilita | OpenTelemetry (Go), Grafana/Loki/Tempo, Sentry (Svelte, Flutter) | |
| CI | GitHub Actions: Go test/lint, Svelte check, Flutter test, build obrazů | |

### 8.3 Nasazení
- **Dev**: Mac, `docker compose` (Postgres+PostGIS+pgvector, Centrifugo, Temporal dev server), Go `air` reload, SvelteKit dev, Flutter na simulátoru; LLM mock nebo Spark přes LAN.
- **Staging**: NAS (Ubuntu, compose, Caddy) jako v ChatShop, Spark přes LAN/VPN.
- **Produkce**: **doporučuji cloud v EU (Hetzner)**, ne NAS. Důvody: veřejný marketplace s osobními daty a smlouvami potřebuje 99,9 % dostupnost, statickou IP, DDoS ochranu, oddělené zálohy a GDPR-obhajitelné zabezpečení; domácí linka a NAS to neunesou. Spark zůstává inference backend přes WireGuard tunel (Hetzner ↔ Spark), s cloudovým fallbackem, když je Spark nedostupný. Až bude traffic, druhý inference uzel.
- Kontejnery: `api` (Go), `worker` (Go, River + Temporal workers), `temporal`, `centrifugo`, `web` (SvelteKit), `site` (Astro, statika na CDN), `db`, `imgproxy`, `caddy`. Flutter app mluví jen s `api` + Centrifugo.

### 8.4 Monorepo
```
terrareality/
  apps/web        SvelteKit (klient + admin + nájemní portál)
  apps/site       Astro (marketing, SEO lokality, storefronty)
  apps/mobile     Flutter
  services/api    Go: modulární monolit (identity, catalog, search, geo, messaging,
                  leasing, coliving, buildings, coownership, payments, billing,
                  notifications, moderation, ai)
  services/worker Go: River jobs + Temporal workers (sdílí kód s api)
  packages/contracts  OpenAPI spec, generované klienty (ts, dart), JSON schémata atributů
  packages/ui     sdílené Svelte komponenty (web + site)
  infra/          compose (dev, nas), terraform (hetzner), Caddyfile, spark modul pro AiStack
  docs/
```

### 8.5 Doménový model (jádro + v0.2 delta)
```
Organization ─< Membership >─ User ─< VerificationLevel
Organization ─< Property(building|house|apartment) ─< OwnershipStake      [5b.3]
Property ─< Unit(kind, parent_id) ─< Listing ─< ListingVersion
Property ─< CostPool ─< AllocationRule ; Unit ─< Meter ─< MeterReading     [5b.2]
Listing ─< Media, ListingAttribute, Address(geo, admin_path[])
Listing ─< Conversation ─< Message ; TenantGroup ─< GroupMember            [5b.1]
Listing ─< Application(applicant = User|TenantGroup, score)
RoommateSeekerProfile(User)                                                [5b.1]
Lease(jurisdiction, currency, state, template_version) ─< LeaseParty(role, share_bps)
Lease ─< LeaseEvent(hash, prev_hash), Document ─< Signature
Lease ─< PaymentSchedule ─< PaymentObligation ─< ObligationSplit ─< Transaction
Lease ─ Deposit(release_rules) ; Lease ─< HandoverProtocol ; Lease ─< MaintenanceTicket
Property ─ Waterfall ─< Distribution ─< DistributionLine ; ExpenseClaim ─< Approval
Proposal ─< Vote(weight) ; CapitalCall ; OwnerStatement                     [5b.3]
Listing ─< Promotion ; Organization ─< Subscription, Invoice
Report/Flag, AuditEvent, FeatureFlag, Template(jurisdiction, version), FilterSchema
```

### 8.6 Mapa „stát → ulice“
1. Admin hierarchie jako materialized path (`CZ/CZ064/CZ0642/582786/...`), listing má `admin_path[]`.
2. Zoom < Z1 kraje (choropleth/bubliny), Z1–Z2 okresy, Z2–Z3 obce, Z3–Z4 části obce / H3 hexy, Z4+ piny s cenou.
3. Agregace = `GROUP BY admin_path[n]` s filtry; cache klíč hash(filtry)+úroveň; invalidace při změně listingu.
4. Hranice: tippecanoe → PMTiles na object storage; Flutter i web čtou totéž.
5. Textové hledání „Brno-Královo Pole“ → skok na admin jednotku; chat umí totéž přes tool call.

### 8.7 „Chytrá smlouva“ bez blockchainu
- Smlouva = Temporal workflow: podpisy → aktivace kalendáře → měsíční obligation → párování platby → eskalace → settlement kauce (oba potvrdí ⇒ uvolni; nesouhlas ⇒ mediace; neaktivita 30 dní ⇒ uvolni nájemci).
- Každá událost `hash = sha256(prev_hash + payload)`. Volitelně denní kotvení Merkle rootu na veřejný L2 = levný, GDPR-neutrální důkaz neměnnosti. Jediná blockchain věc s hodnotou v roce 1–2.
- On-chain escrow ve stablecoinech = fáze 4+, jen při poptávce; off-chain smlouva v jurisdikci musí vždy existovat.

### 8.8 Multi-jurisdikce
`Jurisdiction` modul: šablony smluv, limity (kauce, výpovědní lhůty, indexace), daňové texty, formát adresy, podpisový provider, KYC, měna. Nový stát = konfigurace + právní revize.

### 8.9 Regulační past: peníze
Přijímat nájemné a přeposílat ho, nebo držet kauci = platební služba (PSD2) → licence. Proto fáze A: peníze jdou přímo nájemce → majitel (QR/odkaz), my párujeme přes open banking (AIS = jen čtení). Fáze B: escrow a výběr přes licencovaného partnera (Mangopay, Stripe Connect, Lemonway). Krypto přes MiCA CASP (Confirmo). Výplaty spoluvlastníkům (5b.3) stejně: fáze A pokyny, fáze B partner.

### 8.10 Pořadí platebních kanálů
QR/open banking párování jako default (0 poplatky, přirozené v CZ/SK/PL/HU), Revolut Pay/odkaz jako první „instant“ varianta (expati, FX), karty přes Stripe jako volba, stablecoiny jako niche. Viz Q1.
---

## 9. Právní a produktová rizika

| Riziko | Dopad | Mitigace |
|---|---|---|
| Studený start marketplace (bez inzerátů nejsou hledající a naopak) | fatální | start v 1–2 městech, nástroj pro majitele jako akviziční hák, feed import pro správce, SEO lokality |
| Platební licence | blokační | fáze A bez držení peněz, partner ve fázi B |
| Šablony smluv špatně → právní odpovědnost | vysoký | právník per země, disclaimer, verze, pojištění profesní odpovědnosti |
| Podvodné inzeráty | reputace | ověření majitele (katastr CZ – dálkový přístup, KYC), žádné zálohy mimo platformu, AI + human moderace |
| Diskriminace při výběru nájemce | právní | neukazovat chráněné údaje do fáze výběru, logovat důvody odmítnutí, audit |
| GDPR vs. neměnný log | střední | hash chain obsahuje jen hashe, osobní data mimo, pseudonymizace při výmazu |
| Závislost na BankID/partnerech | střední | adaptéry, fallbacky |
| DSA povinnosti platformy | střední | transparentní řazení, notice & action, kontaktní bod |

---

## 10. Monetizace (hypotézy)

1. Inzerce zdarma pro soukromé majitele; **promo** (topování, zvýraznění) – ověřený model (Bezrealitky).
2. **Předplatné pro správce a majitele budov** (per jednotka/měsíc, tiery: tým, rent roll, rozúčtování, storefront, API).
2b. **Co-ownership modul**: předplatné per nemovitost/měsíc, nebo % z distribuovaného výnosu (jen evidence, ne držení peněz).
3. **Transakční služby**: e-podpis (např. 199 Kč/smlouva), screening (149–299 Kč), escrow kauce (1–2 %), garance nájmu (partner, 3–8 %).
4. **Affiliate**: pojištění, energie, stěhování, internet.
5. Později: data/reporty o nájemním trhu (B2B), API.

Nájemce platí minimálně (max za vlastní „passport“ ověření nebo nic) – jinak odejde na konkurenci.

---

## 11. Roadmapa (v0.2)

### Fáze 0 – Validace (4–6 týdnů, bez psaní produktu)
- 30 rozhovorů v jednom městě: 15 majitelů (z toho 5 s více jednotkami nebo spoluvlastníků), 10 nájemců (5 cizinců, 5 hledajících pokoj), 5 správců/RK.
- Landing + waitlist ve 3 jazycích, měřit konverzi majitel vs. nájemce vs. hledající pokoj.
- Concierge test: 5 nájmů end-to-end (smlouva + BankID podpis + párování plateb v tabulce), 1 spolubydlení se skupinovou žádostí.
- Právní konzultace: PSD2 hranice, CZ šablony (byt, pokoj/společný nájem, spoluvlastnická dohoda), DSA, hranice „nástroj pro spoluvlastníky“ vs. ECSP.
- Výstup: go/no-go, pořadí modulů, ceník v0.

### Fáze 1 – MVP CZ (3–4 měsíce)
- Go api + SvelteKit web: účty, org, BankID, inzeráty (byt i pokoj), ingest atributů přes Spark, chat-first hledání nad mapou s agregacemi, facety, messaging (Centrifugo), žádosti (jednotlivec i skupina), promo + Stripe Billing, moderace, Astro SEO stránky lokalit.
- Lease v0: šablona CZ byt + společný nájem, PDF (Typst), BankID SIGN, Temporal workflow, platební kalendář s dělením na podíly, QR, ruční potvrzení platby.
- Flutter v0: hledání, chat, push, žádost (bez admin funkcí).
- Metriky: inzeráty/týden, kontakt rate, % smluv dotažených digitálně, podíl pokojů, NPS.

### Fáze 2 – Digitální nájem + budovy (3 měsíce)
- Open banking párování, dunning, předávací protokol (Flutter), měřidla a odečty, rozúčtování služeb, údržba, Tenant Passport v1, hodnocení.
- **Buildings modul**: rent roll, vakance, hromadné operace, cost pooly, nájemní portál budovy; správcovský tier (tým, role, XML feedy).
- Co-living: výměna spolubydlícího workflow, reverzní inzeráty a matching.

### Fáze 3 – SK + co-ownership + storefront (3 měsíce)
- Jurisdikce SK, Astro storefronty správců, public API v1, AI asistent (vysvětlení smlouvy, drafty).
- **Co-ownership modul**: cap table, waterfall, výplatní pokyny, schvalování výdajů, hlasování, výkazy per vlastník.

### Fáze 4 – PL + HU + peníze (4–6 měsíců)
- Jurisdikce PL (najem okazjonalny, QES Autenti, BLIK), HU (Ügyfélkapu, HUF), escrow partner, Revolut Pay, stablecoiny (Confirmo), garance nájmu přes partnera, pojištění, výplaty spoluvlastníkům přes partnera.

### Fáze 5 – Platforma (průběžně)
- ECSP partner pro nábor kapitálu nad našimi nemovitostmi, chytré zámky, marketplace služeb, data produkty, on-chain kotvení, AT/DE.
---

## 12. Co ověřit nejdřív, co počká

**Nejdřív (bez toho nemá smysl stavět):**
1. Přijdou majitelé na nový portál, když je inzerce zdarma a dostanou smlouvu + podpis + hlídání plateb zdarma? (hypotéza: nástroj je hák, marketplace je síťový efekt)
2. Dotáhnou lidé smlouvu digitálně, nebo skončí u PDF a papíru? (concierge test)
3. Zaplatí majitel 150–300 Kč za screening / podpis / topování? Kolik správců chce předplatné?
4. Je poptávka po přeshraničním hledání reálná? (traffic na PL/UA/SK verze landingu, rozhovory s expaty)
5. Právní hranice PSD2 pro párování plateb – jedna konzultace.

**Nejdřív navíc (v0.2):**
6. Je poptávka po pokojích a skupinových žádostech dost velká, aby byla v MVP? (rozhovory se studenty/cizinci)
7. Zaplatí majitel budovy za rent roll + rozúčtování víc než za MojeNájmy/Domsys? (3 pilotní správci)
8. Chtějí spoluvlastníci nástroj, nebo jim stačí tabulka? (5 rozhovorů s rodinnými/kamarádskými spoluvlastníky)

**Počká:**
- Krypto a on-chain cokoliv.
- HU/PL (dokud CZ nemá trakci; SK je levný druhý trh – stejný jazykový prostor, EUR).
- Garantovaný nájem, pojištění, servisní marketplace.
- Investiční platforma / ECSP / tokenizace podílů.
- Chytré zámky, dálkové odečty.
- Mikroservisy, Kubernetes, vlastní AI modely.
- Izochrony, 3D prohlídky, AR.

---

## 13. Rozhodnutí (2026-10-14)

| # | Otázka | Rozhodnutí |
|---|---|---|
| 1 | Platební kanály | QR + open banking párování jako základ, Revolut hned za tím, krypto fáze 4 |
| 2 | Držení peněz | nejdřív jen párovat a generovat pokyny; escrow přes partnera později |
| 3 | První trh | Praha |
| 4 | Primární zákazník | soukromí majitelé; správci a budovy od fáze 2 |
| 5 | Produkce | NAS jen pilot; produkce v cloudu (Hetzner), Spark přes VPN |
| 6 | Backend | Go + Python worker pro vision/OCR |
| 7 | Co-ownership | jen nástroj pro spoluvlastníky; investiční platforma výhledově |
| 8 | Financování | zákazník má finance (právníci, partneři, infra) |
| 9 | Entita a značka | CZ s.r.o. v Praze stačí (Revolut Merchant, Stripe, OSS DPH); doména terrareality.cz; název pro PL/HU se řeší až ve fázi 4 („reality“ je srozumitelné jen v CZ/SK) |
| 10 | Storefront správců | zatím jen admin |
| 11 | AI | lidské schválení všech AI rozhodnutí |
| 12 | Ubytovny / krátkodobé pobyty | zatím jen nájem |

Implementační plán: [02-plan.md](02-plan.md).
---

## Zdroje průzkumu
- Bezrealitky: topování ~99 Kč (bezrealitky.cz/blog/topovani-inzeratu-cena-vyhody), ověření zájemců a smlouva zdarma (hypoindex.cz, mesec.cz, euro.cz)
- UlovDomov / Ideální nájemce: Garant 88 % / Garant Plus 84 % (idealninajemce.cz), dlužníci H1 2026 3,6 % (hypoindex.cz), Houmy → Livendo (houmy.cz)
- Flatio: Tracxn, Crunchbase, flatio.com (300+ destinací, Trawerk 2024)
- Spotahome Plus 8 % provize, HousingAnywhere Tenant Protection (landlord.spotahome.com, housinganywhere.com/secure-payments)
- Portály CEE: onlinemarketplaces.com infographic 2023, Semrush SK 7/2026, Otodom report 3/2026 (globalpropertyguide.com)
- BankID SIGN: bankid.cz/firmy/sign (5 Kč / až 10 dokumentů, AES), kurzy.cz (polovina velkých pronajímatelů nabízí e-podpis)
- PL najem okazjonalny: notářský zápis, limit 10 let, QES pro smlouvy >1 rok na dobu určitou (uniqa.pl, landager.com)
- Revolut Business payment links / Revolut Pay v CZ/PL/HU (revolut.com/en-CZ/business/payment-links, docs.stripe.com)
- MiCA: Confirmo (CZ) licence CBI 12/2025 (prnewswire), EURC/USDC compliant, USDT delistováno (payneteasy.com)
- SaaS správa nájmu CZ: mojenajmy.cz, zvladneme.cz, podpora.domsys.cz, realitnihlidacipes.cz
