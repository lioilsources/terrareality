# ADR 0007: Messaging, notifications and moderation

Status: accepted (M4, 2026-10-14)

## Decisions

1. **One conversation per (listing, seeker).** The other party is the organization behind the
   listing: every member with the `messages.write` permission (owner, admin, agent) sees and
   answers it. Starting again on the same listing reuses the conversation.
2. **Row-level security for two parties.** `conversations` has the policy
   `seeker_id = app_current_user() OR org_id IN (SELECT app_user_org_ids())`; messages,
   attachments and read markers check `conversation_id IN (SELECT app_user_conversation_ids())`.
   This extends the org rule of ADR 0004 because the seeker is not an org member. Messages and
   moderation cases are immutable for the app role; staff actions run in system context.
3. **Mask, warn, never block.** Phone numbers, e-mails and bank accounts (IBAN and Czech
   `prefix-number/bank`) are replaced by `[•••]` before storing and the message gets a flag; the
   sender sees why. Requests to pay before a viewing, untraceable payment channels and "keys by
   courier" add the `advance_payment` flag, show a warning to the recipient and open an automatic
   moderation case. Only the masked text is stored.
4. **Realtime through Centrifugo, published after commit.** The api publishes every message to
   `conv:<id>` and to the parties' `user:<id>` channels. Clients get a connection token (HS256,
   with a server-side subscription to their user channel) and a subscription token for a
   conversation channel from the api; the web app proxies both through its server because the
   session cookie is HttpOnly. A failed publish is logged; clients reload the thread on reconnect.
5. **Notifications by a delayed job.** Each message schedules `message_notify`
   (`MESSAGE_NOTIFY_DELAY`, 20 s by default). If the recipient has read the conversation by then
   nothing happens. Otherwise an in-app notification is created or bumped (one unread notification
   per conversation). Push and e-mail go out only when the recipient has no realtime connection
   (Centrifugo presence on the user channel). E-mail is sent once per unread streak (`instant`) or
   in a daily summary at 18:00 Prague time (`daily`), or not at all (`off`).
6. **Push providers.** Mobile devices register FCM tokens (FCM HTTP v1 also reaches iOS through
   APNs). Browsers subscribe with Web Push; the api encrypts payloads per RFC 8291 and signs VAPID
   JWTs itself (the key pair is derived from `WEBPUSH_VAPID_SEED`, default `APP_SECRET_KEY`). The
   dev/test mock turns pushes into e-mails to `push+<user>@push.terra.local` in Mailpit, like SMS.
7. **Moderation queue with an AI suggestion.** User reports and automatic flags are
   `moderation_cases`. A job asks the model (`ai.Moderator`, rules in the mock) for a verdict
   (dismiss, warn, remove the message, suspend messaging) with a reason and confidence. Staff see
   the transcript and the suggestion and decide; only the decision applies sanctions (ADR 0003),
   and it is audited together with the suggestion it followed or overrode.

## Deviations from the plan

- **Push on mobile is wired but not active.** The Flutter app has the `PushRegistrar` seam and the
  api accepts FCM tokens, but Firebase needs the project's configuration files (OQ-14). Until then
  the app relies on realtime while open and on e-mail.
- **Attachments are photos and PDF only**, 10 MB each, uploaded with a presigned PUT and checked
  (content sniffing, ClamAV) before they can be sent.
