package listing

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"path"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/media"
	"github.com/terrareality/terrareality/services/api/internal/org"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	"github.com/terrareality/terrareality/services/api/internal/storage"
)

const uploadTTL = 15 * time.Minute

var allowedTypes = map[string]bool{"image/jpeg": true, "image/png": true, "image/webp": true}

// Upload is a slot for a direct upload to object storage.
type Upload struct {
	Media     db.Medium
	UploadURL string
	ExpiresAt time.Time
}

// CreateUpload reserves a photo and returns a presigned PUT URL.
func (s *Service) CreateUpload(ctx context.Context, p *auth.Principal, orgID, listingID uuid.UUID, filename, contentType string, size int64) (Upload, error) {
	if !allowedTypes[contentType] {
		return Upload{}, apperr.Unprocessable("unsupported_format", "upload JPEG, PNG or WebP photos")
	}
	if size <= 0 || size > media.MaxBytes {
		return Upload{}, apperr.Unprocessable("file_too_large", "photos may have at most 20 MB")
	}
	var up Upload
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermCatalogWrite); err != nil {
			return err
		}
		if _, err := q.GetListing(ctx, db.GetListingParams{ID: listingID, OrgID: orgID}); err != nil {
			return errListingNotFound
		}
		// Serializes concurrent uploads (CreateMedia computes the position).
		if _, err := q.LockListing(ctx, listingID); err != nil {
			return err
		}
		id := uuid.Must(uuid.NewV7())
		key := fmt.Sprintf("orgs/%s/media/%s/original", orgID, id)
		name := path.Base(strings.ReplaceAll(filename, "\\", "/"))
		if len(name) > 200 {
			name = name[len(name)-200:]
		}
		m, err := q.CreateMedia(ctx, db.CreateMediaParams{ID: id, OrgID: orgID, ListingID: &listingID, Kind: "photo",
			ObjectKey: key, Filename: name, ContentType: contentType, SizeBytes: &size, CreatedBy: &p.UserID})
		if err != nil {
			return err
		}
		u, err := s.Blob.PresignPut(ctx, key, uploadTTL)
		if err != nil {
			return err
		}
		up = Upload{Media: m, UploadURL: u, ExpiresAt: time.Now().Add(uploadTTL)}
		return nil
	})
	return up, err
}

// CompleteUpload queues processing after the client finished the PUT.
func (s *Service) CompleteUpload(ctx context.Context, p *auth.Principal, orgID, mediaID uuid.UUID) (db.Medium, error) {
	var m db.Medium
	err := s.asUser(ctx, p, func(q *db.Queries, tx pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermCatalogWrite); err != nil {
			return err
		}
		var err error
		m, err = q.GetMedia(ctx, db.GetMediaParams{ID: mediaID, OrgID: orgID})
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("media_not_found", "photo not found")
		}
		if err != nil {
			return err
		}
		if m.Status != "uploading" {
			return nil
		}
		if err := q.SetMediaStatus(ctx, db.SetMediaStatusParams{ID: m.ID, Status: "processing"}); err != nil {
			return err
		}
		m.Status = "processing"
		return s.Jobs.ProcessMedia(ctx, tx, m.ID)
	})
	return m, err
}

// ProcessMedia sanitizes, scans and analyzes an uploaded photo (worker job).
func (s *Service) ProcessMedia(ctx context.Context, mediaID uuid.UUID) error {
	q := db.New(s.Pool)
	m, err := q.SystemGetMedia(ctx, mediaID)
	if err != nil {
		return err
	}
	if m.Status != "processing" {
		return nil
	}
	reject := func(reason string) error {
		_ = s.Blob.Delete(ctx, m.ObjectKey)
		return q.SetMediaStatus(ctx, db.SetMediaStatusParams{ID: m.ID, Status: "rejected", RejectionReason: &reason})
	}
	raw, err := s.Blob.GetLimited(ctx, m.ObjectKey, media.MaxBytes)
	switch {
	case errors.Is(err, storage.ErrNotFound):
		return reject("upload_missing")
	case errors.Is(err, storage.ErrTooLarge):
		return reject(media.ErrTooLarge.Error())
	case err != nil:
		return err // storage hiccup: retried by River, the upload stays
	}
	status, sig, err := s.Scanner.Scan(ctx, raw)
	if err != nil {
		return err // retried by River
	}
	if status == "infected" {
		return reject("malware_detected:" + sig)
	}
	clean, info, err := media.Sanitize(raw)
	if err != nil {
		return reject(err.Error())
	}
	if err := s.Blob.Put(ctx, m.ObjectKey, info.ContentType, clean); err != nil {
		return err
	}
	// Vision runs before the photo turns "ready", so a privacy flag exists
	// before Submit can include the photo (Submit refuses undecided flags).
	if s.Flags.vision(ctx) && s.Vision.Enabled() && m.ListingID != nil {
		// Vision failures never block the photo; the owner can still use it.
		_ = s.analyzePhoto(ctx, q, m)
	}
	w, h := int32(info.Width), int32(info.Height)
	return q.SetMediaProcessed(ctx, db.SetMediaProcessedParams{ID: m.ID, SizeBytes: &info.Size, Sha256: info.SHA256,
		Width: &w, Height: &h, Orientation: int32(info.Orientation), AvStatus: status, ContentType: info.ContentType})
}

// analyzePhoto stores tags and creates suggestions for caption and privacy blur.
func (s *Service) analyzePhoto(ctx context.Context, q *db.Queries, m db.Medium) error {
	u, err := s.Blob.PresignGet(ctx, m.ObjectKey, 10*time.Minute)
	if err != nil {
		return err
	}
	a, err := s.Vision.Analyze(ctx, u, "cs")
	if err != nil {
		return err
	}
	if err := q.SetMediaVision(ctx, db.SetMediaVisionParams{ID: m.ID, Vision: jsonb(a)}); err != nil {
		return err
	}
	if a.Caption != "" || len(a.Tags) > 0 {
		sg, err := q.CreateSuggestion(ctx, db.CreateSuggestionParams{OrgID: m.OrgID, ListingID: *m.ListingID, MediaID: &m.ID,
			Kind: "photo_tags", CreatedBy: m.CreatedBy})
		if err != nil {
			return err
		}
		if err := q.CompleteSuggestion(ctx, db.CompleteSuggestionParams{ID: sg.ID, Model: &a.Model,
			Payload: jsonb(map[string]any{"room_type": a.RoomType, "tags": a.Tags, "caption": a.Caption})}); err != nil {
			return err
		}
	}
	if a.NeedsPrivacyReview {
		sg, err := q.CreateSuggestion(ctx, db.CreateSuggestionParams{OrgID: m.OrgID, ListingID: *m.ListingID, MediaID: &m.ID,
			Kind: "privacy_blur", CreatedBy: m.CreatedBy})
		if err != nil {
			return err
		}
		return q.CompleteSuggestion(ctx, db.CompleteSuggestionParams{ID: sg.ID, Model: &a.Model,
			Payload: jsonb(map[string]any{"regions": a.Regions, "tags": a.Tags})})
	}
	return nil
}

// UpdateMedia changes order and caption.
func (s *Service) UpdateMedia(ctx context.Context, p *auth.Principal, orgID, mediaID uuid.UUID, position int32, caption I18n) (db.Medium, error) {
	var m db.Medium
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermCatalogWrite); err != nil {
			return err
		}
		var err error
		m, err = q.UpdateMediaMeta(ctx, db.UpdateMediaMetaParams{ID: mediaID, OrgID: orgID, Position: position, Caption: jsonb(caption)})
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("media_not_found", "photo not found")
		}
		return err
	})
	return m, err
}

// DeleteMedia removes a photo from the listing. The stored object is deleted
// right away unless the listing has a published version, which may still
// show it until the next approved version (CleanupMediaBlobs).
func (s *Service) DeleteMedia(ctx context.Context, p *auth.Principal, orgID, mediaID uuid.UUID) error {
	var key string
	keep := false
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermCatalogWrite); err != nil {
			return err
		}
		m, err := q.GetMedia(ctx, db.GetMediaParams{ID: mediaID, OrgID: orgID})
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("media_not_found", "photo not found")
		}
		if err != nil {
			return err
		}
		if m.ListingID != nil {
			if l, err := q.GetListing(ctx, db.GetListingParams{ID: *m.ListingID, OrgID: orgID}); err == nil && l.PublishedVersion != nil {
				keep = true
			}
		}
		key, err = q.DeleteMedia(ctx, db.DeleteMediaParams{ID: mediaID, OrgID: orgID})
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("media_not_found", "photo not found")
		}
		if err != nil {
			return err
		}
		// The key lets CleanupMediaBlobs find objects kept for a published
		// version once no version shows them any more.
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "media", EntityID: &mediaID, Action: "media.deleted",
			Diff: map[string]any{"object_key": key, "kept": keep}})
	})
	if err == nil && !keep {
		_ = s.Blob.Delete(ctx, key)
	}
	return err
}

// Orphan cleanup window: deletions older than the grace period and newer
// than the window are checked on every run (S3 deletes are idempotent).
const (
	orphanGrace  = time.Hour
	orphanWindow = 180 * 24 * time.Hour
)

// CleanupMediaBlobs deletes stored photos that were removed from a working
// copy while a published version still showed them, once neither the
// published nor a pending version references them (periodic worker job).
// It returns how many objects were deleted.
func (s *Service) CleanupMediaBlobs(ctx context.Context) (int, error) {
	q := db.New(s.Pool)
	now := time.Now()
	keys, err := q.ListOrphanMediaKeys(ctx, db.ListOrphanMediaKeysParams{Since: now.Add(-orphanWindow),
		Until: now.Add(-orphanGrace), MaxRows: 1000})
	if err != nil {
		return 0, err
	}
	n := 0
	for _, k := range keys {
		if !strings.HasPrefix(k, "orgs/") {
			continue
		}
		if err := s.Blob.Delete(ctx, k); err != nil && !errors.Is(err, storage.ErrNotFound) {
			return n, err
		}
		n++
	}
	return n, nil
}

// PhotoURLs returns signed imgproxy URLs of a photo (empty when not ready).
func (s *Service) PhotoURLs(key string, orientation int32) map[string]string {
	if s.Img == nil || key == "" {
		return map[string]string{}
	}
	return s.Img.URLs(key, int(orientation))
}

// Vision returns the stored analysis of a photo.
func Vision(m db.Medium) map[string]any {
	var v map[string]any
	_ = json.Unmarshal(m.Vision, &v)
	return v
}
