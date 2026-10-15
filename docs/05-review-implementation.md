# TerraReality – review implementace (v1, 2026-10-15)

Vstup: stav repa po M8 (commit `f50565d`, větev `m8-launch`, PR #9) plus rozpracované M8b na větvi
`m8b-hardening` (DB role, hesla, rotace klíčů, push, druhá kopie médií). Review bylo jen pro čtení, nic se
neměnilo. Sedm oblastí prošlo nezávisle: Go auth a platforma; katalog, hledání, messaging a AI; leasing,
platby a billing; databáze, RLS a kontrakt; web a Astro; Flutter; infra, CI a dokumentace. Rozpracované M8b
navíc prošlo `/code-review`.

Závažnost: **B** blokuje pilot se skutečnými lidmi, **V** vysoká (opravit před pilotem), **S** střední
(opravit v hardening milníku), **N** nízká (backlog). Nálezy označené *(WIP)* jsou v necommitnutém M8b.
Souhrnný plán oprav je v sekci 10.

---

## 0. Shrnutí

Architektura drží to, co slibují závazná rozhodnutí: platforma nikde nedrží ani nepřeposílá peníze
(ADR 0002), žádný výstup AI nemění stav bez člověka (ADR 0003), RLS je zapnuté na všech org tabulkách a
owner kód jde přes `db.AsUser` (ADR 0004), kontrakt je zdroj pravdy a CI hlídá drift generovaného kódu.
Sessions, hesla, TOTP, Stripe webhooky, číslování faktur, hash řetězec smlouvy, pipeline fotek i PITR
obnova jsou nadprůměrně udělané. Nepublikované inzeráty veřejně neunikají.

Co pilot blokuje, jsou čtyři věci, z nichž tři jsou konfigurace nasazení a jedna je autorizace:

1. **Převzetí role nájemce nebo člena skupiny přes neověřený e-mail.** Strany smlouvy a pozvaní členové
   skupin se k účtům párují podle e-mailu bez kontroly `email_verified_at`, registrace vydá session hned.
   Kdo zná e-mail pozvaného, zaregistruje si ho dřív a získá smlouvu, PDF, podpis, výpověď a skupinový chat.
2. **Produkční compose nepředává webu CSP a limit těla požadavku.** V produkci by se neukázala jediná fotka,
   nešlo stáhnout dokument ani přejít na Revolut, a každý upload nad 512 KB by skončil 413.
3. **Caddy health check na `/healthz`.** Degradovaná závislost (vision, worker) shodí celé API na 503.
4. **Mobil nemá persistenci session, odhlášení ani odregistraci push; Android release je podepsaný debug
   klíčem.** TestFlight a Play track v tomto stavu nedávají smysl.

Vedle toho je sedmnáct vysokých nálezů, většinou souběhy a chybějící guardy (výpověď smlouvy kýmkoli,
podpis vs. žádost o změny, souhlasy ve skupině, neomezené čtení uploadu do paměti, rozmazání obličejů bez
retry, přístup k dokladům o příjmu napořád, zápis aplikační role do globálních a append-only tabulek,
jediný `.env` s klíči k zálohám na veřejném VM, červený govulncheck).

Počty: **B 7, V 17, S 45, N 50** (po sloučení duplicit napříč oblastmi), plus 8 nálezů z `/code-review`
nad WIP.

---

## 1. Blokující (B)

| id | oblast | kde | nález | scénář | oprava |
| --- | --- | --- | --- | --- | --- |
| B-1 | leasing + DB | `leasing/service.go:88-91`, `leasing/payments.go:85`, `queries/leasing.sql` `ClaimLeaseParties`, `service.go:387` `writeParties` | Strany smlouvy se navazují na účet podle `users.email` bez kontroly ověření; `Register` vydá session před ověřením. | Útočník zná e-mail nájemce (je v konverzaci/žádosti), zaregistruje si ho, zavolá `GET /v1/leases/mine` → stane se stranou smlouvy: dokumenty, ledger, `POST /sign`, `POST /notice`. Skutečný nájemce se už nenaváže (`user_id` není NULL). | Navazovat jen při `email_verified_at IS NOT NULL` (v UPDATE i ve `writeParties`), ideálně přesunout claim do ověřovací cesty a vyhodit z `access()`. Integrační test „neověřený účet se nenaváže“. |
| B-2 | DB + applications | `migrations/00006` `app_user_group_ids()`, `applications/service.go:291` `JoinGroup`, `Invite` | Stejná důvěra v neověřený e-mail u skupin spolubydlících, navíc uvnitř SECURITY DEFINER funkce RLS. | Neověřený registrant s e-mailem pozvaného vidí skupinu, její chat a žádosti, připojí se a uděluje souhlasy. | `JOIN users u … AND u.email_verified_at IS NOT NULL` ve funkci; `EmailVerifiedAt` v `Join`/`Invite`/`ListMyGroups`. |
| B-3 | web + infra | `infra/hetzner/compose/docker-compose.app.yml:158-170` vs `apps/web/src/env.ts:33-55`, `hooks.server.ts:78-86` | Služba `web` dostává jen API_URL/ORIGIN/MAP_STYLE/SENTRY; `CSP_MEDIA_ORIGINS`, `CSP_FORM_ACTION_ORIGINS`, `CSP_MAP_ORIGINS`, `API_PUBLIC_URL`, `CSP_REALTIME_ORIGIN` padají na `localhost`. | `img-src` povolí `http://localhost:8081` místo imgproxy → žádná fotka; `form-action` bez S3 a Revolut → `?/download` a `?/revolut` Chrome zablokuje. | Předat pět proměnných v compose i `.env.example`, `checkout.revolut.com` do defaultu `CSP_FORM_ACTION_ORIGINS`, ve smoke testu assert `img.naturalWidth > 0`. |
| B-4 | web + infra | adapter-node `BODY_SIZE_LIMIT` (512 KB default), uploady přes form actions v `admin/.../listings/[listingId]/+page.server.ts:109-134`, `zpravy/[id]/+page.server.ts:46-49`, `pas/+page.server.ts:25-29` | Všechny uploady jdou multipartem přes SvelteKit server, limit není v compose nastavený. | Každá fotka z telefonu → 413; založení inzerátu končí po adrese; přílohy chatu a doklady o příjmu také. | `BODY_SIZE_LIMIT=60M` v compose, nebo jeden soubor na požadavek s mapováním `file_too_large`; kontrola velikosti na klientu. |
| B-5 | infra | `compose/Caddyfile:72-76` + `cmd/api/main.go:119-123`, `api/server.go:106-108` | Aktivní health check Caddy na jediný upstream používá `/healthz`, který vrací 503 při selhání jakékoli závislosti (worker heartbeat > 90 s, vision, centrifugo). | Vision spadne na OOM → Caddy označí API jako nezdravé → **všechny** routy 503 „no upstreams“; metriky nevidí provoz, burn-rate alerty mlčí. | Zrušit aktivní health check u jednoho upstreamu, nebo mířit na liveness endpoint (`/v1/version`), nebo `/healthz` vracet 200 + `status: degraded` pro nefatální checky. |
| B-6 | mobil | `api/api_provider.dart:17-26`, `status/status_screen.dart:25-29`, `messaging/messaging_repository.dart:103-119` | Token jen v paměti, žádné odhlášení (`AuthSession.signOut` je mrtvý kód), push zařízení se nikdy nemaže. | Každý studený start = nové přihlášení; na předaném telefonu dál chodí notifikace předchozího uživatele. | `flutter_secure_storage`, obnova při startu, odhlášení volající `logout` + `deletePushDevice` + `ref.invalidate`. |
| B-7 | mobil | `android/app/build.gradle.kts:28-34` | Release build type podepisuje debug keystorem (TODO ze šablony). | `flutter build appbundle --release` jde do Play s debug podpisem; Play ho odmítne nebo se app id zamkne na jednorázový klíč. | `signingConfigs.release` z gitignorovaného `key.properties`, Play App Signing, krok v `launch.md`. |

---

## 2. Vysoké (V)

| id | oblast | kde | nález | scénář | oprava |
| --- | --- | --- | --- | --- | --- |
| V-1 | leasing | `leasing/payments.go:284-323`, `api/leasing_handlers.go:357-367`, `queries/leasing.sql:37-38` | `GiveNotice` smí dát libovolná strana (ručitel, podnájemce) i pronajímatel, `delivered_on` z klienta bez validace; `CancelObligationsAfter` ve stejné tx. | Ručitel pošle `delivered_on=2020-01-01`: smlouva do `notice_given`, všechny otevřené platby zrušené, Temporal ji při dalším ticku ukončí. Výpověď pronajímatele nemá zákonný důvod (§ 2288 OZ). | Jen `tenant`/`co_tenant` (pronajímatel s `reason`); `delivered_on` v [dnes−30 d, dnes+7 d]; zaznamenat `by` + party_id; u společného nájmu zvážit souhlas všech. |
| V-2 | leasing | `leasing/service.go:607-663`, `queries/leasing.sql:34-35` `MarkLeaseSigned` bez guardu stavu | Kontrola `state == proposed` je mimo tx; `CompleteSignature`/`finalize` stav znovu nečtou. | Spolunájemce B pošle `request-changes` a `sign` souběžně (nebo pronajímatel navrhne v2 během podpisu v1): `negotiating → signed`, kalendář a ledger vzniknou nad spornými podmínkami. | V tx `LockLease`, znovu načíst stav, `MarkLeaseSigned … WHERE state='proposed'` (execrows, 409 při 0). |
| V-3 | DB | `migrations/00002` blanket GRANT + ALTER DEFAULT PRIVILEGES pro `terra_app`; REVOKE jen u credential tabulek | Globální tabulky bez RLS (`listing_search` s `org_id`, `filter_schemas`, `filter_schema_groups`, `filter_schema_proposals`, `admin_units`, `ruian_places`, `ruian_staging`, `jurisdictions`, `app_meta`) jsou pro aplikační roli plně zapisovatelné. | Chyba nebo injekce v AsUser cestě (např. dynamický builder v `search/query.go`) přepíše veřejný index cizích organizací. Všichni zapisovatelé už běží v systémovém kontextu. | Migrace: `REVOKE INSERT, UPDATE, DELETE ON <tabulky> FROM terra_app`; test `has_table_privilege('terra_app', t, 'UPDATE') = false` pro tabulky bez RLS. |
| V-4 | DB | `00002` `audit_events_member`, `consents_self`, `identity_verifications_self`, `gdpr_requests_self`; `00009` `orders_member`, `invoices_member`; `00008` `lease_risk_history_member` | Append-only / finanční / identitní tabulky mají ALL policy bez REVOKE. | Člen pod RLS může `UPDATE`/`DELETE` audit své organizace, faktury, objednávky, přepsat vlastní BankID claimy (`birthdate`, `address`), překlopit `gdpr_requests.status`. U `lease_events`, `ledger_entries`, `messages` je to správně. | `REVOKE UPDATE, DELETE ON audit_events, consents, invoices, orders, lease_risk_history FROM terra_app; REVOKE INSERT, UPDATE, DELETE ON identity_verifications …; REVOKE UPDATE ON gdpr_requests …`. |
| V-5 | domény | `storage/storage.go:80-91`, `listing/media.go:112-123`, `messaging/owner.go:86-96`, `applications/passport.go:81-86` | Presigned PUT bez omezení délky; každý konzument dělá `Blob.Get` = `io.ReadAll` celého objektu **před** kontrolou velikosti; doklady o příjmu velikost nekontrolují vůbec. | Přihlášený uživatel nahraje několik GB, zavolá `complete` → worker (fotky) nebo API (přílohy, doklady) spadne na OOM. Levné a opakovatelné. | `StatObject` před `Get` nebo `io.LimitReader(MaxBytes+1)`; dlouhodobě presigned POST s `content-length-range`. |
| V-6 | domény | `listing/suggestions.go:404-435` | Přijetí `privacy_blur` se commitne a `applyRedaction` běží až po tx s request contextem; při selhání vision nebo odpojení klienta zůstane návrh „přijatý“ bez retry; rozmazaný JPEG přepíše PNG/WebP klíč bez aktualizace `content_type/sha256/size`. | Pronajímatel klikne „rozmazat“, dostane chybu nebo nic, fotka zůstane nerozmazaná, záznam tvrdí, že to člověk schválil (ADR 0003). | River job `redact_media` ve stejné tx; `accepted`/`applied_at` až po úspěšném `Blob.Put`; znovu spustit sanitize nad výsledkem. |
| V-7 | domény | `applications/apply.go` `Consent` (~213-245), `queries/applications.sql:70-78` | `GiveConsent` → `CountMissingConsents` → `SubmitApplication` bez zámku řádku. | Dva členové potvrdí souběžně, oba vidí souhlas druhého jako NULL, oba přeskočí submit → žádost navždy `pending_consent`, pronajímatel ji nevidí, `Consent` vrací `no_consent_needed`. | `SELECT … FOR UPDATE` na `applications` (nebo advisory lock) na začátku tx; integrační test se dvěma souběžnými souhlasy. |
| V-8 | domény | `queries/applications.sql:105-113`, `applications/service.go` `people()` | Pronajímatel dostává čerstvé presigned URL na doklady o příjmu u **všech** žádostí vč. `rejected`/`withdrawn`/`accepted`, při každém zobrazení, bez auditu. ADR 0008 slibuje „jen pronajímatelé, kterým se hlásí“. | Zájemce stáhne žádost; za půl roku kterýkoli člen organizace otevře výplatní pásku. | Presign jen pro `submitted/invited/accepted`, po `decided_at + N dní` už ne; samostatný download endpoint s `audit.Record("passport.income_viewed")`. |
| V-9 | web | `admin/orgs/[orgId]/banka/+page.server.ts:33` | `redirect(303, data.link)` bez `{ external: true }`; SvelteKit 3 vyhodí `redirect_external_not_allowed` pro cross-origin cíl. Testem prochází jen mock cesta. | První reálný souhlas s bankou (GoCardless) → 500 místo stránky banky. | `redirect(303, data.link, { external: true })` nebo allowlist bankovních originů. |
| V-10 | web | `packages/attributes/legal/{cs,en}/*.md` (`draft: true`), `register/+page.server.ts:9-10`, `settings/privacy/+page.server.ts:38`, `e2e/api.ts` (`'2026-10'` ×3), `LegalPage.svelte:17-20` | Uživatelé přijímají podmínky, které UI samo označuje jako koncept; verze souhlasu je konstanta na třech místech místo front matteru; koncepty nemají `noindex`. | Změna verze v markdownu bez změny konstant → log souhlasu nese starou verzi; Google indexuje koncepty. | Verzi exportovat z `legal.ts`, `<meta name="robots" content="noindex">` dokud `draft`, sign-off do `legal-questions.md`. |
| V-11 | web | `apps/site/src/lib/api.ts:9`, `layouts/Landing.astro:10`, `docs/runbooks/deploy.md:45-46` | `PUBLIC_APP_URL` default `http://localhost:5173`; runbook zmiňuje jen `API_URL`. | Produkční landing CTA, patička a odkazy ze 146 stránek lokalit míří na localhost. | Build selže při `PROD && !PUBLIC_APP_URL`; jedna konstanta; runbook; smoke assert hostu CTA. |
| V-12 | web + mobil | `tenant/smlouvy/[id]/+page.server.ts:19`, `admin/.../smlouvy/[leaseId]/+page.server.ts:34`, `mobile/leases/leases_repository.dart:39`, `leases_screen.dart:92-101` | Provider podpisu natvrdo `mock`; `invalid_provider` není v `errors.ts`; mobil bez potvrzovacího dialogu a bez ošetření chyb, ignoruje `redirect_url`. | V produkci bez mock signeru každé „Podepsat“ skončí obecnou chybou; s ním nájemci podepisují prostým mock podpisem, aniž by to UI řeklo; na mobilu jeden omylný tap „podepíše“ smlouvu. | Seznam providerů z API/flagu, označit metodu („prostý elektronický podpis“), confirm dialog, mapovat `invalid_provider`. |
| V-13 | mobil | `search/search_repository.dart:74` (`more()`), `:25` pageSize 30; server `search/query.go:244` limit > 100 → 24 | „Načíst další“ zvětšuje `limit` (30→60→90→120) místo `offset`. | Čtvrtý tap pošle limit 120, server vrátí 24 → seznam se **zmenší** z 90 na 24, výsledek 101+ nikdy. | Stránkovat přes `offset` (limit ≤ 100), akumulovat v notifieru, skrýt tlačítko při `items.length >= total`. |
| V-14 | mobil | `messaging/thread_screen.dart:48-59, 99-109`; `messaging_repository.dart:76-97`; seznamy `conversations/applications/leases/viewings/portfolio_screen.dart` | Vlákno bez ošetření chyb (prázdná obrazovka, neodchycená výjimka při odeslání); realtime stream: `late cf.Client`, chyby v async `onListen` nejdou do `out.addError`, `onCancel` před dokončením → `LateInitializationError`; všechny seznamy mapují 401 na „API není dostupné“. | Otevření vlákna z push po expiraci session = blank + Sentry; rychlý návrat = pád; nepřihlášený uživatel na záložce Zprávy je informován, že API neběží. | Společný `errorMessage(ApiException)` + `ApiErrorView` (401 → login, síť → retry); try/catch v `onListen`; nullable client; cancel subscription v `onCancel`. |
| V-15 | mobil | `auth/login_screen.dart:35-38`, `messaging_repository.dart:107` | `mfa_required` se zobrazí jako „Sign-in failed“; MFA, magic link, reset hesla a OIDC na mobilu chybí. | Uživatel s TOTP z webu se na mobilu nepřihlásí a dozví se, že má špatné heslo. | Větev `status == mfa_required` → obrazovka kódu volající `completeMfa`. |
| V-16 | infra | `compose/.env.example:3,36-40,96-97,142-143`, `terraform/main.tf:236-242` | Jeden sdílený `.env` pro obě VM nese S3 klíče pgBackRestu, `PGBACKREST_CIPHER_PASS`, klíče médií i (defaultně) repliky; bucket záloh bez versioningu/object locku, klíče s právem delete. | Kompromitace app VM (veřejný povrch) = přístupové údaje ke smazání záloh DB, médií i repliky. Ransomware smaže všechny kopie. | `.env` per VM (app VM nikdy nevidí `PGBACKREST_*`), zálohy a replika v samostatném Hetzner projektu s vlastními klíči, versioning + noncurrent-expiry lifecycle na bucketu záloh nebo periodická kopie offline. |
| V-17 | infra + CI | `services/api/go.mod:3` (`go 1.26.0`, bez `toolchain`), `ci.yml:25-28,156-162`, kin-openapi v0.142.0, excelize v2.9.0 | `setup-go` instaluje přesně go1.26.0 → govulncheck hlásí stdlib + dva moduly; job `security` je červený, což porušuje pravidlo „done = zelené CI“ a ASVS 10.3/14.2 tvrdí „done“. | PR #9 nelze mergnout; launch gate deklaruje prošlý dependency scan, který neprochází. | `toolchain go1.26.9` do go.mod, `kin-openapi@v0.144.0`, `excelize/v2@v2.11.0`, `go mod tidy`; Dockerfile `golang:1.26-alpine` floatuje na poslední patch. |

---

## 3. Střední (S)

### 3.1 Go auth a platforma

| id | kde | nález | oprava |
| --- | --- | --- | --- |
| S-A1 | `api/auth_handlers.go:14-22,58`, `account/login.go:121-139` | Login, MFA, reset a OIDC callback se omezují jen per IP; žádný per-účet čítač, lockout, audit `login_failed`, notifikace. Credential stuffing z mnoha IP nic nedetekuje (ASVS V2.2.1, V7.2.1). | Per-e-mail bucket v `s.limit`, `users.failed_logins` + `locked_until` s exponenciálním back-offem, audit události, e-mail po N selháních. |
| S-A2 | `httpx/middleware.go:43-46`, `GET /v1/invitations/{token}`, `account/service.go:177-179`, `compose/Caddyfile:26-27` | Tokeny pozvánek (path), magic linků, ověření e-mailu a resetu (query) se zapisují do access logu API i Caddy (→ Loki 30 dní). Kdo čte logy, přehraje neexpirovaný link; pozvánky platí 7 dní. | Maskovat `/v1/invitations/*` v `AccessLog`, token pozvánky do POST body, v Caddy nelogovat `query` pro web doménu (nebo token do fragmentu). |
| S-A3 | `account/mfa.go:46-77`, `api/platform_handlers.go:52-70` | `EnableTOTP` nezneplatní ostatní sessions; `staff()` kontroluje `users.totp_enabled_at` (flag uživatele), ne že tato session prošla druhým faktorem. Starší nebo ukradená pre-MFA session získá backoffice práva zapnutím TOTP. | `RevokeUserSessions(keep=current)` při enable; `sessions.mfa_at` nastavené v `CompleteMFA`; `staff()` vyžaduje `mfa_at IS NOT NULL` při `StaffRequireMFA`. |
| S-A4 | `api/server.go:87-109`, `cmd/api/main.go:118-123` | `/healthz` veřejný, bez limitu, čtyři sondy na požadavek (DB, worker, 2× HTTP, 3 s timeout), vrací syrové chyby (`dial tcp 172.20.0.7:8000`). Amplifikace + disclosure topologie. | Cache výsledku 5–10 s, detaily jen pro staff nebo interní listener, veřejně jen `status` + jména checků. Souvisí s B-5. |
| S-A5 | `api/server.go:83`, `auth_handlers.go:81-89,126-135` | Magic link / forgot / SMS: burst `max(3, burst/3)` pak 1/min na adresu, vždy nový token + e-mail. Až ~1 440 e-mailů/den na oběť, timing oracle existence účtu. | Denní strop per adresa (5/den), znovupoužít otevřený token v TTL, neexistující účet přes stejnou cestu nebo s pevným zpožděním. |
| S-A6 | `config/config.go:190`, `app/app.go:126-129`, `compose/docker-compose.app.yml:70` | Žádný reálný SMS adaptér (`mock`/`log`), produkce má `log`; config odmítá mock banku/Stripe/Revolut v prod, SMS ne. OTP kódy a telefony by šly do logů, `verification_level=phone` nedosažitelný. | Reálný adaptér (GoSMS/Twilio) a odmítnout `SMS_PROVIDER` ≠ real v prod, nebo telefonní ověření v prod schovat za flag; nikdy nelogovat OTP. |
| S-A7 | `config/config.go:182,349-351`, `identity/mock.go:82-129` | `MOCK_IDP` povolený ve `staging`; `/dev/idp/authorize` je veřejná a dovolí zadat libovolný e-mail, `userForSocial` ho auto-linkuje k existujícímu účtu. Kdokoli na stagingu = kdokoli vč. staffu. | `MOCK_IDP` jen dev/test, nebo `/dev/*` za WireGuard/basic-auth a odmítnout mock, když `APIPublicURL` není localhost. |

### 3.2 Katalog, hledání, messaging, žádosti

| id | kde | nález | oprava |
| --- | --- | --- | --- |
| S-D1 | `listing/media.go:131-138,166-174`, `listing/lifecycle.go:77-81,111-123`, `api/catalog_handlers.go:406-440` | Fotka je `ready` před vision; `Submit` bere každou `ready` fotku; backoffice review neukazuje čekající `privacy_blur`. Obličeje a SPZ třetích osob projdou publikací, aniž by se někdo podíval. | `Submit` vyžaduje rozhodnuté `privacy_blur` u zahrnutých fotek (nebo je vyloučí); nerozhodnuté flagy v `BackofficeGetReview`. |
| S-D2 | `listing/service.go:366-416` | `Update` na `review` inzerátu nastaví `draft`, ale nevolá `WithdrawMyPendingVersions` (komentář tvrdí opak); staff schválí starý snapshot. | Stáhnout čekající verze v `Update`, nebo držet `review` a ukázat rozdíl. |
| S-D3 | `search/query.go:151-157,182-187`, `api/search_handlers.go:126` | `build` aplikuje numerické `min/max` na libovolný atribut, `admin_path` a `bbox` bez validace → Postgres error → 500. | Min/Max jen pro `int`/`range`, `admin_path` regex, range bbox, pg syntax error → 400. |
| S-D4 | `applications/viewings.go` `DeleteSlot`, `00006:130` (`ON DELETE CASCADE`) | Smazání slotu kaskádově zruší rezervace bez oznámení; zájemce přijde na neexistující prohlídku. | Načíst aktivní rezervace, zrušit explicitně a `notifyAll("viewing_cancelled")`, nebo zakázat smazání s rezervacemi. |
| S-D5 | `applications/service.go` `Invite`/`Join`, `api/ratelimit.go:66-77` | `POST /v1/groups` a pozvánky bez rate limitu, e-mail nese uživatelské jméno a název skupiny na libovolnou adresu (spam relay); `Join` bez ověřeného e-mailu (viz B-2). | Routy do `RateLimits.Message`, strop pozvánek/den, verified e-mail pro `Join`/`Invite`. |
| S-D6 | `messaging/owner.go:98-100`, `storage.go:108-116`, `attachmentDTOs` | `image/heic` přeskakuje `DetectContentType`; presigned PUT dovolí nastavit `Content-Type`; příjemce dostane plain presigned GET → HTML stránka útočníka ze storage originu. | Sniff HEIC přes `ftyp`, `response-content-disposition: attachment` na GET, nebo server-side re-Put po validaci jako u fotek. |
| S-D7 | `isir/client.go:65,86-93` | Posílá `maxRelevanceVysledku=4`, ale `relevanceVysledku` z odpovědi ignoruje; jakýkoli záznam = „insolvence“. Jmenovec s jiným datem narození označí ověřeného zájemce. | Ověřit škálu relevance ISIR_CUZK_WS, akceptovat jen přesnou shodu, jinak `error`; test nad zachycenou odpovědí. |
| S-D8 | `queries/listings.sql:69-81`, `ListConversations`, `ListNotifications` | Tvrdé limity 200/50 bez stránkování a `total`; agentura s > 200 inzeráty tiše ztrácí nejstarší. (DB F7/F8 níže.) | Cursor pagination v kontraktu, pak sqlc. |
| S-D9 | `applications/apply.go` `Decide`, `queries/applications.sql:115-122` | Accept + `RejectOtherApplications` bez zámku a bez partial unique indexu → dvě přijaté žádosti na jeden inzerát při souběhu; notifikace v druhé tx vrací chybu, ačkoli žádost existuje. | `UNIQUE (listing_id) WHERE status='accepted'`, zámek inzerátu v `Decide`, notifikace přes River. |

### 3.3 Leasing, platby, billing, portfolio

| id | kde | nález | oprava |
| --- | --- | --- | --- |
| S-L1 | `leasing/payments.go:487-537`, `queries/leasing.sql:201-220` | Párování ignoruje `bank_transactions.currency`; 15 000 EUR spáruje 15 000 CZK. | `AND o.currency = $currency` v `OpenSplitsForCode`/`ByAmount`, porovnat `t.Currency`. |
| S-L2 | `leasing/payments.go:504-523` | Bez SS vyhrává první split se stejnou částkou podle `position`; platba spolunájemce B se připíše A, B je upomínán a skórován jako neplatič. | Při > 1 kandidátu se stejnou částkou jen `suggested`, nebo učit `counterparty_account`. |
| S-L3 | `leasing/payments.go:457-480` | `Sync` vkládá transakci autocommitem a páruje v další tx; selhání nechá řádek `unmatched` navždy (`ON CONFLICT DO NOTHING`). | Insert + match v jedné tx, nebo re-match pass na začátku `Sync`. |
| S-L4 *(WIP)* | `migrations/00012_service_role.sql:38` vs `00007:220` | `GRANT … UPDATE, DELETE ON ALL TABLES` pro `terra_service` zahrnuje `lease_events` a `ledger_entries` → append-only záruka ADR 0009 §5 pro roli, pod kterou API reálně běží, padá. | `REVOKE UPDATE, DELETE ON lease_events, ledger_entries FROM terra_service` (zvážit `stripe_events`, `invoices`). |
| S-L5 | `leasing/payments.go:188-216`, `queries/leasing.sql:122-123` | `MarkPaid` validuje `paid+amount <= amount` mimo tx; `AddSplitPayment` bez stropu; souběh s auto-matchem → `paid_amount > amount`, záporná pohledávka, záporné overdue v riziku. | `UPDATE … WHERE paid_amount + $2 <= amount` (execrows) nebo zámek splitu a přeplatek jako kredit. |
| S-B1 | `billing/service.go:325-332`, `stripe.go:210-237` | Jen `checkout.session.completed` s `paid`; `async_payment_succeeded/failed` se ignorují; `payment_method_types` nepřipnuté na `card`. Při zapnutí SEPA v dashboardu zákazník zaplatí, objednávka zůstane `pending`. | `payment_method_types[0]=card`, nebo obsloužit `async_payment_*`. |
| S-B2 | `billing/service.go:382-384` | Nesoulad order/session se zjistí až po `MarkOrderPaidBySession` a vrátí 500 → Stripe retry 3 dny, `stripe_events` se pokaždé rollbackne. | Validovat před zápisem, 2xx po zalogování/auditu. |
| S-P1 | `portfolio/recompute.go:164-175` | `RecomputeStale` skončí na první chybující smlouvě (řazení podle id) → všechny další se už nikdy nepřepočítají. | Log + continue, počítat selhání, označit smlouvu. |
| S-P2 | `portfolio/export.go:68-77`, `leasing/payments.go:233-243` | CSV zapisuje uživatelské řetězce (display_name, adresy) bez neutralizace `= + - @` → formula injection v Excelu. XLSX je bezpečný. | Prefix `'` u buněk začínajících `= + - @ \t \r`. |

### 3.4 Databáze a kontrakt

| id | kde | nález | oprava |
| --- | --- | --- | --- |
| S-F5 | `00007` loop policies `lease_parties_party … ledger_entries_party` (bez WITH CHECK); `00006` `applications_party`, `application_consents_party`, `viewing_bookings_party`; `00005` `message_attachments_party`, `conversations_party` | Chybějící WITH CHECK = USING → nečlenská strana má plný zápis: nájemce pod RLS může měnit `share_bps`, `payment_obligations`, `obligation_splits.paid_amount`, `signatures`; zájemce `applications.status='accepted'`; člen org `consented_at` za zájemce. Živý exploit nenalezen (zápisy jdou v `system()`), ale RLS jako poslední linie je slabší, než ADR 0004/0009 říká. | Rozdělit: `FOR SELECT USING (member OR party)`; `FOR INSERT/UPDATE/DELETE … WITH CHECK (org member)` resp. `applicant_id/user_id/booked_by = app_current_user()`. |
| S-F6 | `00002` `memberships_member` (ALL, jen org scope) | Viewer/investor si pod RLS může `UPDATE memberships SET role='owner'`; matice rolí jen v Go. | Zápisy do `memberships` jen systémově (`REVOKE … FROM terra_app`), nebo `WITH CHECK (app_user_role(org_id) IN ('owner','admin'))`. |
| S-F7/F8 | `ListListings LIMIT 200`, `ListConversations 200`, `ListOrders/ListInvoices 500`, `ListBankTransactions 200`; bez LIMIT: `ListOpenModerationCases` (7 joinů), `ListMunicipalities` (~6 250 řádků), `ListOrgLeases`/`RentRollLeases` (6+ korelovaných subselectů na řádek), `ListLedger`, `ListLeaseEvents`, `ListMembers` | Tiché ořezání (faktury jsou daňové doklady) nebo neomezené selecty (spam vlna → fronta moderace timeoutuje; rent-roll 300 jednotek ≈ 2 000 subselectů). | `limit` + cursor (UUIDv7 `before`) v kontraktu pro faktury, objednávky, inzeráty, konverzace, smlouvy; rent-roll přes lateral/agregované CTE; municipality cache. |
| S-F9 | nová migrace | Chybějící indexy na horkých predikátech: **`group_members(user_id)`** (každá RLS evaluace žádostí), **`lease_parties(email)`** (`ClaimLeaseParties` při každém přístupu ke smlouvě), `auth_tokens(user_id,purpose)`, `tenant_groups(created_by)`, `applications(group_id)`, `applications(org_id)`, `application_consents(user_id)`, `units(parent_id)`, `units(org_id)`, `listings(unit_id)`, `properties(address_id)`, `ledger_entries(party_id)`, `ledger_entries(posting_id)`, `obligation_splits(party_id)`, `signatures(lease_id)`, `message_attachments(conversation_id)`, `moderation_cases(conversation_id)`, `moderation_cases(reporter_id)`, `bank_transactions(split_id)`, `payment_links(lease_id)`, `listing_search.embedding` (bez HNSW → `SimilarByEmbedding` full scan). | Jedna migrace teď, dokud jsou tabulky malé. |
| S-F10 *(WIP)* | `migrations/00012_service_role.sql` | (a) `ALTER MATERIALIZED VIEW … OWNER TO terra_service` vyžaduje členství migrující role v `terra_service` (na managed PG bez superusera selže); (b) `ALTER DEFAULT PRIVILEGES` je vázané na roli, která migraci spustila; (c) `system_all` vznikne jen pro tabulky s RLS v té chvíli, každá budoucí RLS tabulka ji potřebuje. | `GRANT terra_service TO current_user` před OWNER; test `has_table_privilege('terra_service', t, …)` pro všechny tabulky; helper `enable_org_rls(table)`. |
| S-F11 | `00005` `org_display_name(uuid)`, `00006` `group_display_name(uuid)` (SECURITY DEFINER) | Vrátí jméno jakékoli organizace podle UUID; osobní organizace nesou jméno člověka a `GetPublicListing` vrací `org_id` → de-anonymizace soukromých pronajímatelů před kontaktem. | Omezit na organizace, s nimiž má volající vztah, nebo `''` pro `kind='personal'`, nebo nevracet `org_id` veřejně. |

### 3.5 Web a Astro

| id | kde | nález | oprava |
| --- | --- | --- | --- |
| S-W1 | `lib/catalog.ts:65-68` + „Kč“ literál v ~12 šablonách (`ListingCard.svelte:45`, `LeaseSummary.svelte:34-53`, `LeasePayments.svelte:92-94`, `lib/portfolio.ts:51`, …) | `formatMoney` ignoruje `currency` z API; EUR/PLN se ukáže jako Kč. Totéž na mobilu (`leases_screen.dart:21` `money()` navíc ořezává haléře). | `formatMoney(minor, currency, locale)` přes `Intl.NumberFormat`; na mobilu `NumberFormat.simpleCurrency`. |
| S-W2 | `messages/cs.json` (`search_results`, `msg_unread`, `app_slot_free`, `listing_min_term`, `pf_city_leases`, `billing_days`), `hledat/+page.server.ts:53`, `settings/profile/+page.svelte:34`, `login/+page.svelte:63` | Žádné české plurály („1 nabídek“), tři hardcoded řetězce. cs/en klíče jsou 1033/1033. | Paraglide variant/plural u počtů; literály do messages. |
| S-W3 | `lib/leasing.ts:58` vs `lib/catalog.ts:56-63` | Druhý `toMinor` bez čárky/mezery: „12 500,50“ → NaN → `rent_amount: null`. | Smazat duplicitu. |
| S-W4 | `inzerat/[id]/+page.server.ts:16`, `hledat/+page.server.ts:19,27`, `backoffice/reviews/[versionId]/+page.server.ts:14`, `pas/+page.server.ts:7` | Non-null assertions na sekundárních voláních → výpadek `/v1/attributes` dělá z SEO vstupů 500 a Sentry na každý požadavek. | `error(503)` s přívětivou stránkou nebo render bez labelů. |
| S-W5 | `lib/components/map/SearchMap.svelte:4-5` | `maplibre-gl` + CSS staticky importované → ~1 MB v chunku `/hledat` i v SSR bundlu, LCP hlavní akviziční stránky. | Dynamický import v `onMount`. |
| S-W6 | `zpravy/[id]/+page.svelte:66-69`, `lib/realtime.ts:51` | Subscription jednou v `onMount` s id zachyceným; `invalidateAll()` po blokaci neresubscribuje; selhání tokenu jen `live=false` bez retry; jen posledních 100 zpráv bez „starší“. | `$effect` klíčovaný na `c.id`, retry/backoff, akce load-older. |
| S-W7 | `backoffice/users/[userId]/+page.server.ts:23-25`, `impersonation/end/+server.ts:11` | Staff session uložená na 2 h; po konci obnovena s pevným 30denním `maxAge`; vnořená impersonace přepíše stash. | Uložit `expires_at`, odmítnout vnořenou impersonaci. |

### 3.6 Mobil

| id | kde | nález | oprava |
| --- | --- | --- | --- |
| S-M1 | `AndroidManifest.xml:24-27`, `ios/Runner/` bez `.entitlements` | Žádný deep-link/universal-link config, žádný `aps-environment`; e-mailové odkazy otevřou web, iOS push nejde zapnout bez nového entitlements souboru. | Intent filter `autoVerify` pro `https://terrareality.cz/{zpravy,zadosti,smlouvy,inzerat,prohlidky}`, `Runner.entitlements`, AASA/assetlinks, go_router na příchozí URI. |
| S-M2 | `api/api_provider.dart:9-14`, `launch.md:158` | Release default `http://localhost:8080` bez `kReleaseMode` guardu → store build bez define míří na localhost, ATS zablokuje http. | `if (kReleaseMode && fromEnv.isEmpty) throw` nebo produkční URL jako release default. |
| S-M3 | `push/push_registrar.dart:13-23`, `messaging_repository.dart:109-118` | Bez token-refresh streamu, bez unregister, registrace jen v `signIn` (ne při obnovené session), selhání `registerPushDevice` shodí `signIn`. | `PushRegistration` služba nad `authSessionProvider` + `onTokenRefresh`, chyby jen logovat, mazat zařízení při odhlášení. |
| S-M4 | `search/listing_map.dart:122,164-194`, `search_screen.dart:142-144` | `_programmaticMove` se maže až dalším `onCameraIdle`; když fit kameru nepohne, první pan uživatele se spolkne; markery se přestavují každý `build` → `clearCircles/addCircles` při každém rebuildu (flicker). | Timeout/porovnání pozice; memoizace markerů. |

### 3.7 Infra a CI

| id | kde | nález | oprava |
| --- | --- | --- | --- |
| S-I4 | `docker-compose.app.yml` (api 141-147, web 157-170, temporal 229-247) | Žádný `healthcheck:` na api, web, worker, vision, centrifugo, imgproxy, temporal, clamav; `depends_on` jen `service_started`; bez limitů paměti/CPU. 502 burst při každém deployi, zaseklý proces se nerestartuje, ClamAV/Temporal může vyhladovět API. | Healthchecky, `condition: service_healthy`, `deploy.resources.limits` aspoň pro clamav, temporal, vision. |
| S-I5 | `ci.yml:32-36,60-63` vs `Makefile:47-48` | CI kontrola generovaného kódu nepokrývá `internal/catalog/catalog.json` a `internal/leasing/templates`, které `make gen-check` hlídá. | V jobu `go` spustit `make gen-check`. |
| S-I6 | `alertmanager/alertmanager.yml:4-5,25`, ADR 0012 §4, `launch.md:84`, `incident.md:52-53` | Alerty jen e-mailem s placeholder smarthostem; `severity=page` bez paging kanálu; dokumentované ztlumení LLM alertů 07–13 h neexistuje a LLM pravidla nejsou. | Push/SMS receiver pro `page`, reálné SMTP před go-live, LLM pravidla + `mute_time_intervals` nebo smazat tvrzení z docs. |
| S-I7 | `docker-compose.app.yml:175` + `infra/dev/centrifugo/config.json:14-18` | Produkce mountuje **dev** config Centrifuga (admin UI, `password: admin`, dev HMAC klíče) a spoléhá na env override; změna precedence při upgradu tiše zapne admin s heslem `admin` na :8000. | Vlastní `compose/centrifugo.json` bez `admin` bloku a dev tajemství. |
| S-I8 | `docker-compose.app.yml:172,186`, `infra/nas/docker-compose.yml:24` | Major-only tagy `centrifugo:v6`, `imgproxy:v3`, `caddy:2`; rollback přes `IMAGE_TAG` je nevrátí. | Pin na minor/patch nebo digest. |
| S-I9 | `ci.yml` (bez `permissions:`, akce pinnuté tagem, bez `timeout-minutes`, bez dependabot) | Supply chain: mutable tagy, default token scopes, bez automatických dependency PR. | `permissions: contents: read`, SHA pin, timeouty, Dependabot/Renovate pro actions, go, npm, pub. |
| S-I10 | `ci.yml:206-208`, `services/api/Dockerfile:8` | Image bez `--build-arg VERSION/COMMIT/BUILT_AT` → `/v1/version` v prod hlásí `dev`, Sentry/logy nelze korelovat se sha. | Předat build-argy z `$GITHUB_SHA`. |
| S-I11 | `db/pgbackrest.conf:34-35`, `rules/platform.yml:77-83` | `archive-async=y` + `archive-push-queue-max=4GiB`: při delším výpadku S3 pgBackRest **zahodí** WAL a PITR řetězec je přerušený do příštího full backupu (neděle); nic nevynutí full backup po incidentu. | Alert na `pg_stat_archiver.failed_count`, post-incident krok `backup-run.sh full`, větší spool. |
| S-I12 | `db/postgresql.conf:5`, `docker-compose.db.yml:35-36,59-60`, `DATABASE_URL … sslmode=disable` | PostgreSQL na privátní síti Hetzneru bez TLS vč. hesel a dat; vSwitch izoluje, nešifruje (ASVS 9.2 „partial“). | `ssl=on` s interní CA, `sslmode=verify-full` (min. `require`) na api/worker/exporter. |
| S-I13 | `observability/docker-compose.yml:18-21,52` | Celý app stack (`include:`) vyžaduje `/etc/terrareality/secrets/alert_smtp_password`; bez něj `docker compose up` spadne pro všechny služby. | Volitelný secret v override souboru, nebo krok 0 v `deploy.md` §1.3. |

---

## 4. Nízké (N)

**Go auth a platforma:** impersonátor smí měnit telefon, stahovat GDPR export, rušit sessions (`account/me.go:56-80`, `phone.go`, `gdpr.go`); `accept_terms_version` z klienta se neporovnává s `Cfg.TermsVersion` (`login.go:62-69`); `finishFlow` mapuje DB chyby na 400 a vrací syrové provider chyby v 503 (`oidc.go:66-82`); expirované sessions se nikdy nemažou (`queries/sessions.sql`, `jobs/messages.go:110`); `cfg.HSTS` se nepředává do routeru (`cmd/api/main.go:145-149`); nebezpečné defaulty mimo dev (`OIDC_REDIRECT_ALLOWLIST` s localhost, dev `IMGPROXY_KEY/SALT`, `SESSION_TTL_MOBILE` tiše ořezaný na `SESSION_MAX_AGE`) (`config.go:173,199-200,296`); autentizace jen per handler, `NoopAuthenticationFunc` místo centrálního vynucení `security` z kontraktu (`validate.go:32`); registrace 409 `email_taken` detekované přes `strings.Contains("23505")` (`login.go:51-55`, `service.go:207-209`); `app.Flags` voláno před kontrolou chyby `app.Build`, SMTP credentials přes `os.Getenv` mimo Config (`main.go:75-79`, `app.go:114-122`).

**Katalog, hledání, messaging:** `VP8X` chunk délky 0 → index out of range panic z nedůvěryhodných bytů (`media/sanitize.go:198-200`); titulky ořezané bytově `[:120]` rozbijí UTF-8 → jsonb chyba, `text` návrh obchází `checkTexts` (`ai/openai.go:184-189`, `suggestions.go:369-376`); podepsané imgproxy URL nikdy neexpirují, `DeleteMedia` nechává blob a slibovaný cleanup job neexistuje, Centrifugo historie `conv` 720 h (`media/imgproxy.go:38-54`, `listing/media.go:195-230`); jakákoli chyba `Blob.Get` → `reject("upload_missing")` + smazání objektu místo retry (`media.go:112-115`); každé hledání otevírá 5+ paralelních read tx při poolu 16 (`search/query.go:243-288`); digest „nové od posledně“ používá `published_at`, které se bumpne každou schválenou verzí (`search/digest.go:42-47`); joby `MessageCreated`/`Remind` nejsou idempotentní při částečném selhání (`messaging/notifier.go:104-168`, `applications/worker.go:100-133`); report zájemce bez `message_id` má `reported_id=NULL`, blokaci může zrušit jen ten, kdo ji nastavil (`messaging/service.go` `Report`, `SetBlocked`).

**Leasing, billing, portfolio:** poslední měsíc se účtuje/ruší podle `due_day`, ne podle období (OQ-20) (`schedule.go:62-68`, `payments.go:292-309`); workflow prochází jeden termín po druhém až do D+7, `Info` bez `ErrNoRows`/`MaximumAttempts`, `Remind` neidempotentní (`workflows/lease.go:53-97`); volný text komentářů a jména stran v neměnném hash řetězci brání GDPR výmazu (`service.go:125-146,585-597`); faktura bez adresy kupujícího a vždy CZ 21 % (Q-BILL-1/2), bez fallbacku na zjednodušený doklad ≤ 10 k Kč (`billing/service.go:454-467`, `invoice.go:25-33`); `deposit_coverage` vynucuje ≥ 0,5 i bez sjednané kauce, overdue počítá dnešní splatnost od půlnoci (`portfolio/risk.go:172-176`, `portfolio.sql:136`); `ListingID` v `Create` se nekontroluje proti `orgID` (`service.go:282-293`); prázdné `ExternalID` z GoCardless koliduje na `(connection_id, '')` (`bank.go:262-265`); ledger účet `deposit_held` je účet pronajímatele, název svádí k mylnému výkladu ADR 0002 (`00007:134`).

**Databáze a kontrakt:** `00010` povoluje `owner` v pozvánkách, kontrakt ne, `org.Service.Invite` bez allowlistu (`service.go:265`); chybějící CHECKy (`invoices gross = net + vat`, `lease_risk_history.score/band`, měny `^[A-Z]{3}$`, suma `share_bps`, `moderation_cases.decision` vs `kind`); `SearchUsers` ILIKE bez escapování `%`/`_`, `MunicipalityInText` regex z dat bez escapování; `NextListingVersion` max+1, `CreateMedia` position, `PromotionEndOf`+`CreatePromotion` bez zámku řádku → unique violation / překryv promo; `SetListingStatus`, `SetListingAttributes`, `SetListingTexts`, `UpdateMediaMeta`, `SlotsWithAvailability`, `ListSlotBookings`, `GetListingContext` ignorují `deleted_at`; `LeaseParty.email` všem stranám, `Member.email` i viewerům, `AuditEvent.diff: additionalProperties` (`openapi.yaml:4493`); `PushDeviceInput.p256dh/auth`, `MfaRequest.code` bez `maxLength`, `LeaseInput.clauses` bez `maxItems`; `invitations_open_per_email` ignoruje `expires_at`; destruktivní Down migrace `00008`, `00010`, `00011` (DSA případy), `00007/00009` CASCADE – po launchi forward-only.

**Web a Astro:** `robots.txt` povoluje vše, `/hledat?…` bez canonical/noindex, přepínač jazyka ztrácí query; service worker otevírá push `link` bez kontroly originu (`service-worker.ts:23`); *(WIP)* špatný TOTP kód smaže QR (`qr: ''`), `revoke` polyká chyby (`settings/security/+page.server.ts:24-28,50-53`); stránky lokalit bez inzerátů indexovatelné, Astro web bez CSP (`localities.ts:70-133`, Caddyfile site blok); `handleSecurityHeaders` nepřidá hlavičky na redirecty z `handleAuth` (`hooks.server.ts:105`, jen dev).

**Mobil:** `allowBackup` default true bez `dataExtractionRules`; `urlOpener.open` u platebního odkazu bez kontroly schématu (`leases_screen.dart:175`); chyba dashboardu portfolia → „prázdné portfolio“; pátá záložka „Profil“ otevírá interní health stránku s názvy checků; pole nájmu přijímá libovolný text, `int.tryParse` selhání tiše zruší filtr; `_Bubble` bez semantics; debug reporter tiskne těla odpovědí, Sentry bez `beforeSend`.

**Infra:** duplicitní a konfliktní hlavičky Caddy vs API (dvě HSTS hodnoty, různé `Referrer-Policy`, `Permissions-Policy`) (`Caddyfile:11-22` vs `httpx/security.go:34-41`); `wireguard_peer_cidrs` default `0.0.0.0/0`, `PermitRootLogin prohibit-password`, `deploy` NOPASSWD + docker (`variables.tf:37-41`, cloud-init); žádný `.dockerignore` → lokální `make images` zabalí `node_modules`, `.svelte-kit`, `infra/dev/data`, `apps/web/.env*` (`apps/web/Dockerfile:10-11`); typst tarball bez sha256 (`services/api/Dockerfile:17-20`); `ScrapeTargetDown` vylučuje `job="postgres"`, žádné `pg_*` alerty (`platform.yml:12`); Caddy access logy s IP, UA a query (tokeny) do Loki na 30 dní (`Caddyfile:27`, `loki.yml:23`); offline `make dev` platí až po prvním pullu a mapa tahá tiles z OpenFreeMap (`env.ts:12`); staging NAS bez security headers, `caddy:2`, DB jako superuser, SQLite Temporal (`infra/nas/*`).

---

## 5. Rozpracované M8b (`/code-review` nad diffem)

| # | kde | nález | oprava |
| --- | --- | --- | --- |
| W-1 | `config/config.go:296` | `SESSION_MAX_AGE` default 720 h tiše ořeže `SESSION_TTL_MOBILE` (2160 h) přes `account.Service.TTL`; dokumentovaná 90denní mobilní session neexistuje. | Default stropu `max(SessionTTLWeb, SessionTTLMobile)` nebo odmítnout/zalogovat nesoulad v `Load`. |
| W-2 | `auth/middleware.go:43`, `queries/sessions.sql:13` | Absolutní limit se vynucuje jen hodnotou zapsanou v `TouchSession` (`greatest(expires_at, $2)`); sessions z doby před nasazením se nikdy nezkrátí, `GetSessionByToken` nekontroluje `created_at + maxAge`. ASVS V3.3.2 tvrzení v docs neplatí až 90 dní. | `AND created_at > now() - $maxAge` v lookupu (nebo `least()` v `TouchSession`). |
| W-3 | `cmd/api/main.go:67`, `cmd/worker/main.go:61` | `MIGRATE_ON_START` migruje přes pool na `cfg.DatabaseURL`, ne `MigrateDatabaseURL`; pod `terra_api` spadne (`goose_db_version` revoked, DDL zakázané). | Migrační pool na `MigrateDatabaseURL`, nebo odmítnout `MIGRATE_ON_START`, když se URL liší. |
| W-4 | `account/login.go:297,344` | `ResetPassword`/`ChangePassword` volají HIBP (až 2 s) **před** ověřením tokenu / současného hesla → neautentizovaný reset je zesilovač odchozích požadavků; ukradená session testuje hesla proti HIBP bez znalosti současného. | Nejdřív ověřit token (SELECT bez konzumace) / současné heslo, pak `checkBreached` mimo tx. |
| W-5 | `applications/apply.go:448`, `leasing/push.go` | Push se posílají inline v HTTP požadavku po commitu, sekvenčně per příjemce a zařízení s FCM voláním; e-maily pro tytéž události jdou přes Outbox. `Decide(accept)` s 30 žadateli = desítky sekund před 204; restart mezi commitem a smyčkou pushe ztratí. | Push job (Outbox/River) ve stejné tx jako e-mail. |
| W-6 | `integration/harness_test.go:250` | Integrační harness připojuje API jako vlastník schématu; nové granty/policies `terra_service` cvičí jen `service_role_test.go`, ne reálné request cesty. Nová RLS tabulka bez `system_all` projde `make test` a spadne až v produkci. | `newEnv` otevírá pool přes servisní login (env toggle nebo vždy). |
| W-7 | `config/config.go:313`, `app/app.go:268`, `login.go:99` | Validace klíčů duplikovaná (hardcoded 32 místo `secretbox.MinSecretLen`), nedosažitelný fallback `pwned.Local()`, „12“ v hlášce vedle konstanty `minPasswordLen`. | Odstranit smyčku v config, formátovat hlášku z konstanty, smazat fallback. |
| W-8 | `applications/push.go:13`, `leasing/push.go` | Push helpery duplikují `notify`: `applications.pick` vs `notify.Text.Pick`, identické `warn()` a `pushTitles` mapy ve dvou balíčcích, `partyUser` pattern třikrát. | Jedna `notify.PushTitles` mapa klíčovaná jako e-mail šablony, `notify.Text` všude. |

Ověřeno v pořádku: keyring secretboxu a legacy `Open`, idempotence `Reseal`, seznam sloupců `rotate-secrets` odpovídá všem `Box.Seal` (`users.totp_secret`, `users.totp_pending_secret`, `org_revolut_accounts.api_key_enc`) s CAS updatem, HMAC lookupy recovery kódů a telefonu přes všechny klíče, logika migrace 00012 vč. vlastnictví matview a pořadí Down, všechna push volání po commitu, `NoStore` middleware, Dart push routing a testy, guardy `media-replicate` a Prometheus pravidla, regenerované kontrakty.

---

## 6. Matice RLS

Policy: **org** = `org_id IN (SELECT app_user_org_ids())`; **self** = `user_id = app_current_user()`;
**party** = org NEBO nečlenský vztah; **WC** = samostatný WITH CHECK; **RO** = UPDATE/DELETE odebrané
`terra_app`.

| tabulky | RLS | policy | poznámka |
| --- | --- | --- | --- |
| app_meta, jurisdictions, filter_schemas, filter_schema_groups, filter_schema_proposals, ruian_places, ruian_staging, admin_units, listing_search | ne (globální) | – | `terra_app` má INSERT/UPDATE/DELETE (V-3); `listing_search` nese `org_id` |
| promo_products | ne | – | zápis odebraný ✓ |
| stripe_events, invoice_counters, feature_flags, attribute_suggestions, sessions, auth_tokens, user_recovery_codes, oauth_identities | ne | – | ALL odebrané `terra_app` ✓ |
| users | ne | – | jen sloupcový SELECT grant ✓ (bez telefonu, credentials) |
| listing_aggregates (MV) | n/a | – | vlastník `terra_service` *(WIP)* |
| organizations | ✓ | `id IN org_ids` ALL | |
| memberships | ✓ | org ALL | S-F6 |
| invitations | ✓ | org ALL | |
| audit_events | ✓ | org OR actor ALL | není append-only (V-4) |
| consents, gdpr_requests | ✓ | self ALL | není append-only (V-4) |
| identity_verifications | ✓ | self ALL | uživatel může zapisovat (V-4) |
| addresses, properties, units, listings, media, ai_suggestions | ✓ | org ALL | |
| listing_versions | ✓ | org, RO | withdraw přes SECDEF fn ✓ |
| saved_searches, notifications, notification_preferences, push_devices, tenant_passports | ✓ | self ALL | |
| conversations | ✓ | party (seeker OR org) ALL | |
| messages | ✓ | party + WC sender=self, RO | ✓ |
| message_attachments | ✓ | party ALL | `uploaded_by` nevázané (S-F5) |
| conversation_reads | ✓ | party + WC self | ✓ |
| reply_templates | ✓ | org ALL | |
| moderation_cases | ✓ | reporter=self, RO | anonymní/listing případy jen systémově ✓ |
| tenant_groups | ✓ | člen skupiny OR creator | pozvaný podle neověřeného e-mailu (B-2) |
| group_members | ✓ | člen/pozvaný + WC | B-2 |
| group_messages | ✓ | člen + WC, RO | ✓ |
| applications | ✓ | applicant OR org OR group ALL | S-F5 |
| application_consents | ✓ | strana žádosti ALL | S-F5 |
| roommate_profiles | ✓ | SELECT any-active; write self + WC | ✓ |
| viewing_slots | ✓ | SELECT org OR applicant; write org + WC | ✓ |
| viewing_bookings | ✓ | strana žádosti ALL | S-F5 |
| leases | ✓ | org OR party, WC org | ✓ |
| lease_parties, lease_documents, signatures, payment_obligations, obligation_splits | ✓ | org OR lease party ALL | bez WC (S-F5) |
| lease_events, ledger_entries | ✓ | org OR lease party, RO | ✓ (WIP S-L4 to ruší pro `terra_service`) |
| bank_connections, bank_transactions | ✓ | org ALL | |
| portfolio_groups, portfolio_group_items, portfolio_rules, risk_settings, lease_risk_history, portfolio_summaries | ✓ | org ALL | history není append-only (V-4) |
| lease_risk | ✓ | org OR party, WC org | API filtruje faktory pro nájemce ✓ |
| orders, invoices, promotions, org_revolut_accounts | ✓ | org ALL | orders/invoices mutable (V-4) |
| payment_links | ✓ | org OR party, WC org | ✓ |
| *(WIP 00012)* každá RLS tabulka | + `system_all TO terra_service` | | nové RLS tabulky ji musí přidat (S-F10c) |

---

## 7. Silné stránky

- **ADR 0002 bez výjimky.** Stripe jen pro vlastní promo poplatky, Revolut objednávky pod klíčem
  pronajímatele v jeho účtu, banka jen AIS čtení, QR/SPAYD jen generuje pokyny. Web i mobil to říkají
  výslovně.
- **ADR 0003 vynucené strukturálně.** Schválení, rozhodnutí o návrhu, moderace a DSA rozhodnutí jsou jediní
  zapisovatelé publikovaného/sankčního stavu, každé auditované spolu s AI návrhem, který následovalo.
  LLM dostává jen ohraničené vstupy, výstupy validované schématem.
- **ADR 0004 implementované, jak je napsané.** Jeden idiom policy, `app_user_*` SECURITY DEFINER s pinnutým
  `search_path`, `AsUser` = `SET LOCAL ROLE` + transakční `set_config`, aplikační role nikdy nevlastní
  tabulky, credential tabulky odebrané, `users` jen sloupcově. Append-only na úrovni grantů u
  `lease_events`, `ledger_entries`, `messages`, `listing_versions`, `group_messages`, `moderation_cases`.
- **Kontraktová disciplína.** 198 operací = 198 strict handlerů (compile-time), RFC 7807 všude, runtime
  kin-openapi validace, CI regeneruje Go/TS/Dart a padá na diffu, SQL CHECK enumy odpovídají OpenAPI enumům.
- **Sessions a credentials.** 256bitové opaque tokeny hashované, `TouchSession` write-limitovaný v SQL,
  impersonace fixní TTL bez staff práv a auditovaná; argon2id s OWASP parametry, konstantní porovnání,
  timing equaliser, RFC 6238 TOTP s testovacími vektory a single-use kroky, per-user HMAC recovery kódy.
- **Billing a leasing jádro.** Stripe webhook s raw-body HMAC a 5min tolerancí, `stripe_events` dedup
  vložený první, `MarkOrderPaidBySession … AND status='pending'`, `Idempotency-Key`; bezmezerové číslování
  faktur upsertem v platící transakci, DPH per řádek s half-up; peníze bigint minor units všude, dělení
  nájmu celočíselné se zbytkem první straně, každé zaúčtování kontrolované na bilanci; hash řetězec
  kanonický JSON s row lockem a verifikací při čtení; start Temporal workflow enqueue v podpisové tx.
- **Pipeline fotek.** Magic-byte detekce nezávislá na deklarovaném typu, EXIF/XMP/IPTC/PNG text/WebP metadata
  stripnutá bez re-encode, orientace zachovaná, decompression-bomb guard, originály privátní za HMAC
  imgproxy URL, ClamAV INSTREAM s deadliny.
- **Web.** Session jen v HttpOnly cookie, veškeré I/O proxované serverem, X-Forwarded-For předávané API,
  nonce CSP s testy, vlastní testovaný Markdown subset pro právní texty, magic link nekonzumovaný GETem,
  Sentry s PII scrubbingem a budgetem událostí.
- **Mobil.** Konzistentní vrstvení repository → provider → screen, všechno overridovatelné v testech, SPD
  string ze serveru jen renderovaný, Revolut až po tapu (test to dokazuje), push routing čistá allow-listed
  funkce s testy, 160 klíčů cs/en bez hardcoded řetězců, Sentry `sendDefaultPii=false`.
- **Infra.** Žádná tajemství v gitu, DB VM bez veřejných portů, SSH CIDR, Temporal UI/Grafana/Prometheus na
  127.0.0.1, imgproxy jen přes Caddy, distroless non-root image, `images` jen na main s tokenem,
  `restore-test.sh` je skutečný PITR drill s produkční konfigurací, SLO pravidla (burn rate 14,4×/6×/3×/1×,
  p95 search 300 ms) odpovídají metrikám v kódu, smoke test striktně read-only s explicitními cíli.

---

## 8. Pokrytí testy

**Co je pokryté:** auth primitiva, httpx, rate limiter, secretbox, pwned, health, realtime token; integrace
registrace→MFA→org→pozvánka, RLS izolace, BankID/social mock, magic link, telefon, impersonace, GDPR;
katalog, privacy blur, vision kontrakt, search index + výkon, chat pravidla, messaging, digest, žádosti,
roommate matching, DSA reporty; chain/IBAN/SPAYD/schedule, Typst šablony, webhook signatura, DPH, Stripe
double-click, adaptéry proti httptest, risk model (10 testů), workflow eskalace; `TestLeaseAcceptance`
celý tok, promo checkout + faktura, Revolut, portfolio. E2E (Playwright, jen CS): registrace → ověření →
TOTP → org → pozvánka, BankID, Google, redirecty, byt + pokoj + schválení, drill-down + chat hledání,
realtime chat + report → moderace, skupinová žádost tří lidí, společný podpis + QR + párování, portfolio +
riziko, promo kartou + faktura + badge, Revolut, impersonace, metriky, flagy, DSA anonymní report, právní
stránky cs/en, cookie lišta. Smoke read-only proti produkci. Flutter 13 souborů: hledání, mapa, detail →
chat → vlákno, prohlídka → žádost, 401 → login, inbox, sloty, přesun prohlídky, podpis + QR + historie,
Revolut create/reuse/409/403, portfolio, status, push routing.

**Co chybí a mapuje se na nálezy:**
- žádné testy souběhu (V-2, V-7, S-D9, S-L5), žádný negativní/fuzz test `media.Sanitize` a search builderu
  (N, S-D3), redakční failure path (V-6), smazání slotu s rezervacemi (S-D4), ISIR jen mock (S-D7),
  idempotence jobů (N), neověřený účet vs claim (B-1, B-2), autorizační matice ručitel/podnájemce/investor
  na notice/settlement/risk (V-1), měnový mismatch a chybějící SS (S-L1, S-L2), webhook replay / `async_payment_*`
  / order mismatch (S-B1, S-B2), CSV injection (S-P2), `terra_service` nesmí UPDATE `lease_events` (S-L4);
- žádné unit testy v `account`, `org`, `flags`, `audit`, `search`, `messaging`, `listing`; TOTP
  enable/disable + recovery login, `CompleteMFA` vyčerpání pokusů, `ChangePassword` step-up, pozvánky edge
  cases, `staff()` s `StaffRequireMFA`, absolutní limit session end-to-end, reálný `identity.OIDC`;
- web: forgot/reset/change hesla, resend verification, revoke session, MFA disable/recovery (vše WIP
  stránky), magic-link login, lifecycle inzerátu (pause/rented/archive/duplicate), AI návrh → lidské
  rozhodnutí, tenant passport + ISIR, uložená hledání, web push, GDPR export, notice/settlement, backoffice
  *reject*, anglické vykreslení jakéhokoli toku, realtime reconnect, komponentové testy, axe;
- mobil: `LoginScreen`/`signIn` (úspěch, špatné heslo, `mfa_required`), error/offline/401 stavy všech
  seznamů, stránkování hledání (odhalilo by V-13), cold-start push, reálná `MapLibreListingMap`, selhání
  podpisu, EN locale, text scale, on-device integrace;
- integrační harness běží pod vlastníkem schématu, ne pod `terra_service` (W-6).

---

## 9. Nesoulad dokumentace s kódem

- ADR 0012 §4 „LLM alerty ztlumené 07–13 h“: žádná LLM pravidla ani `time_intervals`; `launch.md:84` a
  `incident.md:52-53` to opakují.
- `launch.md:83` jmenuje alert `WorkerDown`; pravidlo je `WorkerHeartbeatMissing`.
- `launch.md:104-107` říká, že api/worker běží jako superuser `terra` (WIP to mění); `launch.md:94-100`
  nechává ASVS todo 1, 2, 4, 7 nezaškrtnuté, `asvs-l2.md:164-173` je škrtá (oba WIP).
- `PLAN.md:11,106` větev `m8-launch`; „Kde pokračovat 3“ uvádí DB roli, hesla 12, breached passwords,
  rotaci klíčů a repliku médií jako doporučené, všechno je ve WIP; počty 15/70 jsou staré.
- `backup.md:92-93` odkazuje na Grafana panel `media_replica_objects`; `terra-overview.json` ho nemá.
- ADR 0004 §7 „auth, jobs a backoffice běží jako owner role“ je překonané ADR 0012 §5 bez poznámky;
  ADR 0004 §1 „mobil 90 dní sliding“ teď ořezává `SESSION_MAX_AGE=720h`.
- `asvs-l2.md:3` odkazuje na větev `m8-launch`; řádky 9.1/14.4.5 „HSTS webu k ověření“, Caddyfile ho
  nastavuje.
- `launch.md:20` „terraform fmt/validate offline“: `validate` potřebuje `init`, jak říká
  `infra/hetzner/README.md:37`.
- `prometheus/targets/postgres.yml:1` tvrdí, že postgres_exporter je v cloud-initu DB VM; je v
  `docker-compose.db.yml`.
- Komentář v `listing/service.go:366` „Editing withdraws a pending review“ neodpovídá kódu (S-D2);
  `listing/media.go` slibuje cleanup job, který neexistuje.
- Ověřené ASVS „done“ řádky, které platí: 2.1.1, 2.1.7, 8.1, 14.4.3/HSTS API, 10.2, 7.1.

---

## 10. Návrh plánu oprav

**M8b (před mergem, na stávající větvi):** W-1 až W-8; S-L4 a S-F10 (opravy migrace 00012); V-17
(Go 1.26.9 + moduly, odblokuje PR #9); B-3, B-4, B-5 (compose: CSP proměnné, `BODY_SIZE_LIMIT`, Caddy
health check); V-9, V-11 (jednořádkové); aktualizace docs ze sekce 9.

**M8c – hardening před pilotem (nový milník, ~2 týdny):**
- autorizace: B-1, B-2, V-1, V-2, V-3, V-4, S-F5, S-F6, S-A3, S-F11;
- souběhy a guardy: V-5, V-6, V-7, V-8, S-D1, S-D2, S-D3, S-D4, S-D5, S-D6, S-D9, S-L1, S-L2, S-L3, S-L5,
  S-B1, S-B2, S-P1, S-P2;
- auth hygiena: S-A1, S-A2, S-A4, S-A5, S-A6, S-A7;
- provoz: V-16 (oddělené `.env` a klíče záloh), S-I4, S-I5, S-I6, S-I7, S-I8, S-I9, S-I10, S-I11, S-I12,
  S-I13;
- web: V-10, V-12, S-W1 až S-W7; škálování: S-F7/F8, S-F9;
- testy: souběhy, neověřený claim, autorizační matice, fuzz sanitize, harness pod `terra_service`.

**M8d – mobil před TestFlightem:** B-6, B-7, V-12 (mobilní část), V-13, V-14, V-15, S-M1 až S-M4, testy
loginu, chyb a stránkování.

**Backlog (N):** sekce 4, prioritně per-route idempotence jobů, expirace imgproxy URL a cleanup blobů, CHECK
constrainty, `.dockerignore`, SHA pin akcí, Postgres alerty.

Produktová a právní rozhodnutí, která z review vyplývají: verze a sign-off právních textů (V-10),
podpisová metoda a její označení (V-12), výpověď pronajímatele s důvodem (V-1), retence dokladů o příjmu
(V-8), ISIR relevance (S-D7), daňový doklad do odpovědi na Q-BILL-1/2, retence access logů (N).
