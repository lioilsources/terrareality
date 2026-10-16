# Launch checklist (M8)

Acceptance M8 (`docs/02-plan.md`): tento checklist splněn, produkční E2E smoke test prošel, restore ze
zálohy ověřen. Rozhodnutí za tím: `docs/ADR/0012-production-launch.md`. Postupy: `deploy.md`,
`backup.md`, `restore.md`, `incident.md`, `seed-praha.md`.

Legenda:

- `[x]` hotovo, `[ ]` čeká.
- **Vlastník**: **my** (vývojový tým), **zákazník** (provozovatel platformy, jeho právník a účty),
  **Spark** (provozovatel DGX Spark / AiStack; na Spark nikdy nesahá tento projekt).
- **Kde**: _repo_ = připraveno a ověřené v repozitáři (offline); _venku_ = musí proběhnout mimo repo
  (cloud, účty, podpisy, obchody s aplikacemi). Nic z tohoto repa se samo nenasazuje.

Checklist se odškrtává v PR / issue „Launch“ s datem a jménem; tento soubor drží stav repa.

## 1. Infra (Hetzner, DNS, TLS)

- [x] Terraform: 2 VM (app, db), privátní síť, firewally, volumes, snapshoty/zálohy serverů, buckets
      (`infra/hetzner/terraform`; `terraform fmt` offline, `terraform init -backend=false && terraform validate`
      potřebuje jen registry providerů, obojí v CI jobu `security`) — my · repo
- [x] Compose prod (app + db), Caddy s automatickým TLS a bezpečnostními hlavičkami bez duplicit,
      healthchecky a limity paměti, Caddy health check na `/v1/version`, CSP origins a `BODY_SIZE_LIMIT`
      pro web (`infra/hetzner/compose`, `deploy.md` §1.3 a §4) — my · repo
- [x] CI pushuje image `ghcr.io/<owner>/terra/{api,web,vision}:<sha>` + `latest` při push do `main`,
      pokud je nastaven secret `REGISTRY_TOKEN` (job `images`) — my · repo
- [ ] Hetzner Cloud projekt, API token, S3 klíče Object Storage, bucket pro Terraform state
      (`deploy.md` §1.1 kroky 1–2) — zákazník · venku
- [ ] **Druhý Hetzner projekt pro zálohy** (jen S3 klíče: repo pgBackRestu + replika médií); klíče jen do
      `.env` DB VM a password manageru, nikdy na app VM ani do CI (`backup.md` §Credential isolation) — zákazník · venku
- [ ] Po `terraform apply`: bucket záloh má zapnutý versioning a 2 lifecycle pravidla (konzole); jinak
      ručně a zapsat sem — my · venku
- [ ] `terraform.tfvars` + `backend.hcl` vyplněné (admin CIDR, SSH klíče, egress IP Sparku) — my + zákazník · venku
- [ ] `terraform init -backend-config=backend.hcl` → `terraform plan -out tf.plan` → review dvěma lidmi →
      `terraform apply tf.plan`; uložit `terraform output` — my · venku
- [ ] Secret `REGISTRY_TOKEN` (a případně `vars.IMAGE_REGISTRY`, `vars.REGISTRY_USER`) v GitHubu,
      read-only token pro `docker login` na app VM — zákazník · venku
- [ ] DNS (TTL 300 na launch týden): A/AAAA `terrareality.cz`, `www`, `app`, `api`, `img` → app VM;
      CAA `letsencrypt.org` (+ `zerossl.com`) — zákazník · venku
- [ ] TLS: Caddy získal certifikáty pro všechny hosty, `curl -I http://…` přesměruje na https,
      SSL Labs ≥ A — my · venku
- [ ] DB VM a app VM nasazené podle `deploy.md` §1.2–1.3, one-shoty `Exited (0)`, ostatní služby `healthy` — my · venku
- [ ] TLS k PostgreSQL: `scripts/pg-tls-init.sh` na DB VM, `pg-ca.crt` na app VM, `DB_SSLMODE=verify-full`,
      CA klíč v password manageru a smazaný z VM — my · venku
- [ ] Snapshot obou VM před launchem (`hcloud server create-image --type snapshot`) — my · venku

## 2. Secrets

- [x] Všechny proměnné jen jako placeholdery: app VM `infra/hetzner/compose/.env.example`, DB VM
      `infra/hetzner/compose/db.env.example`, `infra/hetzner/observability/observability.env.example`;
      žádná tajemství v gitu — my · repo
- [ ] `.env` zvlášť pro každou VM (`chmod 600`). App VM: `APP_SECRET_KEY`, DB hesla (bez monitoring),
      Centrifugo, imgproxy klíč/sůl, Stripe (live klíče + webhook secret), SMTP, FCM
      (`/etc/terrareality/secrets/fcm.json`), Sentry DSN, Alertmanager (`/etc/terrareality/secrets/alertmanager/`
      `smtp_password`, `page_webhook_url`). DB VM: DB hesla, klíče záložního projektu, `PGBACKREST_CIPHER_PASS`,
      klíče médií a repliky. Kontrola: `grep -c PGBACKREST /opt/terra/infra/hetzner/compose/.env` na app VM = 0 — my + zákazník · venku
- [ ] `PGBACKREST_CIPHER_PASS` v password manageru **a** v offline obálce u zákazníka (`backup.md`) — zákazník · venku
- [ ] Dev defaulty v `config.go` přepsané (Stripe, bank, Revolut, mock IdP vypnutý; API při startu v prod
      odmítne dev hodnoty) — my · venku
- [x] Runbook rotace klíčů a tajemství `docs/runbooks/key-rotation.md` (ASVS V6.4, launch todo 3): keyring
      `APP_SECRET_KEY` + `APP_SECRET_KEY_PREVIOUS`, `terractl rotate-secrets` — my · repo
- [ ] `WEBPUSH_VAPID_SEED` nastavený explicitně v produkčním `.env` (jinak rotace `APP_SECRET_KEY` zneplatní
      web push odběry, viz `key-rotation.md` §2) — my · venku

## 3. Zálohy

- [x] pgBackRest: stanza `terra`, plná záloha v neděli, diferenciální po–so, WAL archiving `archive_timeout=60`
      (RPO ≤ 1 h), AES-256, repo na Object Storage; systemd timery (`infra/hetzner/db`) — my · repo
- [x] Jediný zapisovač metrik `scripts/backup-metrics.sh` (stanza `terra`), názvy metrik sedí na alerty
      `terra-backup` v `infra/hetzner/observability/prometheus/rules/platform.yml` — my · repo
- [x] Restore test lokálně: `make restore-test` (záloha + PITR v dočasných kontejnerech) — my · repo
- [x] Druhá kopie médií: hodinový `rclone sync` bucketu `terrareality-media` do `terrareality-media-replica`
      v jiné lokalitě (výchozí nbg1), smazané/přepsané objekty 90 dní v `_replica-archive/<čas>/`, pojistky
      proti hromadnému mazání, metriky `media_replica_*` + alerty `terra-media-replica`, obnova
      `scripts/media-restore.sh` (`backup.md` §Media replica, `restore.md` scénář E) — my · repo
- [ ] Replika médií v produkci: bucket z Terraformu (v záložním Hetzner projektu s vlastními klíči,
      skript jiné klíče vynucuje), `MEDIA_REPLICA_*` v `.env` DB VM, první sync, timer `terra-media-replicate`,
      `scripts/media-restore.sh check` `ok`, zkušební obnova jednoho inzerátu do scratch bucketu — my + zákazník · venku
- [ ] První plná záloha v produkci (`scripts/backup-run.sh full`) a `scripts/backup-check.sh` vše `ok` — my · venku
- [ ] **Restore test na produkci po první záloze**: `restore.md` scénář C (restore vedle produkce),
      ověřit počty řádků a čas obnovy (RTO ≤ 4 h); zapsat datum a výsledek sem — my · venku
- [ ] Hetzner automatické zálohy serverů zapnuté (`backups = true`) a jeden snapshot obnoven na zkoušku — my · venku

## 4. Observabilita

- [x] Grafana + Prometheus + Loki + Tempo + Alloy + Alertmanager, dashboard `TerraReality`,
      alerty SLO (dostupnost 99,9 %, p95 search ≤ 300 ms), healthz včetně workeru, zálohy, disk
      (`infra/hetzner/observability`, `promtool check`) — my · repo
- [x] Sentry hooky ve webu a Flutteru (prázdné DSN = vypnuto) — my · repo
- [ ] `observability.env` a adresář `ALERT_SECRETS_DIR` (`smtp_password`, `page_webhook_url`) na app VM;
      skutečný smarthost a adresy v `alertmanager.yml`; Grafana admin heslo změněno — my · venku
- [ ] Kanál pro `severity=page` vybraný (ntfy téma / SMS brána) a URL v `page_webhook_url` — zákazník + my · venku
- [ ] Dashboardy ukazují data: targety `up`, metriky api/worker, logy v Loki, trace v Tempo — my · venku
- [ ] **Test alertů**: testovací alert přes Alertmanager
      (`docker compose exec alertmanager amtool alert add smoke_test severity=page --alertmanager.url=http://localhost:9093`)
      dorazí e-mailem i na paging kanál; zastavit `worker` na 3 min → `WorkerHeartbeatMissing`/`ApiHealthzDown`
      vystřelí a zmizí — my · venku
- [ ] Ticho LLM alertů 07:00–13:00 Europe/Prague ověřené: `LlmJobFailuresHigh` (`component="llm"`) se v okně
      neposílá (Alertmanager `time_intervals` `spark-comfyui-window`, `amtool config routes test component=llm`) — my · venku
- [ ] Uptime probe hosty v `prometheus/targets/{uptime,healthz}.yml` odpovídají finálnímu DNS — my · venku
- [ ] Sentry projekt (EU region nebo self-host, viz DPA) a DSN do `.env` — zákazník · venku
- [ ] Kontakty a on-call v `incident.md` vyplněné — zákazník · venku

## 5. Bezpečnost

- [x] OWASP ASVS L2 checklist (`docs/security/asvs-l2.md`), rate limiting, CSP (web + API), HSTS,
      dependency scan v CI (govulncheck, npm audit, pip-audit, osv-scanner) — my · repo
- [ ] ASVS launch todos z `docs/security/asvs-l2.md`:
  - [x] 1. minimální délka hesla 12 (V2.1.1; kontrakt → `make gen`) — my · repo
  - [x] 2. kontrola uniklých hesel při registraci/resetu (V2.1.7, `PWNED_PASSWORDS`) — my · repo
  - [x] 3. runbook rotace klíčů a tajemství (V6.4, `key-rotation.md`) — my · repo
  - [x] 4. `Cache-Control: no-store` na autentizovaných odpovědích API (V8.1, `httpx.NoStore`) — my · repo
  - [ ] 5. HSTS a TLS na proxy pro web a site potvrzené na produkci (V9.1, V14.4.5; v Caddyfile hotovo, smoke test to kontroluje) — my · venku
  - [ ] 6. `CLAMAV_ADDR` v produkci, kontrola magic bytes u příloh (V12.2, V12.4.2) — my · repo + venku
  - [x] 7. absolutní životnost session, step-up pro změnu e-mailu/hesla (V3.3, V3.7; `SESSION_MAX_AGE`) — my · repo
  - [ ] 8. retence a ochrana logů proti změně (V7.3): retence hotová (aplikační logy 30 dní, access logy Caddy
        14 dní bez query a s IP zkrácenou na /24); ochrana proti změně otevřená — my · venku
  - [ ] 9. Q-AI-1 zodpovězená před zapnutím `ai.cloud_fallback` (V8.3) — zákazník · venku
  - [ ] 10. externí penetrační test a oprava nálezů — zákazník (objednává) + my (opravy) · venku
- [x] **Vyhrazená DB role pro aplikaci bez superuser práv** (ADR 0012 §5): api/worker se připojují jako
      `terra_api` (NOSUPERUSER, NOBYPASSRLS, člen `terra_service`), migrace dál pod vlastníkem `terra`
      (`MIGRATE_DATABASE_URL`); staging stejně — my · repo
- [ ] `terra_api` založená v produkci (`deploy.md` §1.4), `pg_stat_activity` ukazuje `terra_api` — my · venku
- [ ] SSH jen z `admin_cidrs`, fail2ban aktivní, DB VM bez veřejných portů (ověřit `nmap` zvenku) — my · venku

## 6. Právní

- [x] Návrhy podmínek, zásad ochrany osobních údajů, cookies a DSA kontaktního místa
      (`packages/attributes/legal`), stránky na webu s označením „návrh“, cookie lišta — my · repo
- [ ] Právník zkontroloval všechny texty a doplnil údaje provozovatele (Q-LEGAL-1); odstranit
      označení „návrh“ — zákazník · venku
- [ ] Sign-off verzí právních textů zapsaný v `docs/legal-questions.md` Q-LEGAL-5 (kdo, kdy, verze,
      commit); `TERMS_VERSION`/`PRIVACY_VERSION` v `.env` = `version:` ve front matter — zákazník + my · venku
- [ ] Texty na webu odpovídají realitě (review V-12): podpis smlouvy elektronicky v aplikaci, Bank iD SIGN
      jen „připravujeme“ (OQ-19), šablony „procházejí právní revizí“, dokud `LEASE_TEMPLATES_REVIEWED=false`;
      po podpisu smlouvy s Bank iD a revizi šablon upravit `apps/site/src/i18n/strings.ts` — my · repo
- [ ] DPA podle `docs/legal/dpa-checklist.md` podepsané nebo vědomě přijaté právníkem — zákazník · venku:
  - [ ] Hetzner (hosting, Object Storage, zálohy)
  - [ ] Bank iD
  - [ ] GoCardless
  - [ ] Stripe
  - [ ] Revolut Business
  - [ ] e-mailový provider (vybrat)
  - [ ] Google (Sign in, FCM), Apple (Sign in, APNs)
  - [ ] Sentry (pokud SaaS)
  - [ ] Anthropic (jen před zapnutím `ai.cloud_fallback`)
  - [ ] vlastník DGX Spark (pokud jiný subjekt)
  - [ ] OpenFreeMap (rozhodnout: self-host dlaždic, nebo přijmout)
  - [ ] DPA šablona pro majitele (majitel = správce, my = zpracovatel)
- [ ] Záznamy o činnostech zpracování (čl. 30), DPIA pro rizikové skóre (Q-RISK-1), seznam
      subdodavatelů zveřejněn — zákazník · venku
- [ ] Otevřené otázky z `docs/legal-questions.md` uzavřené nebo vědomě odložené po launchi — zákazník · venku.
      Blokující pro launch: Q-LEGAL-1…5, Q-GDPR-1…6, Q-CZ-1…4, Q-LEASE-1…3, Q-RISK-1, Q-APP-1…3,
      Q-MSG-1…3, Q-IMP-1, Q-BILL-1…3, Q-AI-1 (jen pokud se zapíná cloud fallback). Po launchi: Q-STR-1…2.

## 7. Data (seed Praha)

- [x] Import RÚIAN pro Prahu a okolí, hranice, onboarding majitelů přes `terractl`
      (`docs/runbooks/seed-praha.md`); Astro stránky pro Prahu a okolí — my · repo
- [ ] Adresy: `terractl import-ruian --region praha` (oficiální data, `--url official`), pak hranice
      (`--boundaries`) a `terractl reindex` — my · venku
- [ ] 20 pilotních majitelů: CSV mimo repo (osobní údaje), `terractl onboard-owner --csv pilot-owners.csv --dry-run`,
      pak bez `--dry-run`; pozvánky odešly — my + zákazník · venku
- [ ] Staff účty s MFA (backoffice) — my · venku
- [ ] Statický web přegenerovaný proti produkčnímu API (stránky obcí) a nahraný do `/srv/site` — my · venku

## 8. Mobil (Flutter)

- [x] Flutter v0: hledání s mapou, chat, žádost, prohlídky, nájemní portál, push; widget testy — my · repo
- [ ] **Nativní nastavení MapLibre a Sentry neověřené na tomto Macu** (xcodebuild visí; iOS build
      a běh na zařízení zopakovat na jiném Macu / v CI s macOS) — my · venku
- [ ] Apple Developer účet, App ID `cz.terrareality.terrareality`, push certifikát/klíč APNs,
      Sign in with Apple — zákazník · venku
- [ ] TestFlight: `flutter build ipa --release` (verze z `pubspec.yaml`), upload přes Xcode/Transporter,
      interní testeři, export compliance — my · venku
- [ ] Google Play Console, upload klíč, `flutter build appbundle --release`, interní testovací track,
      data safety formulář — zákazník (účet) + my (build) · venku
- [ ] Podpis Androidu (Play App Signing): upload klíč
      `keytool -genkey -v -keystore apps/mobile/android/upload-keystore.jks -keyalg RSA -keysize 2048
      -validity 10000 -alias upload`, `apps/mobile/android/key.properties` podle `key.properties.example`
      (obojí gitignorované, záloha v trezoru hesel); bez `key.properties` release build záměrně selže.
      V Play Console zapnout Play App Signing a nahrát upload certifikát — my · venku
- [ ] App Links / Universal Links: `/.well-known/assetlinks.json` (package `cz.terrareality.terrareality`,
      SHA-256 **app signing** certifikátu z Play Console) a `/.well-known/apple-app-site-association`
      (`<TEAM_ID>.cz.terrareality.terrareality`, cesty `/zpravy`, `/zadosti`, `/smlouvy`, `/inzerat`,
      `/prohlidky` vč. podcest `/*` a přesně `/auth/magic` a `/auth/reset` — e-mailové odkazy s `?token=`;
      `/auth/callback/*` a `/auth/oidc/*` aplikace **nebere**, zůstávají na webu) na `terrareality.cz`
      i `app.terrareality.cz`. Šablony jsou v `apps/web/static/.well-known/`, vyplňuje je Caddy
      (snippet `app_links` v obou Caddyfilech) z env `APPLE_TEAM_ID` (10 znaků) a `ANDROID_CERT_SHA256`
      (SHA-256 otisky oddělené čárkou, formát `AA:BB:...`, nejdřív app signing klíč z Play Console →
      App integrity, volitelně upload klíč) v `.env` app VM; odpověď 200, `Content-Type:
      application/json`, bez přesměrování (kontrola v `deploy.md` §1.3 krok 7). Android cesty bere
      z manifestu, `assetlinks.json` žádné cesty nemá. `WEB_BASE_URL` api musí být jeden z těchto dvou
      hostů (dnes `https://app.terrareality.cz`), jinak se odkazy z e-mailů v aplikaci neotevřou.
      Ověření: Apple `https://app-site-association.cdn-apple.com/a/v1/app.terrareality.cz`, Google
      Digital Asset Links API / `adb shell pm get-app-links cz.terrareality.terrareality`.
      App ID s capability Associated Domains a Push Notifications — my (web) + zákazník (Apple účet) · venku
- [ ] Release build vždy s `--dart-define=API_URL=https://api.terrareality.cz` (bez něj aplikace při
      startu spadne, nikdy nemíří na localhost) — my · venku
- [ ] FCM projekt, `google-services.json` / `GoogleService-Info.plist` mimo git, `fcm.json` na serveru — zákazník + my · venku
- [ ] Sentry DSN pro mobil (`--dart-define`), produkční `API_URL` v buildu — my · venku

## 9. Spark (LLM)

- [x] WireGuard na straně Hetzneru připraven (`infra/hetzner/wireguard`), cloud LLM fallback za flagem
      `ai.cloud_fallback` (výchozí vypnuto) — my · repo
- [ ] Žádost o WireGuard peer odeslána provozovateli Sparku (veřejný klíč, PSK bezpečným kanálem) — my · venku
- [ ] Peer na Sparku nastaven a tunel ověřen (`/health/liveliness` z app VM) — Spark · venku
- [ ] **Do té doby AI flagy vypnuté**: `LLM_BASE_URL=` prázdné, `FEATURE_FLAGS=-ai.attributes,-ai.text,-ai.vision`
      (moderace a ostatní AI také vypnout, pokud nemají LLM) — my · venku
- [ ] `ai.cloud_fallback` zůstává vypnutý, dokud není DPA s Anthropic a odpověď na Q-AI-1 — zákazník · venku

## 10. Go-live

- [x] Produkční smoke E2E (jen čtení): `make smoke BASE_URL=https://app.terrareality.cz
      API_URL=https://api.terrareality.cz SITE_URL=https://terrareality.cz`, nebo ručně workflow `smoke`
      v GitHub Actions; kontroluje site (landing, Praha, sitemap), web (home, hledání, detail inzerátu,
      právní stránky, fotka inzerátu se načte přes imgproxy = CSP `img-src`), `/healthz` vč. workeru,
      bezpečnostní hlavičky, žádné chyby v konzoli — my · repo
- [ ] Smoke test zelený proti produkci (výsledek a sha zapsat sem) — my · venku
- [ ] Ruční průchod: registrace, přihlášení s MFA, vložení inzerátu pilotním majitelem, zpráva, žádost,
      Stripe testovací webhook 2xx (`deploy.md` §1.3 krok 7) — my + zákazník · venku
- [ ] **Plán rollbacku** odsouhlasen (`deploy.md` §3): předchozí `IMAGE_TAG` → `app up -d --no-deps api worker web vision`
      (< 2 min); migrace jen dopředu, jinak PITR těsně před migrací (`restore.md` scénář B);
      DNS zpět na stránku údržby; rozhoduje zákazník — my + zákazník · venku
- [ ] Komunikace launch dne (kdo je na příjmu, kanál, `incident.md`) — zákazník · venku
- [ ] Po 24 h: SLO dashboard, chybovost v Sentry, zálohy `ok` — my · venku

## Záznam

| Datum | Co | Kdo | Výsledek |
| ----- | -- | --- | -------- |
|       |    |     |          |
