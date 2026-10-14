# TerraReality – review scope a plánu (v1, 2026-10-14)

Vstup: [01-scope.md](01-scope.md) (v0.3) a [02-plan.md](02-plan.md) (v1). Stav: **nálezy k zapracování**. Každý nález má závažnost (**B** blokační, **V** vysoká, **S** střední, **N** nízká), zdůvodnění a návrh změny s odkazem na milník v 02-plan. Sekce 7 je soupis změn do plánu, sekce 8 otázky pro právníka. Ověřené regulatorní skutečnosti mají zdroj v sekci 9.

---

## 0. Shrnutí

Scope je nadprůměrně promyšlený. Správná rozhodnutí: platforma nedrží peníze (8.9), člověk schvaluje každé AI rozhodnutí (02-plan §0), jurisdikce jako konfigurace (8.8), hash chain místo blockchainu (8.7), adaptéry s mocky pro každého partnera.

Tři věci, které mohou projekt potopit dřív než technika:

1. **Wedge není ostřejší než Bezrealitky.** Hák „inzerce zdarma + smlouva + ověření“ Bezrealitky už nabízí. Skutečná odlišnost začíná po podpisu, jenže ta nenaplní mapu. Rozhodnutí #4 (soukromí majitelé) jde proti tezi 6 (správce = 50 inzerátů).
2. **MVP je na 26 týdnů zhruba dvojnásobný.** Pět stacků, Temporal, Centrifugo, šest externích adaptérů, LLM chat, PMTiles, skupinové žádosti.
3. **Regulatorní povinnosti vznikají přesně tím, co děláme navíc oproti portálu** (DAC7 kvůli párování plateb, zákon o realitním zprostředkování kvůli výběru nájemce, DSA kvůli obchodníkům, GDPR kvůli skóre a hodnocení). Scope je nezná.

Navíc chybí distribuce, finanční model a několik zákonů z let 2025–2026 (zákon o podpoře bydlení, novely NOZ, EUDI peněženka), které jsou buď riziko, nebo příležitost.

---

## 1. Strategie a trh

| # | Závažnost | Nález | Návrh |
|---|---|---|---|
| 1.1 | **B** | Rozpor rozhodnutí #4 vs. teze 6. V Praze jde většina nájmů přes RK; Bezrealitky drží segment „bez realitky“ s free inzercí, smlouvou i ověřením zájemce. Hák pro soukromé majitele tedy není diferenciátor a nenaplní mapu. | Vybrat **jeden** wedge pro Prahu a MVP mu podřídit: (a) **pokoje + spolubydlení + cizinci** (vysoký turnover, skupinové žádosti nemá nikdo, Flatio/HousingAnywhere drahé a krátkodobé), nebo (b) **malí správci 5–50 jednotek** s rent rollem a importem. Doporučení: (a) jako veřejná tvář, (b) jako zdroj nabídky od dne 1. |
| 1.2 | **B** | Import XML feedů (UC-22) je ve fázi 2. Bez něj je mapa v den 1 prázdná. RK a správci exportují z CRM (RealKo, Realman, …) ve formátu Sreality rutinně. | Přesunout import feedů do **M2**. Inzeráty z feedu označit „od RK/správce“, jiný ceník, žádná free smlouva. |
| 1.3 | **V** | Chybí distribuce: žádný rozpočet na akvizici, CAC, kanály. SEO lokalit (Astro) proti doménové autoritě Sreality/Bezrealitky nese traffic za 12+ měsíců. | Do fáze 0 přidat test kanálů: international office VUT/ČVUT/UK, relokační agentury, HR pražských IT firem, ukrajinské komunitní skupiny, správci s feedem. Měřit cost per onboarded listing. |
| 1.4 | **V** | Chybí finanční model (unit economics, burn, break-even) a cenový test. Monetizace (sekce 10) jsou hypotézy bez čísla. | Fáze 0: fake door „topovat za 149 Kč“ na landingu, Van Westendorp u 15 majitelů, 3 správci s cenou per jednotka. Výstup: jednoduchý model do `docs/04-finance.md`. |
| 1.5 | **S** | Metriky MVP (02-plan §1) nemají likviditu. | Přidat: % inzerátů s ≥ 1 žádostí do 7 dní, medián doby první odpovědi majitele, % inzerátů obsazených do 30 dní. |
| 1.6 | **S** | Název „Terra reality“ je typický název realitní kanceláře; riziko kolize ochranné známky/firmy. | Před registrací domény ověřit ÚPV, EUIPO, obchodní a živnostenský rejstřík. |
| 1.7 | **N** | Konkurence (sekce 2) nezmiňuje institucionální PRS (Heimstaden, AFI Home, Zeitgeist v CZ; Resi4Rent, Vantage v PL), kteří mají vlastní portály a jsou zároveň potenciální kotevní nabídka. | Doplnit do 2.1 a do fáze 2 jako cíl buildings modulu. |

---

## 2. Regulatorní nálezy

| # | Závažnost | Nález | Návrh |
|---|---|---|---|
| 2.1 | **B** | **DAC7** (směrnice 2021/514, zákon 164/2013 Sb. §14 a násl.). Výjimka platí jen pro platformy, kde prodávající pouze zveřejňují inzeráty, bez zprostředkování platby nebo garance. Jakmile generujeme QR s částkou a párujeme příchozí platby, platforma „zná protiplnění“ → velmi pravděpodobně **oznamující provozovatel platformy** pro činnost „poskytnutí nemovité věci“. Povinnost: ohlášení SFÚ do 15 dnů, sběr DIČ/RČ a adresy prodejce, adresa nemovitosti, roční úhrn protiplnění, oznámení do 31. 1. | Otázka pro právníka #1 **před M1**. Datový model: `Organization` a `User` v M1 dostanou pole pro DAC7 (TIN, datum narození, adresa, stát rezidence), `Lease`/`PaymentObligation` musí umožnit roční agregaci per prodejce a nemovitost. Pokud právník potvrdí, M6 acceptance obsahuje export DAC7 XML. |
| 2.2 | **B** | **Zákon 39/2020 Sb. o realitním zprostředkování.** Výběr nájemce, screening, prohlídky a smlouva na míru dohromady se mohou kvalifikovat jako zprostředkování realitní smlouvy → vázaná živnost, povinné pojištění odpovědnosti, status **povinné osoby podle AML zákona** (253/2008 Sb.). Bezrealitky se tomu vyhýbá pozicí „inzertní služba + vzory“. | Otázka #2 před M1. Formulace podmínek a UI: majitel vybírá sám, my poskytujeme nástroje; žádný „náš makléř“. |
| 2.3 | **V** | **Zákon o podpoře bydlení 175/2025 Sb.**, účinný od 1. 1. 2026 (část ustanovení odložena). Zavádí **garantované nájemní bydlení**: majitel, který vloží byt do správy obce nebo organizace poskytující garantované bydlení, má zaručenu úhradu nájmu i škod; dále síť kontaktních míst pro bydlení (KMB) a asistenci v bydlení. Scope to nezná a plánuje „garanci nájmu“ přes drahého partnera ve fázi 4. Pozor: vláda chystá novelu s odkladem části opatření. | Fáze 0: 3 rozhovory s KMB/obcemi. Fáze 2: „garantované bydlení“ jako typ nabídky pro majitele (bez partnera a provize). Sledovat odklad. |
| 2.4 | **V** | **Novely NOZ.** V roce 2025 čtyři novely, od 1. 1. 2026 dalších pět, mezi nimi domněnka doručování písemností do datové schránky u nájmu bytu a domu. „Právník před M6“ nestačí. | Proces: `jurisdictions` verzované s datem účinnosti; čtvrtletní legislativní review; šablona CZ obsahuje klauzuli o doručování (datová schránka, e-mail). |
| 2.5 | **V** | **PENB**: uvedení energetické třídy v inzerci je povinné (zákon 406/2000 Sb. § 7a), sankce pro inzerenta. Scope má třídu jen jako atribut. | M2: validátor při přechodu do `published`; při chybějícím průkazu zobrazit „G“ nebo blokovat podle výkladu právníka. |
| 2.6 | **V** | **Ohlašovací povinnost ubytovatele** (zákon 326/1999 Sb. § 100 a násl.): majitel musí nahlásit cizince cizinecké policii do 3 dnů (portál Ubyport). Téměř nikdo to neví. Dále **potvrzení o zajištění ubytování** pro pobytová řízení (OAMP) je největší bolest expatů. Obdoba SK (hlásenie pobytu cudzinca), PL (meldunek), HU (lakcímbejelentés). | M6: generovat potvrzení o ubytování ze smlouvy; připomínka majiteli na hlášení; Ubyport integrace do fáze 2. Jurisdikce: pole `foreigner_registration` s lhůtou a formulářem. |
| 2.7 | **V** | **DSA**: čl. 30 traceability of traders → KYB majitelů-podnikatelů a RK před publikací (IČO, adresa, bankovní účet, prohlášení o souladu); čl. 24 transparency report; čl. 11–12 kontaktní body; čl. 27 transparentní řazení (promo). EU platforma ODR byla v červenci 2025 zrušena, nelinkovat; odkazovat na ADR ČOI. | M1: KYB flow pro `Organization.kind = business`; M7: štítek promo + popis řazení v podmínkách; M8: transparency report job. |
| 2.8 | **S** | **European Accessibility Act** (účinnost 6/2025) dopadá na e-commerce služby → WCAG 2.1 AA je zákonná povinnost, ne NFR. | Ponechat v průřezových požadavcích, přidat do launch checklistu jako compliance položku. |
| 2.9 | **V** | **GDPR**: skóre zájemce (UC-06, M5) je profilování (čl. 22); ISIR lookup potřebuje právní titul a log; **hodnocení nájemců** je citlivé, ÚOOÚ historicky zakazoval registry neplatičů bez souhlasu. Tenant Passport přes hranice = předávání osobních údajů mezi správci. | Passport jen s výslovným souhlasem nájemce, nájemce řídí, komu a co ukáže (selective disclosure, viz 5.1 EUDI). Skóre jen jako pomůcka s vysvětlením, nikdy jako řazení bez souhlasu. DPIA před M5. |
| 2.10 | **S** | **HU**: klasický Ügyfélkapu skončil v lednu 2025, nahradil ho Ügyfélkapu+ / DÁP (Digitális Állampolgárság). | Opravit FR-1.3. |
| 2.11 | **S** | **PL**: najem okazjonalny vyžaduje notářské prohlášení nájemce o dobrovolném vyklizení → flow nebude plně digitální; najem instytucjonalny jen pro podnikatele-pronajímatele. | Fáze 4: hybridní krok „notář“ ve workflow smlouvy; šablony obou režimů. |
| 2.12 | **S** | **SK**: QR platby = **Pay by square** (jiný formát než CZ SPD); eID přes občiansky preukaz s čipem; zákon 98/2014 o krátkodobom nájme bytu (max 2 roky, 2× prodloužení) je jediný flexibilní režim, jinak OZ s chráněným nájmem. | Fáze 3: `PaymentQrProvider` per jurisdikce (SPD, Pay by square, HU MNB QR, PL bez standardu → BLIK/odkaz); šablony podle 98/2014. |
| 2.13 | **S** | **PSD2 AIS**: souhlas s přístupem k účtu je nutné obnovovat každých 180 dní; GoCardless Bank Account Data má slabé pokrytí HU. | M6: reconnect UX a připomínky; adaptér i pro Tink / Salt Edge. |
| 2.14 | **N** | Spotřebitelské právo u promo: 14 dní na odstoupení, pokud majitel-spotřebitel nesouhlasí s okamžitým plněním. | M7: checkbox souhlasu s okamžitým plněním před platbou. |
| 2.15 | **N** | Antidiskriminace je řešena jen pro CZ (zákon 198/2009 Sb.); PL (Kodeks cywilny + ustawa o równym traktowaniu), SK (365/2004 Z. z.), HU (Ebktv.). | Jurisdikce: seznam chráněných znaků a text důvodů odmítnutí per země. |

---

## 3. Produktové mezery

| # | Závažnost | Nález | Návrh |
|---|---|---|---|
| 3.1 | **V** | **Kauce bez escrow je vektor podvodu**: scope neříká, kdy a komu se platí. Platba kauce před podpisem na účet „majitele“ je nejčastější podvod. | M6: kauce vzniká jako obligation až po podpisu obou stran; **ověření vlastníka z katastru** (ČÚZK dálkový přístup / WSDP, placené) do M2, ne do fáze 2; varování nájemci při jakékoli platbě před podpisem. |
| 3.2 | **V** | **Předávací protokol** (UC-12) je ve fázi 2, ale je základem sporů o kauci, které workflow v M6 řeší. | M6: jednoduchá webová verze (fotky, odečty, podpis obou klikem, hash). Flutter verze fáze 2. |
| 3.3 | **S** | Chybí **turnover smyčka** pro majitele 1–5 bytů: konec smlouvy → automatický návrh nového inzerátu z jednotky. Je jen u budov (5b.2). | M6: event `notice_given` → draft inzerátu z Unit + poslední Listing version. Hlavní retenční mechanismus. |
| 3.4 | **S** | Chybí hlídání zákonných lhůt pro majitele: výpovědní doba 3 měsíce, oznámení zvýšení nájmu, lhůta vyúčtování 4 měsíce, konec doby určité. | M6: timery z `jurisdictions`, notifikace D-90/D-30. |
| 3.5 | **S** | Chybí šablona **souhlasu s trvalým pobytem** na adrese bytu (nejčastější dotaz cizinců i Čechů) a **souhlas s podnájmem** (§ 2275). | M6: dvě doplňkové šablony v Typst. |
| 3.6 | **S** | Kauce u spolubydlení: převod podílu mezi odcházejícím a příchozím „evidujeme, peníze jdou přímo“ – ale bez protokolu pokoje a bez souhlasu majitele s výší je to spor. | 5b.1: do ReplacementWorkflow přidat podpis majitele a protokol pokoje jako povinné kroky. |
| 3.7 | **N** | Chybí **export dat majitele** (portabilita, i jako argument proti vendor lock-in) a import z tabulky (většina malých majitelů má Excel). | M2: CSV import jednotek; M8: export všeho per organizace. |

---

## 4. Technika a plán

| # | Závažnost | Nález | Návrh |
|---|---|---|---|
| 4.1 | **B** | **Rozsah M0–M8 v 26 týdnech** je ~2× realistický i s Claude Code: Go + Python + SvelteKit + Astro + Flutter, Temporal, Centrifugo, 6 adaptérů, LLM chat, PMTiles, skupinové žádosti, open banking, Revolut. | Rozdělit na **MVP-A (12–14 týdnů)** a **MVP-B (10–12 týdnů)**, viz sekce 7. |
| 4.2 | **V** | **Spark jako produkční inference pro chat**: Qwen3-32B na GB10 utáhne jednotky až nízké desítky souběžných streamů. Chat-first vyhledávání pro každého návštěvníka to neunese; WireGuard Hetzner → domácí linka je single point; p95 pro chat není v NFR. | Spark pro asynchronní práci (embeddingy, extrakce atributů, vision). Chat: pravidlový parser jako default, LLM za flagem přes menší model (Qwen3-8B/14B) nebo cloud. NFR: p95 první token chatu < 1,5 s. |
| 4.3 | **S** | Admin hranice z OSM pro CZ je zbytečné: **RÚIAN** má polygony ÚSC, MOMC, částí obce i ulic (ČÚZK open data). SK: ZBGIS/registr adries; PL: PRG/TERYT; HU: jen OSM. | M3: RÚIAN polygony; OSM jen pro HU. |
| 4.4 | **S** | Chybí ochrana proti scrapingu (konkurence a agregátory budou), bot protection, rate limit na search. | M3: rate limiting per IP/účet, honeypot, obrázky přes imgproxy se signed URL. |
| 4.5 | **S** | Astro vedle SvelteKitu zdvojuje routing, i18n a komponenty. | MVP-A: SvelteKit s `prerender` pro `/pronajem-bytu/<obec>`; Astro až pro storefronty (fáze 3). |
| 4.6 | **S** | Temporal od M0 přidává provozní komponentu (server, DB schéma, verzování workflow) dřív, než je potřeba. | MVP-A: stavový automat v Postgresu + River timers (D-3, D+1, D+7). Temporal zavést s vyúčtováním a výměnou spolubydlícího (fáze 2), kdy se workflow skutečně větví. |
| 4.7 | **S** | Flutter v MVP zdvojuje hledání/chat/žádost. | MVP-A: PWA (push přes web push); Flutter od MVP-B jen pro protokol a nájemní portál. |
| 4.8 | **N** | Chybí design/brand workstream, proces podpory (SLA, kanál), runbook moderace. | M0: design tokens v `packages/ui`; M4: runbook moderace; M8: podpora. |
| 4.9 | **N** | RLS + pooling: `SET LOCAL app.current_user` musí být per transakce; pgBouncer jen v transaction mode. | ADR 0004. |

---

## 5. Příležitosti, které v plánu nejsou

| # | Příležitost | Proč teď | Kam |
|---|---|---|---|
| 5.1 | **EUDI Wallet** (eIDAS 2.0): každý členský stát musí nabídnout peněženku do **24. 12. 2026**; povinné přijímání v regulovaných sektorech a u velkých platforem zhruba o rok později. Přesně „Tenant Passport přes hranice“ bez BankID per stát. Můžeme být **vydavatelem atestace „historie plateb nájmu“** (QEAA), kterou si nájemce odnese kamkoli. | Nikdo v CEE realitách to nestaví; cross-border identita zdarma. | M1: `IdentityProvider.eudi` stub (OpenID4VP). Fáze 3: registrace jako relying party, vydávání atestací. |
| 5.2 | **Garantované bydlení ze zákona 175/2025** jako produkt pro majitele přes KMB/obce. | Státem placená garance místo partnera s 3–8 %. | Fáze 0 rozhovory, fáze 2 typ nabídky. |
| 5.3 | **Institucionální PRS a obce** jako kotevní nabídka buildings modulu; obecní bytové fondy přes veřejné zakázky (Registr smluv). | Desítky tisíc jednotek, vlastní portály slabé pro nájemce. | Fáze 2. |
| 5.4 | **Ukrajinská komunita CZ/PL** jako samostatný GTM: uk lokalizace + potvrzení o ubytování + dočasná ochrana. | Stovky tisíc lidí s vysokým turnoverem a bolestí při hledání. | MVP-A. |
| 5.5 | **Rent index per obec** z vlastních dat (jako Bezrealitky index). | PR, SEO, B2B data produkt dřív než fáze 5. | Fáze 2. |
| 5.6 | **MCP / agent-first API** pro hledání. | AI asistenti budou byty hledat za lidi; levné, odlišující, stejné nástroje jako chat (`set_filters`, `search`). | M3 (stejný tool set). |
| 5.7 | **Firemní relokace**: HR platí screening/passport za zaměstnance. | B2B kanál bez marketplace studeného startu. | Fáze 2. |
| 5.8 | **Smlouva s univerzitami** (international office) pro pokoje. | Přímý kanál na segment z 1.1. | Fáze 0/1. |

---

## 6. Co v plánu zůstává správně (nerozporovat)

Nedržení peněz; člověk v AI smyčce; jurisdikce jako konfigurace; hash chain bez kotvení; adaptéry s mocky; Postgres jako jediná DB do 200k inzerátů; monorepo s OpenAPI jako kontrakt; Hetzner pro produkci; co-ownership jen jako nástroj pro spoluvlastníky; žádné ubytovny.

---

## 7. Změny do 02-plan (konkrétní delta)

### 7.1 Nové rozdělení MVP
- **MVP-A (M0–M6', 12–14 týdnů)**: Go api + worker, SvelteKit (klient, admin, nájemní portál, prerender SEO), Postgres, Centrifugo, River. Účty, org, BankID mock+real, KYB, inzeráty byt/pokoj, import feedů, PENB validátor, ověření vlastníka z katastru, ingest atributů (async na Sparku), mapa + facety + pravidlový parser chatu, messaging, žádosti **jednotlivce**, smlouva CZ (byt doba určitá/neurčitá, pokoj) + BankID SIGN, platební kalendář, QR SPD, ruční potvrzení platby, předávací protokol v0, hash chain, DAC7 datové pole, promo + Stripe, backoffice v0.
- **MVP-B (10–12 týdnů)**: skupinové žádosti a TenantGroup, společný nájem, dělení plateb, open banking AIS, Flutter (protokol, nájemní portál, chat), LLM chat za flagem, Temporal migrace workflow, Revolut, Astro storefronty jen pokud fáze 0 potvrdí správce.

### 7.2 Delta per milník
- **M0**: ADR 0004 (RLS + pooling), 0005 (MVP-A bez Temporal/Astro/Flutter), design tokens.
- **M1**: pole DAC7 na `User`/`Organization`; KYB flow pro podnikatele (DSA čl. 30); `IdentityProvider.eudi` stub; oprava HU na DÁP/Ügyfélkapu+; `jurisdictions` verzované s `effective_from`.
- **M2**: import XML feedů (Sreality formát) + CSV import jednotek; PENB validátor; ověření vlastníka (ČÚZK adaptér + mock); štítek „od RK/správce“.
- **M3**: RÚIAN polygony místo OSM; rate limiting a signed image URL; pravidlový parser jako default, LLM za flagem; MCP endpoint nad stejnými nástroji.
- **M4**: runbook moderace; „záloha před prohlídkou“ jako hard flag.
- **M5**: DPIA; skóre jen s vysvětlením a souhlasem; skupinové žádosti → MVP-B.
- **M6**: kauce až po podpisu obou stran; protokol v0; timery lhůt (D-90/D-30); šablony souhlas s trvalým pobytem a podnájmem; klauzule o doručování (datová schránka); potvrzení o ubytování pro cizince + připomínka ohlášení; turnover: `notice_given` → draft inzerátu; DAC7 roční export (pokud právník potvrdí); River timers místo Temporal.
- **M7**: souhlas s okamžitým plněním; popis řazení v podmínkách.
- **M8**: DSA transparency report job; ADR ČOI místo EU ODR; export dat organizace; EAA v launch checklistu.
- **Fáze 0**: cenový test (fake door, Van Westendorp), test kanálů (1.3), 3 rozhovory KMB/obce, 2 rozhovory univerzitní international office, ověření názvu.
- **Fáze 2**: garantované bydlení (175/2025), PRS/obce, rent index, firemní relokace, Ubyport.
- **Fáze 3**: EUDI relying party + vydávání atestací; `PaymentQrProvider` per jurisdikce.

### 7.3 Nové soubory
- `docs/legal-questions.md` (sekce 8) – **před M1**, ne před M6.
- `docs/04-finance.md` – výstup fáze 0.
- `docs/ADR/0004-rls-pooling.md`, `0005-mvp-split.md`.

---

## 8. Otázky pro právníka (před M1)

1. **DAC7**: je platforma, která generuje QR s částkou nájmu a páruje platby přes AIS (bez držení peněz), „oznamujícím provozovatelem platformy“? Pokud ano, rozsah sběru údajů a výjimky (do 30 transakcí/2 000 EUR ročně u nemovitostí neplatí – ověřit).
2. **Zákon 39/2020 Sb.**: kde je hranice mezi inzertní službou s nástroji a realitním zprostředkováním při výběru nájemce, screeningu, prohlídkách a generování smlouvy? Dopad na živnost, pojištění, AML.
3. **DSA**: rozsah čl. 30 pro soukromé majitele vs. podnikatele; co je „obchodník“ u pronájmu jednoho bytu.
4. **GDPR**: právní titul pro skóre zájemce, ISIR lookup, hodnocení nájemců a přeshraniční Tenant Passport; nutnost DPIA; retence smluv vs. výmaz.
5. **Ubytovatel**: dopadá § 100 zákona 326/1999 Sb. na soukromého pronajímatele bytu; co může platforma generovat (potvrzení o ubytování) bez odpovědnosti.
6. **PENB**: důsledek chybějícího průkazu při publikaci; může platforma inzerát blokovat.
7. **PSD2** hranice pro QR + AIS párování (již v 01-scope, potvrdit písemně).
8. **Zákon 175/2025**: může soukromá platforma být „poskytovatelem garantovaného bydlení“ nebo zprostředkovat majitele obci; stav odkladu.
9. **Spotřebitel**: majitel-fyzická osoba jako spotřebitel u promo a add-on služeb; odstoupení.
10. **Doručování**: formulace klauzule o doručování do datové schránky / e-mailu po novele NOZ 2026.

---

## 9. Ověřené zdroje (říjen 2026)

- Zákon o podpoře bydlení 175/2025 Sb., účinnost 1. 1. 2026 s výjimkami; garance pro majitele a KMB; chystaný odklad části opatření: pravniprostor.cz (Vyšlo ve Sbírce zákonů), advokatnidenik.cz 2026-01-02, seznamzpravy.cz (277327).
- DAC7: výjimka pro čistě inzertní platformy bez zprostředkování platby či garance; oznamovaná činnost „poskytnutí nemovité věci“: financnisprava.gov.cz (Sdělení prodejcům, FAQ DAC7), Deloitte DAC 7 leták, zákon 373/2022 Sb.
- EUDI Wallet: povinnost nabídnout peněženku do 24. 12. 2026, přijímání v regulovaných sektorech cca o rok později: gdprlocal.com, gataca.io (eIDAS 2.0 timeline, 3/2026), corbado.com.
- Novely NOZ 2025–2026 včetně doručování do datové schránky u nájmu bytu: Občanský zákoník 2026 (DonauMedia, přehled novel).
- Ostatní (39/2020, 406/2000 § 7a, 326/1999 § 100, DSA, EAA, Pay by square, DÁP) z obecné znalosti – potvrdit právníkem.
