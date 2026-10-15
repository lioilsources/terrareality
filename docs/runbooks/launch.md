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
      (`infra/hetzner/terraform`, `terraform fmt`/`validate` offline) — my · repo
- [x] Compose prod (app + db), Caddy s automatickým TLS a bezpečnostními hlavičkami
      (`infra/hetzner/compose`) — my · repo
- [x] CI pushuje image `ghcr.io/<owner>/terra/{api,web,vision}:<sha>` + `latest` při push do `main`,
      pokud je nastaven secret `REGISTRY_TOKEN` (job `images`) — my · repo
- [ ] Hetzner Cloud projekt, API token, S3 klíče Object Storage, bucket pro Terraform state
      (`deploy.md` §1.1 kroky 1–2) — zákazník · venku
- [ ] `terraform.tfvars` + `backend.hcl` vyplněné (admin CIDR, SSH klíče, egress IP Sparku) — my + zákazník · venku
- [ ] `terraform init -backend-config=backend.hcl` → `terraform plan -out tf.plan` → review dvěma lidmi →
      `terraform apply tf.plan`; uložit `terraform output` — my · venku
- [ ] Secret `REGISTRY_TOKEN` (a případně `vars.IMAGE_REGISTRY`, `vars.REGISTRY_USER`) v GitHubu,
      read-only token pro `docker login` na app VM — zákazník · venku
- [ ] DNS (TTL 300 na launch týden): A/AAAA `terrareality.cz`, `www`, `app`, `api`, `img` → app VM;
      CAA `letsencrypt.org` (+ `zerossl.com`) — zákazník · venku
- [ ] TLS: Caddy získal certifikáty pro všechny hosty, `curl -I http://…` přesměruje na https,
      SSL Labs ≥ A — my · venku
- [ ] DB VM a app VM nasazené podle `deploy.md` §1.2–1.3, one-shoty `Exited (0)` — my · venku
- [ ] Snapshot obou VM před launchem (`hcloud server create-image --type snapshot`) — my · venku

## 2. Secrets

- [x] Všechny proměnné jen jako placeholdery v `infra/hetzner/compose/.env.example` a
      `infra/hetzner/observability/observability.env.example`; žádná tajemství v gitu — my · repo
- [ ] `.env` na obou VM (`chmod 600`): `APP_SECRET_KEY`, klíč secretboxu, DB hesla, Centrifugo,
      imgproxy klíč/sůl, Stripe (live klíče + webhook secret), SMTP, FCM (`/etc/terrareality/secrets/fcm.json`),
      Sentry DSN, Alertmanager SMTP heslo — my + zákazník · venku
- [ ] `PGBACKREST_CIPHER_PASS` v password manageru **a** v offline obálce u zákazníka (`backup.md`) — zákazník · venku
- [ ] Dev defaulty v `config.go` přepsané (Stripe, bank, Revolut, mock IdP vypnutý; API při startu v prod
      odmítne dev hodnoty) — my · venku
- [ ] Runbook rotace klíčů (ASVS V6.4, launch todo 3) — my · repo (čeká)

## 3. Zálohy

- [x] pgBackRest: stanza `terra`, plná záloha v neděli, diferenciální po–so, WAL archiving `archive_timeout=60`
      (RPO ≤ 1 h), AES-256, repo na Object Storage; systemd timery (`infra/hetzner/db`) — my · repo
- [x] Jediný zapisovač metrik `scripts/backup-metrics.sh` (stanza `terra`), názvy metrik sedí na alerty
      `terra-backup` v `infra/hetzner/observability/prometheus/rules/platform.yml` — my · repo
- [x] Restore test lokálně: `make restore-test` (záloha + PITR v dočasných kontejnerech) — my · repo
- [ ] První plná záloha v produkci (`scripts/backup-run.sh full`) a `scripts/backup-check.sh` vše `ok` — my · venku
- [ ] **Restore test na produkci po první záloze**: `restore.md` scénář C (restore vedle produkce),
      ověřit počty řádků a čas obnovy (RTO ≤ 4 h); zapsat datum a výsledek sem — my · venku
- [ ] Hetzner automatické zálohy serverů zapnuté (`backups = true`) a jeden snapshot obnoven na zkoušku — my · venku

## 4. Observabilita

- [x] Grafana + Prometheus + Loki + Tempo + Alloy + Alertmanager, dashboard `TerraReality`,
      alerty SLO (dostupnost 99,9 %, p95 search ≤ 300 ms), healthz včetně workeru, zálohy, disk
      (`infra/hetzner/observability`, `promtool check`) — my · repo
- [x] Sentry hooky ve webu a Flutteru (prázdné DSN = vypnuto) — my · repo
- [ ] `observability.env` a SMTP heslo Alertmanageru na app VM; Grafana admin heslo změněno — my · venku
- [ ] Dashboardy ukazují data: targety `up`, metriky api/worker, logy v Loki, trace v Tempo — my · venku
- [ ] **Test alertů**: testovací alert přes Alertmanager
      (`docker compose exec alertmanager amtool alert add smoke_test severity=page --alertmanager.url=http://localhost:9093`)
      dorazí e-mailem; zastavit `worker` na 3 min → `WorkerDown`/healthz alert vystřelí a zmizí — my · venku
- [ ] Ticho LLM alertů 07:00–13:00 (Alertmanager time interval, `incident.md`) ověřené — my · venku
- [ ] Uptime probe hosty v `prometheus/targets/{uptime,healthz}.yml` odpovídají finálnímu DNS — my · venku
- [ ] Sentry projekt (EU region nebo self-host, viz DPA) a DSN do `.env` — zákazník · venku
- [ ] Kontakty a on-call v `incident.md` vyplněné — zákazník · venku

## 5. Bezpečnost

- [x] OWASP ASVS L2 checklist (`docs/security/asvs-l2.md`), rate limiting, CSP (web + API), HSTS,
      dependency scan v CI (govulncheck, npm audit, pip-audit, osv-scanner) — my · repo
- [ ] ASVS launch todos z `docs/security/asvs-l2.md`:
  - [ ] 1. minimální délka hesla 12 (V2.1.1; kontrakt → `make gen`) — my · repo
  - [ ] 2. kontrola uniklých hesel při registraci/resetu (V2.1.7) — my · repo
  - [ ] 3. runbook rotace klíčů a tajemství (V6.4) — my · repo
  - [ ] 4. `Cache-Control: no-store` na autentizovaných odpovědích API (V8.1) — my · repo
  - [ ] 5. HSTS a TLS na proxy pro web a site potvrzené na produkci (V9.1, V14.4.5; smoke test to kontroluje) — my · venku
  - [ ] 6. `CLAMAV_ADDR` v produkci, kontrola magic bytes u příloh (V12.2, V12.4.2) — my · repo + venku
  - [ ] 7. absolutní životnost session, step-up pro změnu e-mailu/hesla (V3.3, V3.7) — my · repo
  - [ ] 8. retence a ochrana logů proti změně (V7.3) — my · venku
  - [ ] 9. Q-AI-1 zodpovězená před zapnutím `ai.cloud_fallback` (V8.3) — zákazník · venku
  - [ ] 10. externí penetrační test a oprava nálezů — zákazník (objednává) + my (opravy) · venku
- [ ] **Vyhrazená DB role pro aplikaci bez superuser práv** (ADR 0012 §5): api/worker se dnes připojují
      jako `terra` (superuser, vlastník schématu); RLS platí díky `db.AsUser` (`SET LOCAL ROLE terra_app`),
      ale kód mimo `AsUser` RLS obchází. Pro produkci: login role `terra_api` (NOSUPERUSER, NOBYPASSRLS),
      migrace dál pod vlastníkem schématu — my · repo + venku
- [ ] SSH jen z `admin_cidrs`, fail2ban aktivní, DB VM bez veřejných portů (ověřit `nmap` zvenku) — my · venku

## 6. Právní

- [x] Návrhy podmínek, zásad ochrany osobních údajů, cookies a DSA kontaktního místa
      (`packages/attributes/legal`), stránky na webu s označením „návrh“, cookie lišta — my · repo
- [ ] Právník zkontroloval všechny texty a doplnil údaje provozovatele (Q-LEGAL-1); odstranit
      označení „návrh“ — zákazník · venku
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
      Blokující pro launch: Q-LEGAL-1…4, Q-GDPR-1…6, Q-CZ-1…4, Q-LEASE-1…3, Q-RISK-1, Q-APP-1…3,
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
      právní stránky), `/healthz` vč. workeru, bezpečnostní hlavičky, žádné chyby v konzoli — my · repo
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
