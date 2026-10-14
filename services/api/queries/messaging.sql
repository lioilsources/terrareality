-- M4: conversations, messages, moderation and notifications.

-- name: ListingForConversation :one
-- Published listing a seeker may contact (system context).
SELECT s.listing_id, s.org_id, s.title, l.prescreen
FROM listing_search s JOIN listings l ON l.id = s.listing_id
WHERE s.listing_id = $1 AND l.status = 'published' AND l.deleted_at IS NULL;

-- name: CreateConversation :one
INSERT INTO conversations (org_id, listing_id, seeker_id, prescreen_answers)
VALUES ($1, $2, $3, $4)
ON CONFLICT (listing_id, seeker_id) DO UPDATE SET last_message_at = conversations.last_message_at
RETURNING *, (xmax = 0)::boolean AS created;

-- name: SeekerBlockedByOrg :one
SELECT EXISTS (SELECT 1 FROM conversations
  WHERE seeker_id = $1 AND org_id = $2 AND blocked_at IS NOT NULL AND blocked_by <> seeker_id)::boolean;

-- name: GetConversation :one
SELECT * FROM conversations WHERE id = $1;

-- name: ListConversations :many
-- Inbox of the current user (RLS limits rows to their conversations).
SELECT c.id, c.org_id, c.listing_id, c.seeker_id, c.blocked_at, c.blocked_by, c.last_message_at, c.created_at,
  coalesce(org_display_name(c.org_id), '')::text AS org_name,
  su.display_name AS seeker_name,
  coalesce(s.title, l.title, '{}'::jsonb)::jsonb AS listing_title,
  s.cover_key, coalesce(s.cover_orientation, 1)::int AS cover_orientation,
  coalesce(lm.body, '')::text AS last_body, lm.sender_id AS last_sender_id,
  (SELECT count(*) FROM messages m
     WHERE m.conversation_id = c.id AND m.sender_id IS DISTINCT FROM sqlc.arg(user_id)::uuid
       AND m.created_at > coalesce(r.last_read_at, '-infinity'))::int AS unread
FROM conversations c
JOIN users su ON su.id = c.seeker_id
LEFT JOIN listing_search s ON s.listing_id = c.listing_id
LEFT JOIN listings l ON l.id = c.listing_id
LEFT JOIN conversation_reads r ON r.conversation_id = c.id AND r.user_id = sqlc.arg(user_id)::uuid
LEFT JOIN LATERAL (
  SELECT CASE WHEN m.removed_at IS NULL THEN m.body ELSE '' END AS body, m.sender_id
  FROM messages m WHERE m.conversation_id = c.id ORDER BY m.created_at DESC LIMIT 1) lm ON true
WHERE (sqlc.narg(org_id)::uuid IS NULL OR c.org_id = sqlc.narg(org_id)::uuid)
  AND (sqlc.narg(conversation_id)::uuid IS NULL OR c.id = sqlc.narg(conversation_id)::uuid)
  AND (NOT sqlc.arg(as_seeker)::boolean OR c.seeker_id = sqlc.arg(user_id)::uuid)
ORDER BY c.last_message_at DESC
LIMIT 200;

-- name: ListMessages :many
SELECT m.id, m.conversation_id, m.sender_id, m.kind, m.flags, m.removed_at, m.created_at,
  CASE WHEN m.removed_at IS NULL THEN m.body ELSE '' END::text AS body
FROM messages m
WHERE m.conversation_id = $1 AND m.created_at < coalesce(sqlc.narg(before)::timestamptz, 'infinity')
ORDER BY m.created_at DESC
LIMIT $2;

-- name: InsertMessage :one
INSERT INTO messages (conversation_id, sender_id, kind, body, flags)
VALUES ($1, $2, $3, $4, $5) RETURNING *;

-- name: TouchConversation :exec
UPDATE conversations SET last_message_at = $2 WHERE id = $1;

-- name: MarkRead :exec
INSERT INTO conversation_reads (conversation_id, user_id, last_read_at) VALUES ($1, $2, $3)
ON CONFLICT (conversation_id, user_id) DO UPDATE
SET last_read_at = greatest(conversation_reads.last_read_at, excluded.last_read_at);

-- name: ListReads :many
SELECT conversation_id, user_id, last_read_at FROM conversation_reads WHERE conversation_id = $1;

-- name: SetConversationBlock :exec
UPDATE conversations SET blocked_by = $2, blocked_at = CASE WHEN $2::uuid IS NULL THEN NULL ELSE now() END
WHERE id = $1;

-- name: InsertAttachment :one
INSERT INTO message_attachments (conversation_id, uploaded_by, object_key, filename, content_type, size_bytes, av_status)
VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *;

-- name: AttachToMessage :execrows
UPDATE message_attachments SET message_id = $1
WHERE id = ANY(sqlc.arg(ids)::uuid[]) AND conversation_id = $2 AND uploaded_by = $3 AND message_id IS NULL
  AND av_status IN ('clean', 'skipped');

-- name: ListAttachments :many
SELECT * FROM message_attachments WHERE message_id = ANY(sqlc.arg(message_ids)::uuid[]) ORDER BY created_at;

-- name: GetAttachment :one
SELECT * FROM message_attachments WHERE id = $1;

-- name: ListReplyTemplates :many
SELECT * FROM reply_templates WHERE org_id = $1 ORDER BY title;

-- name: CreateReplyTemplate :one
INSERT INTO reply_templates (org_id, title, body) VALUES ($1, $2, $3) RETURNING *;

-- name: UpdateReplyTemplate :one
UPDATE reply_templates SET title = $3, body = $4 WHERE id = $1 AND org_id = $2 RETURNING *;

-- name: DeleteReplyTemplate :execrows
DELETE FROM reply_templates WHERE id = $1 AND org_id = $2;

-- name: UpdateListingPrescreen :execrows
UPDATE listings SET prescreen = $3 WHERE id = $1 AND org_id = $2 AND deleted_at IS NULL;

-- name: CreateReport :one
INSERT INTO moderation_cases (source, conversation_id, message_id, reporter_id, reported_id, reason, note, ai_status)
VALUES ('report', $1, $2, $3, $4, $5, $6, $7) RETURNING id;

-- name: FlagMessage :one
-- Returns the new case id, or null when the message was already flagged.
SELECT flag_message(sqlc.arg(message_id)::uuid, sqlc.arg(reason)::text, sqlc.arg(note)::text)::uuid AS case_id;

-- ---------------------------------------------------------------------------
-- Notifications (user context).

-- name: GetNotificationPreferences :one
SELECT * FROM notification_preferences WHERE user_id = $1;

-- name: UpsertNotificationPreferences :one
INSERT INTO notification_preferences (user_id, email_messages, push_messages) VALUES ($1, $2, $3)
ON CONFLICT (user_id) DO UPDATE SET email_messages = excluded.email_messages, push_messages = excluded.push_messages
RETURNING *;

-- name: ListNotifications :many
SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50;

-- name: CountUnreadNotifications :one
SELECT count(*)::int FROM notifications WHERE user_id = $1 AND read_at IS NULL;

-- name: MarkNotificationsRead :exec
UPDATE notifications SET read_at = now()
WHERE user_id = $1 AND read_at IS NULL AND (sqlc.narg(id)::uuid IS NULL OR id = sqlc.narg(id)::uuid);

-- name: MarkConversationNotificationsRead :exec
UPDATE notifications SET read_at = now()
WHERE user_id = $1 AND read_at IS NULL AND kind = 'message' AND data->>'conversation_id' = sqlc.arg(conversation_id)::text;

-- name: UpsertPushDevice :one
INSERT INTO push_devices (user_id, platform, token, keys, label) VALUES ($1, $2, $3, $4, $5)
ON CONFLICT (platform, token) DO UPDATE SET keys = excluded.keys,
  label = excluded.label, last_seen_at = now()
RETURNING *;

-- name: ListPushDevices :many
SELECT * FROM push_devices WHERE user_id = $1 ORDER BY last_seen_at DESC;

-- name: DeletePushDevice :execrows
DELETE FROM push_devices WHERE id = $1 AND user_id = $2;

-- ---------------------------------------------------------------------------
-- System context (worker, backoffice).

-- name: SystemGetMessage :one
SELECT * FROM messages WHERE id = $1;

-- name: MessageRecipients :many
-- Everyone on the other side of a message: the seeker or the organization's
-- members who handle messages, with their read marker and preferences.
WITH c AS (SELECT * FROM conversations WHERE conversations.id = sqlc.arg(conversation_id)::uuid),
parties AS (
  SELECT c.seeker_id AS user_id FROM c
  UNION
  SELECT m.user_id FROM memberships m JOIN c ON m.org_id = c.org_id WHERE m.role IN ('owner', 'admin', 'agent')
)
SELECT u.id, u.email, u.locale, u.display_name,
  coalesce(r.last_read_at, 'epoch')::timestamptz AS last_read_at,
  coalesce(p.email_messages, 'instant')::text AS email_messages,
  coalesce(p.push_messages, true)::boolean AS push_messages
FROM parties
JOIN users u ON u.id = parties.user_id
LEFT JOIN conversation_reads r ON r.conversation_id = sqlc.arg(conversation_id)::uuid AND r.user_id = u.id
LEFT JOIN notification_preferences p ON p.user_id = u.id
WHERE u.id IS DISTINCT FROM sqlc.narg(sender_id)::uuid AND u.pseudonymized_at IS NULL;

-- name: ConversationParties :many
-- User ids that may see a conversation (realtime fan-out).
SELECT c.seeker_id AS user_id FROM conversations c WHERE c.id = $1
UNION
SELECT m.user_id FROM memberships m JOIN conversations c ON c.org_id = m.org_id
WHERE c.id = $1 AND m.role IN ('owner', 'admin', 'agent');

-- name: SystemConversationSummary :one
SELECT c.*, coalesce(o.name, '')::text AS org_name, su.display_name AS seeker_name,
  coalesce(s.title, l.title, '{}'::jsonb)::jsonb AS listing_title
FROM conversations c
JOIN users su ON su.id = c.seeker_id
LEFT JOIN organizations o ON o.id = c.org_id
LEFT JOIN listing_search s ON s.listing_id = c.listing_id
LEFT JOIN listings l ON l.id = c.listing_id
WHERE c.id = $1;

-- name: InsertNotification :one
INSERT INTO notifications (user_id, kind, data, link) VALUES ($1, $2, $3, $4) RETURNING *;

-- name: MarkNotificationEmailed :exec
UPDATE notifications SET emailed_at = now() WHERE id = ANY(sqlc.arg(ids)::uuid[]);

-- name: BumpMessageNotification :one
-- One unread notification per conversation and recipient; new messages update it.
UPDATE notifications SET created_at = now(),
  data = jsonb_set(sqlc.arg(data)::jsonb, '{count}', to_jsonb(coalesce((notifications.data->>'count')::int, 0) + 1))
WHERE id = (SELECT n.id FROM notifications n
  WHERE n.user_id = sqlc.arg(user_id) AND n.kind = 'message' AND n.read_at IS NULL
    AND n.data->>'conversation_id' = sqlc.arg(conversation_id)::text
  ORDER BY n.created_at DESC LIMIT 1)
RETURNING *;

-- name: SetAttachmentStatus :exec
UPDATE message_attachments SET av_status = $2 WHERE id = $1;

-- name: DigestRecipients :many
-- Users with unread, not yet e-mailed notifications who chose a daily digest.
SELECT DISTINCT n.user_id, u.email, u.locale, u.display_name
FROM notifications n
JOIN users u ON u.id = n.user_id
JOIN notification_preferences p ON p.user_id = n.user_id
WHERE n.read_at IS NULL AND n.emailed_at IS NULL AND p.email_messages = 'daily' AND u.pseudonymized_at IS NULL
LIMIT 1000;

-- name: DigestNotifications :many
SELECT * FROM notifications
WHERE user_id = $1 AND read_at IS NULL AND emailed_at IS NULL
ORDER BY created_at LIMIT 50;

-- name: SystemPushDevices :many
SELECT * FROM push_devices WHERE user_id = $1;

-- name: DeletePushDeviceByToken :exec
DELETE FROM push_devices WHERE platform = $1 AND token = $2;

-- name: DeletePushDeviceOfOthers :exec
DELETE FROM push_devices WHERE platform = $1 AND token = $2 AND user_id <> $3;

-- name: UserMessagingSuspended :one
SELECT (messaging_suspended_at IS NOT NULL)::boolean AS suspended FROM users WHERE id = $1;

-- name: ListOpenModerationCases :many
SELECT mc.*, ru.display_name AS reporter_name, ru.email AS reporter_email,
  du.display_name AS reported_name, du.email AS reported_email,
  coalesce(msg.body, '')::text AS message_body,
  coalesce(s.title, l.title, '{}'::jsonb)::jsonb AS listing_title
FROM moderation_cases mc
JOIN conversations c ON c.id = mc.conversation_id
LEFT JOIN users ru ON ru.id = mc.reporter_id
LEFT JOIN users du ON du.id = mc.reported_id
LEFT JOIN messages msg ON msg.id = mc.message_id
LEFT JOIN listing_search s ON s.listing_id = c.listing_id
LEFT JOIN listings l ON l.id = c.listing_id
WHERE mc.status = 'open'
ORDER BY mc.created_at;

-- name: GetModerationCase :one
SELECT mc.*, ru.display_name AS reporter_name, ru.email AS reporter_email,
  du.display_name AS reported_name, du.email AS reported_email,
  coalesce(msg.body, '')::text AS message_body,
  coalesce(s.title, l.title, '{}'::jsonb)::jsonb AS listing_title
FROM moderation_cases mc
JOIN conversations c ON c.id = mc.conversation_id
LEFT JOIN users ru ON ru.id = mc.reporter_id
LEFT JOIN users du ON du.id = mc.reported_id
LEFT JOIN messages msg ON msg.id = mc.message_id
LEFT JOIN listing_search s ON s.listing_id = c.listing_id
LEFT JOIN listings l ON l.id = c.listing_id
WHERE mc.id = $1;

-- name: ModerationTranscript :many
-- The conversation around a case, oldest first, for staff and the AI verdict.
SELECT * FROM (
  SELECT m.id, m.sender_id, m.kind, m.body, m.flags, m.removed_at, m.created_at,
    coalesce(u.display_name, '')::text AS sender_name,
    (m.sender_id = c.seeker_id)::boolean AS from_seeker
  FROM messages m
  JOIN conversations c ON c.id = m.conversation_id
  LEFT JOIN users u ON u.id = m.sender_id
  WHERE m.conversation_id = $1
  ORDER BY m.created_at DESC LIMIT 40
) t ORDER BY created_at;

-- name: PendingModerationAI :many
SELECT id FROM moderation_cases WHERE ai_status = 'pending' AND status = 'open' ORDER BY created_at LIMIT 100;

-- name: SetModerationAI :exec
UPDATE moderation_cases SET ai_status = $2, ai_suggestion = $3, ai_model = $4 WHERE id = $1;

-- name: DecideModerationCase :execrows
UPDATE moderation_cases SET status = 'resolved', decision = $2, decision_note = $3, decided_by = $4, decided_at = now()
WHERE id = $1 AND status = 'open';

-- name: RemoveMessage :exec
UPDATE messages SET removed_at = now() WHERE id = $1 AND removed_at IS NULL;

-- name: SuspendMessaging :exec
UPDATE users SET messaging_suspended_at = now() WHERE id = $1 AND messaging_suspended_at IS NULL;
