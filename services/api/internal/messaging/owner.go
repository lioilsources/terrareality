package messaging

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"path"
	"slices"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/org"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	"github.com/terrareality/terrareality/services/api/internal/storage"
)

// ---------------------------------------------------------------------------
// Attachments: reserve, upload with a presigned PUT, complete (scan).

// MaxAttachmentBytes limits one attachment.
const MaxAttachmentBytes = 10 << 20

var attachmentTypes = []string{"image/jpeg", "image/png", "image/webp", "image/heic", "application/pdf"}

// Upload is a reserved attachment slot.
type Upload struct {
	ID        uuid.UUID
	UploadURL string
	ExpiresAt time.Time
}

// CreateUpload reserves an attachment in a conversation.
func (s *Service) CreateUpload(ctx context.Context, p *auth.Principal, convID uuid.UUID, filename, contentType string, size int64) (Upload, error) {
	if !slices.Contains(attachmentTypes, contentType) {
		return Upload{}, apperr.Unprocessable("attachment_type", "only photos (JPEG, PNG, WebP, HEIC) and PDF files can be attached")
	}
	if size <= 0 || size > MaxAttachmentBytes {
		return Upload{}, apperr.Unprocessable("attachment_size", "attachments are limited to 10 MB")
	}
	filename = path.Base(strings.ReplaceAll(filename, "\\", "/"))
	if filename == "" || filename == "." || utf8.RuneCountInString(filename) > 200 {
		filename = "attachment"
	}
	var out Upload
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		c, _, err := access(ctx, q, p.UserID, convID)
		if err != nil {
			return err
		}
		if c.BlockedAt != nil {
			return errBlocked
		}
		key := fmt.Sprintf("conversations/%s/%s", convID, uuid.New())
		a, err := q.InsertAttachment(ctx, db.InsertAttachmentParams{ConversationID: convID, UploadedBy: &p.UserID,
			ObjectKey: key, Filename: filename, ContentType: contentType, SizeBytes: size, AvStatus: "pending"})
		if err != nil {
			return err
		}
		out.ID = a.ID
		out.ExpiresAt = time.Now().Add(15 * time.Minute)
		out.UploadURL, err = s.Blob.PresignPut(ctx, key, 15*time.Minute)
		return err
	})
	return out, err
}

// CompleteUpload checks the uploaded file (size, type, malware) so it can be
// attached to a message.
func (s *Service) CompleteUpload(ctx context.Context, p *auth.Principal, id uuid.UUID) (Attachment, error) {
	var out Attachment
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		a, err := q.GetAttachment(ctx, id)
		if errors.Is(err, pgx.ErrNoRows) || (err == nil && (a.UploadedBy == nil || *a.UploadedBy != p.UserID)) {
			return apperr.NotFound("attachment_not_found", "attachment not found")
		}
		if err != nil {
			return err
		}
		reject := func(code, msg string) error {
			_ = s.Blob.Delete(ctx, a.ObjectKey)
			_ = q.SetAttachmentStatus(ctx, db.SetAttachmentStatusParams{ID: id, AvStatus: "infected"})
			return apperr.Unprocessable(code, msg)
		}
		// Bounded read: the presigned PUT does not limit the size.
		data, err := s.Blob.GetLimited(ctx, a.ObjectKey, MaxAttachmentBytes)
		switch {
		case errors.Is(err, storage.ErrTooLarge):
			return reject("attachment_size", "attachments are limited to 10 MB")
		case errors.Is(err, storage.ErrNotFound):
			return apperr.Unprocessable("attachment_missing", "upload the file first")
		case err != nil:
			return err
		}
		if !contentMatches(a.ContentType, data) {
			return reject("attachment_type", "the file content does not match its type")
		}
		status, _, err := s.Scanner.Scan(ctx, data)
		if err != nil {
			return err
		}
		if status == "infected" {
			return reject("attachment_infected", "the file was rejected by the malware scanner")
		}
		if err := q.SetAttachmentStatus(ctx, db.SetAttachmentStatusParams{ID: id, AvStatus: status}); err != nil {
			return err
		}
		out = s.attachmentDTOs(ctx, []db.MessageAttachment{a})[0]
		return nil
	})
	return out, err
}

// heicBrands are ISO BMFF major brands of HEIF/HEIC images.
var heicBrands = []string{"heic", "heix", "hevc", "hevx", "heim", "heis", "hevm", "hevs", "mif1", "msf1"}

// isHEIC checks the ISO BMFF "ftyp" box of a HEIF/HEIC image.
func isHEIC(b []byte) bool {
	if len(b) < 12 || string(b[4:8]) != "ftyp" {
		return false
	}
	return slices.Contains(heicBrands, string(b[8:12]))
}

// contentMatches checks the bytes against the declared type. HEIC has no
// net/http signature, so its ftyp box is checked instead of trusting the
// declared type.
func contentMatches(contentType string, data []byte) bool {
	if contentType == "image/heic" {
		return isHEIC(data)
	}
	return strings.HasPrefix(http.DetectContentType(data), contentType)
}

// ---------------------------------------------------------------------------
// Reply templates.

// Templates lists an organization's reply templates.
func (s *Service) Templates(ctx context.Context, p *auth.Principal, orgID uuid.UUID) ([]db.ReplyTemplate, error) {
	var out []db.ReplyTemplate
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermMessages); err != nil {
			return err
		}
		var err error
		out, err = q.ListReplyTemplates(ctx, orgID)
		return err
	})
	return out, err
}

func validTemplate(title, body string) error {
	if t := utf8.RuneCountInString(strings.TrimSpace(title)); t < 1 || t > 80 {
		return apperr.Unprocessable("template_title", "the title must have 1 to 80 characters")
	}
	if b := utf8.RuneCountInString(strings.TrimSpace(body)); b < 1 || b > 4000 {
		return apperr.Unprocessable("template_body", "the text must have 1 to 4000 characters")
	}
	return nil
}

// SaveTemplate creates (id nil) or updates a reply template.
func (s *Service) SaveTemplate(ctx context.Context, p *auth.Principal, orgID uuid.UUID, id *uuid.UUID, title, body string) (db.ReplyTemplate, error) {
	if err := validTemplate(title, body); err != nil {
		return db.ReplyTemplate{}, err
	}
	title, body = strings.TrimSpace(title), strings.TrimSpace(body)
	var out db.ReplyTemplate
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermMessages); err != nil {
			return err
		}
		var err error
		if id == nil {
			out, err = q.CreateReplyTemplate(ctx, db.CreateReplyTemplateParams{OrgID: orgID, Title: title, Body: body})
		} else {
			out, err = q.UpdateReplyTemplate(ctx, db.UpdateReplyTemplateParams{ID: *id, OrgID: orgID, Title: title, Body: body})
			if errors.Is(err, pgx.ErrNoRows) {
				return apperr.NotFound("template_not_found", "template not found")
			}
		}
		if err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "reply_template", EntityID: &out.ID, Action: "reply_template.save"})
	})
	return out, err
}

// DeleteTemplate removes a reply template.
func (s *Service) DeleteTemplate(ctx context.Context, p *auth.Principal, orgID, id uuid.UUID) error {
	return s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermMessages); err != nil {
			return err
		}
		n, err := q.DeleteReplyTemplate(ctx, db.DeleteReplyTemplateParams{ID: id, OrgID: orgID})
		if err != nil {
			return err
		}
		if n == 0 {
			return apperr.NotFound("template_not_found", "template not found")
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "reply_template", EntityID: &id, Action: "reply_template.delete"})
	})
}

// ---------------------------------------------------------------------------
// Pre-screening questions.

var prescreenKinds = []string{"text", "yes_no", "number"}

// NormalizePrescreen validates questions and assigns ids to new ones.
func NormalizePrescreen(in []PrescreenQuestion) ([]PrescreenQuestion, error) {
	if len(in) > 10 {
		return nil, apperr.Unprocessable("prescreen_too_many", "ask at most 10 questions")
	}
	out := make([]PrescreenQuestion, 0, len(in))
	seen := map[string]bool{}
	for i, q := range in {
		cs := strings.TrimSpace(q.Text["cs"])
		en := strings.TrimSpace(q.Text["en"])
		if cs == "" && en == "" {
			return nil, apperr.Unprocessable("prescreen_text", fmt.Sprintf("question %d has no text", i+1))
		}
		if utf8.RuneCountInString(cs) > 300 || utf8.RuneCountInString(en) > 300 {
			return nil, apperr.Unprocessable("prescreen_text", "questions are limited to 300 characters")
		}
		if !slices.Contains(prescreenKinds, q.Kind) {
			return nil, apperr.Unprocessable("prescreen_kind", "unknown question kind")
		}
		if q.ID == "" || seen[q.ID] || len(q.ID) > 40 {
			q.ID = "q" + strings.ReplaceAll(uuid.NewString()[:8], "-", "")
		}
		seen[q.ID] = true
		text := map[string]string{}
		if cs != "" {
			text["cs"] = cs
		}
		if en != "" {
			text["en"] = en
		}
		out = append(out, PrescreenQuestion{ID: q.ID, Text: text, Kind: q.Kind, Required: q.Required})
	}
	return out, nil
}
