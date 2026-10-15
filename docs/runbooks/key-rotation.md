# Runbook: key and secret rotation (ASVS V6.4)

Covers every secret the platform uses to encrypt, sign or authenticate, where it lives and how to
rotate it without downtime. Rotate **immediately** on suspected compromise (leaked `.env`, laptop
lost, ex-team member with VM access), otherwise on the schedule below.

All production secrets live only in `/opt/terra/infra/hetzner/compose/.env` on the VMs (`chmod 600`,
owner `deploy`) and in the team password manager. Placeholders: `infra/hetzner/compose/.env.example`.
Generate new values with `openssl rand -hex 32` unless stated otherwise.

Shorthand on the app VM (see `deploy.md`):

    cd /opt/terra/infra/hetzner/compose
    app() { docker compose -f docker-compose.app.yml "$@"; }
    restart_backend() { app up -d --no-deps api worker; }

Record every rotation (date, secret, who, reason) in the launch log (`launch.md`, "Záznam") or
the incident record.

## Inventory

| Secret | Used for | Lives in | Rotation | Grace window |
| --- | --- | --- | --- | --- |
| `APP_SECRET_KEY` | AES-256-GCM of TOTP secrets and landlord Revolut API keys (`internal/platform/secretbox`); HMAC of recovery codes, SMS codes, mock IdP codes | `.env` (api, worker, migrate/terractl) | yearly + on compromise, §1 | `APP_SECRET_KEY_PREVIOUS` |
| `WEBPUSH_VAPID_SEED` | derives the Web Push VAPID key pair | `.env` | **do not rotate** unless compromised, §2 | none (all browsers resubscribe) |
| `CENTRIFUGO_TOKEN_SECRET` | HMAC of realtime connection/subscription tokens (TTL 1 h) | `.env` (api + centrifugo) | yearly + on compromise, §3 | none; clients reconnect |
| `CENTRIFUGO_API_KEY` | api → Centrifugo server API | `.env` (api + centrifugo) | yearly + on compromise, §3 | none; seconds |
| `IMGPROXY_KEY`, `IMGPROXY_SALT` | signed image URLs | `.env` (api + imgproxy) | on compromise, §4 | `IMGPROXY_VERIFY_KEYS/SALTS` |
| `STRIPE_WEBHOOK_SECRET` | verifies `POST /v1/webhooks/stripe` | `.env` + Stripe dashboard | yearly + on compromise, §5 | Stripe signs with both secrets up to 24 h |
| `STRIPE_SECRET_KEY` | Stripe API (platform invoices only, ADR 0002) | `.env` + Stripe dashboard | yearly + on compromise, §5 | Stripe "roll key" expiry |
| Landlord Revolut API keys | per-landlord Merchant API key (sealed in `org_revolut_accounts.api_key_enc`) | DB, sealed by `APP_SECRET_KEY` | landlord's decision, §6 | landlord reconnects |
| `GOOGLE_CLIENT_SECRET`, `APPLE_CLIENT_SECRET`, `BANKID_CLIENT_SECRET` | OIDC client auth | `.env` + provider consoles | Apple JWT every 6 months; others yearly, §7 | provider allows two secrets |
| `GOCARDLESS_SECRET_ID/KEY` | bank account data | `.env` + GoCardless portal | yearly, §7 | create new, then revoke old |
| `S3_ACCESS_KEY/SECRET_KEY` (app project) | Object Storage, media | `.env` app VM + DB VM + Hetzner console | yearly, §7 | create new, then delete old |
| `PGBACKREST_S3_KEY*`, `MEDIA_REPLICA_*_KEY` (backup project) | Object Storage, backups + media replica | `.env` **DB VM only** + Hetzner console (backup project) | yearly + immediately if the DB VM is suspected compromised, §7 | create new, then delete old |
| `POSTGRES_PASSWORD`, `TERRA_API_DB_PASSWORD`, `TEMPORAL_DB_PASSWORD` | DB login roles | `.env` (both VMs) | yearly, §8 | none; restart |
| `MONITORING_DB_PASSWORD` | postgres_exporter | `.env` DB VM only | yearly, §8 | none; restart |
| PostgreSQL server certificate / internal CA (`scripts/pg-tls-init.sh`) | TLS app VM → DB VM | `/srv/pgtls` DB VM, `pg-ca.crt` app VM, CA key in the password manager | server cert before expiry (825 days, `--renew`), CA every 10 years | new server cert under the same CA: none |
| `PGBACKREST_CIPHER_PASS` | encryption of every backup | `.env` DB VM + password manager + offline | **never in place**, §9 | n/a |
| FCM service account JSON | Firebase push | `/etc/terrareality/secrets/fcm.json` | yearly, §7 | two keys may coexist |
| SMTP password, `SENTRY_DSN`, `CLOUD_LLM_API_KEY`, Alertmanager `smtp_password` / `page_webhook_url` | outbound services | `.env` / `ALERT_SECRETS_DIR` | on compromise, §7 | provider-specific |

Not secrets that need rotation: session tokens, magic links, invitation and reset tokens are random
256-bit values stored only as SHA-256 hashes (`internal/platform/tokens`); revoke them by deleting
`sessions` / `auth_tokens` rows if needed (forces everyone to log in again).

## 1. `APP_SECRET_KEY` (secretbox keyring)

How it works: the api builds a keyring from `APP_SECRET_KEY` (current) and
`APP_SECRET_KEY_PREVIOUS` (comma-separated, newest first). New values are always sealed and signed
with the current key; values sealed or signed with a previous key are still readable and verifiable.
Every sealed value carries a 4-byte key id (`TRK\x01` header); values written before the keyring
existed (no header) are tried against every key. `terractl rotate-secrets` re-encrypts the stored
columns (`users.totp_secret`, `users.totp_pending_secret`, `org_revolut_accounts.api_key_enc`) with
the current key, in batches, idempotently.

Steps:

1. Make sure `WEBPUSH_VAPID_SEED` is set explicitly in `.env`. If it was empty, set it to the
   **current (old)** `APP_SECRET_KEY` first, otherwise every browser push subscription breaks. The
   api refuses to start with `APP_SECRET_KEY_PREVIOUS` and no explicit seed.
2. Edit `.env` on the app VM:

       APP_SECRET_KEY_PREVIOUS=<old APP_SECRET_KEY>[,<older keys still in their grace period>]
       APP_SECRET_KEY=<openssl rand -hex 32>

   Store the new key in the password manager; keep the old one there, marked "previous".
3. `restart_backend`. Check `/healthz` and the logs: logins with 2FA and Revolut payment links must
   keep working (old values are opened with the previous key).
4. Re-encrypt stored data, first as a dry run:

       app run --rm --no-deps migrate /app/terractl rotate-secrets --dry-run
       app run --rm --no-deps migrate /app/terractl rotate-secrets

   The output lists, per column, how many values were re-encrypted, already current and
   unreadable. "unreadable" must be 0; otherwise a key that sealed those values is missing from
   the ring: find it before removing anything. The command is safe to re-run (it skips values
   already sealed with the current key) and to run while the api serves traffic.
5. Grace period: keep `APP_SECRET_KEY_PREVIOUS` for **30 days**. HMAC values cannot be
   re-computed (we never store the plaintext), and they are verified against all keys while the old
   key is in the ring:
   - SMS phone codes, mock IdP codes: expire in minutes, nothing to do.
   - **MFA recovery codes** issued before the rotation are HMACs under the old key. After the old
     key is removed they stop working. Before removing it, list affected users and ask them to
     disable and re-enable 2FA (this issues new codes):

         SELECT DISTINCT u.email FROM user_recovery_codes c JOIN users u ON u.id = c.user_id
         WHERE c.used_at IS NULL AND c.created_at < '<rotation timestamp>';

     After a **compromise**, shorten the grace period to what support can handle and treat old
     recovery codes as exposed (an attacker with the key and a DB dump can brute-force them).
6. End of grace: run `rotate-secrets --dry-run` once more (must report 0 to re-encrypt and 0
   unreadable), then empty `APP_SECRET_KEY_PREVIOUS` and `restart_backend`.

Restoring an old backup (`restore.md`) brings back values sealed with older keys: put those keys
back into `APP_SECRET_KEY_PREVIOUS` and run `rotate-secrets` after the restore. Therefore keep
retired keys in the password manager for as long as backups exist (pgBackRest retention).

## 2. `WEBPUSH_VAPID_SEED`

The VAPID public key is baked into every browser push subscription. A new seed means every existing web push
subscription is rejected by the push services, and users get web push again only after they
revisit the web app and resubscribe. Rotate only on compromise: set a new value, `restart_backend`.
The Flutter app uses FCM and is not affected.

## 3. Centrifugo secrets

Centrifugo accepts one HMAC token key, so there is no overlap window; connection tokens live 1 h
and clients fetch a new one from the api when they reconnect.

1. Set new `CENTRIFUGO_TOKEN_SECRET` (and/or `CENTRIFUGO_API_KEY`) in `.env`.
2. `app up -d --no-deps centrifugo api worker` (both sides together). Open websocket
   connections drop and reconnect with a fresh token; messages are not lost (they are in the DB,
   realtime is only a notification channel).

## 4. imgproxy key and salt

Signed image URLs end up in caches and rendered pages; keep the old pair accepted for a while.

1. In `.env`: `IMGPROXY_VERIFY_KEYS=<new key>,<old key>`, `IMGPROXY_VERIFY_SALTS=<new salt>,<old salt>`
   (same order), then `IMGPROXY_KEY=<new key>`, `IMGPROXY_SALT=<new salt>`.
2. `app up -d --no-deps imgproxy api worker web`.
3. After 7 days (and after purging any CDN cache), empty `IMGPROXY_VERIFY_KEYS/SALTS`,
   `app up -d --no-deps imgproxy`.

## 5. Stripe

Webhook signing secret (`STRIPE_WEBHOOK_SECRET`):

1. Stripe Dashboard → Developers → Webhooks → endpoint `https://api.terrareality.cz/v1/webhooks/stripe`
   → "Roll secret", choose an expiry of the old secret (up to 24 h; "now" only on compromise).
2. During the expiry window Stripe sends a `v1=` signature for each active secret; the api accepts
   an event when any `v1` matches (`billing.VerifyWebhook`), so deploy whenever ready: put the new
   `whsec_...` into `.env`, `restart_backend`.
3. Check Dashboard → webhook attempts: no failures after the switch. Failed events are retried by
   Stripe for 3 days; replay them from the dashboard if the window was missed.

API key (`STRIPE_SECRET_KEY`): Dashboard → Developers → API keys → "Roll key" with an expiry
(e.g. 1 h), put the new `sk_live_...` into `.env`, `restart_backend`, verify an invoice job.
Use a restricted key if possible.

## 6. Revolut

The platform has no Revolut credentials of its own: each landlord's Merchant API key is stored
sealed (step §1 re-encrypts it) and only used to create payment links (ADR 0002). A landlord who
rotates the key in Revolut Business (Merchant API settings) reconnects it in the app
(Billing → Revolut), which replaces the sealed value. On a platform-side compromise of
`APP_SECRET_KEY`, ask every connected landlord to regenerate their Merchant API key:

    SELECT o.name, u.email FROM org_revolut_accounts a JOIN organizations o ON o.id = a.org_id
    LEFT JOIN users u ON u.id = a.connected_by;

We do not receive Revolut webhooks today. If they are added, Revolut rotates a webhook signing
secret through the Merchant API (`POST /webhooks/{id}/rotate-signing-secret` with an
`expiration_period` for the old one); verification must then accept both secrets until it expires.

## 7. Third-party credentials (OIDC, GoCardless, S3, FCM, SMTP, LLM)

Pattern: create the new credential in the provider console while the old one stays valid, put it
into `.env`, restart the consumers, verify, then revoke the old credential.

- Google: Cloud console → Credentials → OAuth client → "Add secret", then disable the old one.
- Apple: the client secret is a JWT signed with the Sign in with Apple key, valid at most
  6 months; regenerate before `exp`. Revoke the key in the Apple developer portal on compromise.
- BankID: client secret in the BankID developer portal.
- GoCardless: new secret id/key pair in the Bank Account Data portal, then delete the old one.
- Hetzner Object Storage: new access key in the right project (Security → S3 credentials). Media
  keys (app project) go to api, worker and imgproxy (`app up -d --no-deps api worker imgproxy`) and to
  the DB VM `.env` (replication source). Backup project keys (pgBackRest, replica) go only to the DB
  VM `.env` (`db up -d`, then `pgbackrest check`; the replica timer reads `.env` on its next run).
- FCM: new service account key in Firebase, replace `/etc/terrareality/secrets/fcm.json`,
  `restart_backend`, delete the old key.

## 8. Database passwords

`ALTER ROLE ... PASSWORD` as the owner on the DB VM, update `.env` on both VMs (monitoring: DB VM only), restart the
consumers (`terra_api`: api, worker; owner: migrate; `temporal`: temporal; monitoring: exporters).
There is no overlap; expect a few seconds of errors, schedule it.

## 9. `PGBACKREST_CIPHER_PASS`

Never change in place: existing backups stay encrypted with the old passphrase. On compromise,
create a new repository path with a new passphrase, take a full backup there, keep the old
passphrase until the old backups expire, then delete the old repository (`backup.md`).
