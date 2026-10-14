-- +goose Up
-- M4: conversations between a seeker and the organization behind a listing,
-- messages with attachments and read receipts, owner reply templates and
-- pre-screening questions, reports and automatic flags for moderation, and
-- notifications (in-app, push devices, per-user preferences).

-- Pre-screening questions the owner asks before the first message:
-- [{"id": "q1", "text": {"cs": "...", "en": "..."}, "kind": "text|yes_no|number", "required": true}]
ALTER TABLE listings ADD COLUMN prescreen jsonb NOT NULL DEFAULT '[]'::jsonb
  CHECK (jsonb_typeof(prescreen) = 'array');

-- A staff sanction: the user cannot send messages (moderation decision).
ALTER TABLE users ADD COLUMN messaging_suspended_at timestamptz;

-- ---------------------------------------------------------------------------
-- One conversation per (listing, seeker). The owner side is the organization:
-- every member with the messages permission sees it.
CREATE TABLE conversations (
  id                uuid PRIMARY KEY DEFAULT uuid_v7(),
  org_id            uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  listing_id        uuid NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  seeker_id         uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  prescreen_answers jsonb NOT NULL DEFAULT '[]'::jsonb,
  blocked_by        uuid REFERENCES users(id) ON DELETE SET NULL,
  blocked_at        timestamptz,
  last_message_at   timestamptz NOT NULL DEFAULT now(),
  created_at        timestamptz NOT NULL DEFAULT now(),
  UNIQUE (listing_id, seeker_id)
);
CREATE INDEX conversations_org ON conversations (org_id, last_message_at DESC);
CREATE INDEX conversations_seeker ON conversations (seeker_id, last_message_at DESC);

CREATE TABLE messages (
  id              uuid PRIMARY KEY DEFAULT uuid_v7(),
  conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id       uuid REFERENCES users(id) ON DELETE SET NULL,
  kind            text NOT NULL DEFAULT 'text' CHECK (kind IN ('text', 'prescreen', 'system')),
  body            text NOT NULL CHECK (length(body) <= 4000),
  -- Warnings shown next to the message (contact details, advance payment).
  flags           text[] NOT NULL DEFAULT '{}',
  removed_at      timestamptz,             -- moderation: body hidden from both sides
  created_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX messages_conversation ON messages (conversation_id, created_at);

CREATE TABLE message_attachments (
  id              uuid PRIMARY KEY DEFAULT uuid_v7(),
  conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  message_id      uuid REFERENCES messages(id) ON DELETE CASCADE, -- null until sent
  uploaded_by     uuid REFERENCES users(id) ON DELETE SET NULL,
  object_key      text NOT NULL UNIQUE,
  filename        text NOT NULL,
  content_type    text NOT NULL,
  size_bytes      bigint NOT NULL CHECK (size_bytes > 0),
  av_status       text NOT NULL DEFAULT 'pending' CHECK (av_status IN ('pending', 'clean', 'infected', 'skipped')),
  created_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX message_attachments_message ON message_attachments (message_id);

-- Read receipts: how far each participant has read.
CREATE TABLE conversation_reads (
  conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id         uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  last_read_at    timestamptz NOT NULL,
  PRIMARY KEY (conversation_id, user_id)
);

CREATE TABLE reply_templates (
  id         uuid PRIMARY KEY DEFAULT uuid_v7(),
  org_id     uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  title      text NOT NULL CHECK (length(title) BETWEEN 1 AND 80),
  body       text NOT NULL CHECK (length(body) BETWEEN 1 AND 4000),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX reply_templates_org ON reply_templates (org_id, title);
CREATE TRIGGER reply_templates_updated_at BEFORE UPDATE ON reply_templates
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------------
-- Moderation queue: user reports and automatic flags. The AI verdict is a
-- suggestion; staff decide (ADR 0003).
CREATE TABLE moderation_cases (
  id              uuid PRIMARY KEY DEFAULT uuid_v7(),
  source          text NOT NULL CHECK (source IN ('report', 'auto')),
  conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  message_id      uuid REFERENCES messages(id) ON DELETE CASCADE,
  reporter_id     uuid REFERENCES users(id) ON DELETE SET NULL,
  reported_id     uuid REFERENCES users(id) ON DELETE SET NULL,
  reason          text NOT NULL CHECK (reason IN ('scam', 'advance_payment', 'harassment', 'discrimination',
                                                  'spam', 'contact_sharing', 'other')),
  note            text CHECK (length(note) <= 2000),
  status          text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'resolved')),
  ai_status       text NOT NULL DEFAULT 'pending' CHECK (ai_status IN ('pending', 'ready', 'failed', 'disabled')),
  ai_suggestion   jsonb,                   -- {"verdict": "...", "reason": "...", "confidence": 0.8}
  ai_model        text,
  decision        text CHECK (decision IN ('dismiss', 'warn', 'remove_message', 'suspend_user')),
  decision_note   text,
  decided_by      uuid REFERENCES users(id) ON DELETE SET NULL,
  decided_at      timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX moderation_cases_open ON moderation_cases (created_at) WHERE status = 'open';
-- One open automatic flag per message and reason.
CREATE UNIQUE INDEX moderation_cases_auto ON moderation_cases (message_id, reason) WHERE source = 'auto';

-- ---------------------------------------------------------------------------
-- Notifications.
CREATE TABLE notifications (
  id         uuid PRIMARY KEY DEFAULT uuid_v7(),
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind       text NOT NULL,                -- message | moderation | ...
  data       jsonb NOT NULL DEFAULT '{}'::jsonb,
  link       text NOT NULL DEFAULT '',
  read_at    timestamptz,
  emailed_at timestamptz,                  -- included in an e-mail (instant or digest)
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX notifications_user ON notifications (user_id, created_at DESC);
CREATE INDEX notifications_digest ON notifications (created_at) WHERE read_at IS NULL AND emailed_at IS NULL;

CREATE TABLE notification_preferences (
  user_id        uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  email_messages text NOT NULL DEFAULT 'instant' CHECK (email_messages IN ('instant', 'daily', 'off')),
  push_messages  boolean NOT NULL DEFAULT true,
  updated_at     timestamptz NOT NULL DEFAULT now()
);
CREATE TRIGGER notification_preferences_updated_at BEFORE UPDATE ON notification_preferences
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE push_devices (
  id           uuid PRIMARY KEY DEFAULT uuid_v7(),
  user_id      uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  platform     text NOT NULL CHECK (platform IN ('fcm', 'apns', 'webpush')),
  token        text NOT NULL,              -- FCM/APNs token or web push endpoint URL
  keys         jsonb,                      -- web push p256dh/auth
  label        text NOT NULL DEFAULT '',
  created_at   timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (platform, token)
);
CREATE INDEX push_devices_user ON push_devices (user_id);

-- ---------------------------------------------------------------------------
-- Row-level security. Conversations belong to an organization and to a seeker
-- who is not a member, so the policy extends the org rule with the seeker
-- (ADR 0007).
-- +goose StatementBegin
CREATE FUNCTION app_user_conversation_ids() RETURNS SETOF uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT c.id FROM conversations c
  WHERE c.seeker_id = app_current_user() OR c.org_id IN (SELECT app_user_org_ids())
$$;
-- +goose StatementEnd

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
CREATE POLICY conversations_party ON conversations
  USING (seeker_id = app_current_user() OR org_id IN (SELECT app_user_org_ids()));

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY messages_party ON messages
  USING (conversation_id IN (SELECT app_user_conversation_ids()))
  WITH CHECK (conversation_id IN (SELECT app_user_conversation_ids()) AND sender_id = app_current_user());
-- Messages are immutable for users; moderation runs in system context.
REVOKE UPDATE, DELETE ON messages FROM terra_app;

ALTER TABLE message_attachments ENABLE ROW LEVEL SECURITY;
CREATE POLICY message_attachments_party ON message_attachments
  USING (conversation_id IN (SELECT app_user_conversation_ids()));

ALTER TABLE conversation_reads ENABLE ROW LEVEL SECURITY;
CREATE POLICY conversation_reads_party ON conversation_reads
  USING (conversation_id IN (SELECT app_user_conversation_ids()))
  WITH CHECK (user_id = app_current_user());

ALTER TABLE reply_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY reply_templates_member ON reply_templates USING (org_id IN (SELECT app_user_org_ids()));

ALTER TABLE moderation_cases ENABLE ROW LEVEL SECURITY;
CREATE POLICY moderation_cases_reporter ON moderation_cases USING (reporter_id = app_current_user());
REVOKE UPDATE, DELETE ON moderation_cases FROM terra_app;

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY notifications_self ON notifications USING (user_id = app_current_user());

ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY notification_preferences_self ON notification_preferences USING (user_id = app_current_user());

ALTER TABLE push_devices ENABLE ROW LEVEL SECURITY;
CREATE POLICY push_devices_self ON push_devices USING (user_id = app_current_user());

-- +goose StatementBegin
-- Seekers see the name of the organization they talk to (organizations has
-- member-only RLS).
CREATE FUNCTION org_display_name(p_org uuid) RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT name FROM organizations WHERE id = p_org
$$;
-- +goose StatementEnd

-- +goose StatementBegin
-- Automatic flags are created while the sender's transaction runs with RLS;
-- the function checks the message is the caller's own.
CREATE FUNCTION flag_message(p_message uuid, p_reason text, p_note text) RETURNS uuid
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  INSERT INTO moderation_cases (source, conversation_id, message_id, reported_id, reason, note)
  SELECT 'auto', m.conversation_id, m.id, m.sender_id, p_reason, p_note
  FROM messages m WHERE m.id = p_message AND m.sender_id = app_current_user()
  ON CONFLICT (message_id, reason) WHERE source = 'auto' DO NOTHING
  RETURNING id
$$;
-- +goose StatementEnd

-- +goose Down
DROP FUNCTION IF EXISTS flag_message(uuid, text, text);
DROP FUNCTION IF EXISTS org_display_name(uuid);
DROP TABLE IF EXISTS push_devices, notification_preferences, notifications, moderation_cases, reply_templates,
  conversation_reads, message_attachments, messages, conversations CASCADE;
DROP FUNCTION IF EXISTS app_user_conversation_ids();
ALTER TABLE users DROP COLUMN IF EXISTS messaging_suspended_at;
ALTER TABLE listings DROP COLUMN IF EXISTS prescreen;
