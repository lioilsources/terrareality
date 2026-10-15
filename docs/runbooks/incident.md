# Runbook: incidents (production)

## Contacts (fill in before launch)

| Role | Name | Phone | Other |
|---|---|---|---|
| Incident lead / on-call (primary) | `<name>` | `<+420 ...>` | `<signal/e-mail>` |
| On-call (secondary) | `<name>` | `<...>` | |
| Owner (decisions: data loss, user notice, legal) | `<name>` | `<...>` | |
| AiStack operator (DGX Spark, LLM gateway) | `<name>` | `<...>` | Director session |
| DPO / GDPR contact | `<name>` | | `<dpo@...>` |
| Hetzner support | | | console → Support, status: status.hetzner.com |
| Stripe support | | | dashboard → Help; status.stripe.com |
| Revolut Business support | | | merchant dashboard |
| Lawyer | `<name>` | | |

Channels: incident chat `<#incidents>`, status page / in-app banner `<url>`.

## Severity

| Sev | Definition | Examples | Response | Update cadence |
|---|---|---|---|---|
| SEV1 | Platform down or data at risk for everyone; security breach | site/api 5xx > 5 min, DB lost, leaked secrets, personal data exposed | page primary + secondary + owner immediately, 24/7 | every 30 min |
| SEV2 | Core flow broken for many users, no workaround | login, search, messaging, applications, Stripe promo payments, e-mail delivery | primary within 30 min (07:00–23:00), else next morning | every 2 h |
| SEV3 | Degraded, workaround exists | AI suggestions delayed, image variants slow, one integration (ISIR, GoCardless) down | next working day | daily |
| SEV4 | Cosmetic / single user | | backlog | |

SLOs (observability): availability 99.9 % per 30 days, search p95 ≤ 300 ms.

## Generic procedure

1. **Acknowledge** the alert, open a thread in the incident channel: what, since when, sev, lead.
2. **Stabilise** before diagnosing: roll back the last deploy if it correlates (`deploy.md` §3),
   switch a misbehaving feature off with `FEATURE_FLAGS` / the backoffice flags, scale back batch jobs.
3. **Diagnose**: Grafana `TerraReality` dashboard (`ssh -L 3001:localhost:3001 deploy@app`), Loki
   logs `{service="api"} |= "error"`, Tempo traces, `app ps`, `curl https://api.../healthz`,
   on the DB VM `docker exec terra-db psql -U terra -d terra -c "select * from pg_stat_activity"`.
4. **Communicate**: in-app banner / status page for SEV1–2; no guesses about causes publicly.
5. **Close**: verify SLO metrics back to normal; post-mortem within 5 working days for SEV1–2
   (timeline, root cause, what we change), blameless.

Personal data involved (exposure, loss, unauthorised access)? → owner + DPO immediately; the GDPR
72 h notification clock (Art. 33) starts when we become aware. Write down the time.

## Known recurring situations

### LLM window 07:00–13:00 (expected, not an incident)

The DGX Spark gives the GPU to ComfyUI 07:00–13:00 (Europe/Prague) every day; all LLM routes fail
(`infra/spark/README.md`). AI suggestions (attribute extraction, listing texts, vision tagging) are
River jobs with retries spanning ~7 h, so they complete after 13:00; the UI shows "generating".
**Do not page anyone** for LLM errors in this
window; alerts on LLM errors must be silenced 07:00–13:00 (Alertmanager time interval).

Outside the window:
- `curl http://10.66.0.2:8080/v1/models` from the app VM. Fails → `wg show` (handshake older than
  2–3 min = tunnel down). Tunnel up but gateway down → contact the AiStack operator; we never
  restart anything on the Spark ourselves.
- If the cloud LLM fallback (`ai.cloud_fallback` flag, Claude via gateway) is approved and
  configured, the owner may enable it for the duration; otherwise jobs simply wait (SEV3).
- Never re-run AI jobs in bulk without announcing a batch to the operator (13:10–06:55 only).
Every AI output stays a suggestion that a human approves (ADR 0003), so delays never block users.

### Stripe webhooks failed / missed (promo payments, invoices)

Symptoms: paid promo not activated, invoice missing, Stripe dashboard → Developers → Webhooks shows
failed deliveries, api logs `webhook` errors.

1. Check the endpoint: `https://api.terrareality.cz/v1/webhooks/stripe` (Caddy passes it 1:1).
   Signature errors → `STRIPE_WEBHOOK_SECRET` in `.env` does not match the endpoint's secret
   (rotated?). Fix, `app up -d --no-deps api`.
2. Stripe retries failed deliveries automatically for up to 3 days with backoff. After a fix,
   resend the failed ones: Dashboard → Webhooks → endpoint → failed events → **Resend**, or CLI:

        stripe events resend <evt_id> --webhook-endpoint=<we_id>
        # list recent failures:
        stripe events list --delivery-success=false --limit 100

   Event handling is idempotent (`stripe_events` table keyed by event id, one transaction per
   event), replays are safe. Handled types: `checkout.session.completed`, `checkout.session.expired`.
3. Older than the retry window or after a PITR restore (`restore.md`): list events since the
   restore target (`stripe events list --created[gte]=<unix ts>`) and resend each to the endpoint.
   Compare paid Checkout sessions in Stripe with promo orders in the backoffice.
4. Never activate promo or mark invoices paid by hand in the DB without the Stripe event; the
   platform does not hold or move money (ADR 0002), Stripe is the source of truth for payments.

### Revolut payment links

Links are created with the landlord's own Revolut merchant key (landlord-direct, ADR 0002). Errors
are per landlord (revoked key) → backoffice shows the account, the landlord reconnects. QR payment
remains the first option, so this is SEV3 at most.

### Database

- Connection errors from api: DB VM up? `db ps`, disk (`df -h /srv`), `pg_stat_activity`.
- Disk filling with WAL: archiving broken → `backup.md` §Troubleshooting.
- Data loss / corruption: `restore.md` (decide scenario + target time with the owner).

### TLS / Caddy

Certificates renew automatically (Let's Encrypt, ZeroSSL fallback). Failure → `app logs caddy`,
DNS still points to the app VM? port 80 open? Rate limits: wait or switch issuer.

### Secrets leaked

Rotate immediately (SEV1): the leaked secret first, then anything sharing the same storage.
`APP_SECRET_KEY` rotation invalidates sealed TOTP secrets: coordinate with the owner. Stripe/Revolut
keys rotate in their dashboards; Object Storage keys in the Hetzner console (then update `.env` on
both VMs and restart). Revoke the WireGuard peer by removing it from `wg0.conf` (`wg syncconf`).
