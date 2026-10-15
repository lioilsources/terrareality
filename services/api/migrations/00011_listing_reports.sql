-- +goose Up
-- DSA notice-and-action (Regulation (EU) 2022/2065, art. 16 and 17): anyone,
-- signed in or not, can report a published listing. A report is a moderation
-- case of kind 'listing' in the existing staff queue. Staff decide (keep,
-- unpublish, request_change; ADR 0003) and the reporter receives an
-- acknowledgement and a statement of reasons by e-mail. No AI verdict runs on
-- listing cases (ai_status 'disabled').
ALTER TABLE moderation_cases
  ADD COLUMN kind text NOT NULL DEFAULT 'conversation' CHECK (kind IN ('conversation', 'listing')),
  ADD COLUMN listing_id uuid REFERENCES listings(id) ON DELETE CASCADE,
  -- Anonymous reporters (no account): contact for the DSA e-mails.
  ADD COLUMN reporter_contact_email citext CHECK (length(reporter_contact_email) <= 254),
  ADD COLUMN reporter_contact_name text CHECK (length(reporter_contact_name) <= 200),
  ADD COLUMN reporter_locale text NOT NULL DEFAULT 'cs' CHECK (reporter_locale IN ('cs', 'en')),
  ALTER COLUMN conversation_id DROP NOT NULL;

ALTER TABLE moderation_cases DROP CONSTRAINT moderation_cases_reason_check;
ALTER TABLE moderation_cases ADD CONSTRAINT moderation_cases_reason_check
  CHECK (reason IN ('scam', 'advance_payment', 'harassment', 'discrimination', 'spam', 'contact_sharing', 'other',
                    'illegal_content', 'fraud', 'wrong_info'));
ALTER TABLE moderation_cases DROP CONSTRAINT moderation_cases_decision_check;
ALTER TABLE moderation_cases ADD CONSTRAINT moderation_cases_decision_check
  CHECK (decision IN ('dismiss', 'warn', 'remove_message', 'suspend_user', 'keep', 'unpublish', 'request_change'));
ALTER TABLE moderation_cases ADD CONSTRAINT moderation_cases_subject
  CHECK ((kind = 'conversation' AND conversation_id IS NOT NULL)
      OR (kind = 'listing' AND listing_id IS NOT NULL AND conversation_id IS NULL));

CREATE INDEX moderation_cases_listing ON moderation_cases (listing_id) WHERE listing_id IS NOT NULL;

-- +goose Down
DELETE FROM moderation_cases WHERE kind = 'listing';
DROP INDEX IF EXISTS moderation_cases_listing;
ALTER TABLE moderation_cases DROP CONSTRAINT moderation_cases_subject;
ALTER TABLE moderation_cases DROP CONSTRAINT moderation_cases_decision_check;
ALTER TABLE moderation_cases ADD CONSTRAINT moderation_cases_decision_check
  CHECK (decision IN ('dismiss', 'warn', 'remove_message', 'suspend_user'));
ALTER TABLE moderation_cases DROP CONSTRAINT moderation_cases_reason_check;
ALTER TABLE moderation_cases ADD CONSTRAINT moderation_cases_reason_check
  CHECK (reason IN ('scam', 'advance_payment', 'harassment', 'discrimination', 'spam', 'contact_sharing', 'other'));
ALTER TABLE moderation_cases
  ALTER COLUMN conversation_id SET NOT NULL,
  DROP COLUMN reporter_locale,
  DROP COLUMN reporter_contact_name,
  DROP COLUMN reporter_contact_email,
  DROP COLUMN listing_id,
  DROP COLUMN kind;
