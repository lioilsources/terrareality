package account

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
)

const exportLinkTTL = 15 * time.Minute

// GDPRRequests lists the user's requests.
func (s *Service) GDPRRequests(ctx context.Context, p *auth.Principal) ([]db.GdprRequest, error) {
	return db.New(s.Pool).ListGDPRRequests(ctx, p.UserID)
}

// RequestExport queues a data export job.
func (s *Service) RequestExport(ctx context.Context, p *auth.Principal) (db.GdprRequest, error) {
	if p.Impersonated() {
		return db.GdprRequest{}, apperr.ErrImpersonation
	}
	var r db.GdprRequest
	err := s.tx(ctx, func(q *db.Queries, tx pgx.Tx) error {
		var err error
		r, err = q.CreateGDPRRequest(ctx, db.CreateGDPRRequestParams{UserID: p.UserID, Kind: "export", ScheduledAt: time.Now()})
		if err != nil {
			return err
		}
		if err := s.Scheduler.ScheduleExport(ctx, tx, r.ID); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{Entity: "gdpr_request", EntityID: &r.ID, Action: "gdpr.export_requested"})
	})
	return r, err
}

// ExportLink returns a short-lived download URL of a finished export.
func (s *Service) ExportLink(ctx context.Context, p *auth.Principal, id uuid.UUID) (string, time.Time, error) {
	if p.Impersonated() {
		return "", time.Time{}, apperr.ErrImpersonation // the export is the user's whole data set
	}
	r, err := db.New(s.Pool).GetGDPRRequest(ctx, id)
	if errors.Is(err, pgx.ErrNoRows) || (err == nil && (r.UserID != p.UserID || r.Kind != "export")) {
		return "", time.Time{}, apperr.NotFound("export_not_found", "export not found")
	}
	if err != nil {
		return "", time.Time{}, err
	}
	if r.Status != "done" || r.ObjectKey == nil {
		return "", time.Time{}, apperr.Conflict("export_not_ready", "the export is not ready yet")
	}
	u, err := s.Blob.PresignGet(ctx, *r.ObjectKey, exportLinkTTL)
	return u, time.Now().Add(exportLinkTTL), err
}

// RequestErasure schedules erasure after the grace period (idempotent).
func (s *Service) RequestErasure(ctx context.Context, p *auth.Principal) (db.GdprRequest, error) {
	if p.Impersonated() {
		return db.GdprRequest{}, apperr.ErrImpersonation
	}
	var r db.GdprRequest
	err := s.tx(ctx, func(q *db.Queries, tx pgx.Tx) error {
		existing, err := q.GetOpenErasureRequest(ctx, p.UserID)
		if err == nil {
			r = existing
			return nil
		}
		if !errors.Is(err, pgx.ErrNoRows) {
			return err
		}
		at := time.Now().Add(s.Cfg.ErasureGrace)
		r, err = q.CreateGDPRRequest(ctx, db.CreateGDPRRequestParams{UserID: p.UserID, Kind: "erasure", ScheduledAt: at})
		if err != nil {
			return err
		}
		if err := s.Scheduler.ScheduleErasure(ctx, tx, r.ID, at); err != nil {
			return err
		}
		u, err := q.GetUser(ctx, p.UserID)
		if err != nil {
			return err
		}
		if err := s.send(ctx, tx, notify.Email, u.Email, u.Locale, "erasure_scheduled", map[string]any{
			"Date": at.Format("2006-01-02"), "Link": s.Cfg.WebBaseURL + "/admin/settings/privacy"}); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{Entity: "gdpr_request", EntityID: &r.ID, Action: "gdpr.erasure_requested",
			Diff: map[string]any{"scheduled_at": at.Format(time.RFC3339)}})
	})
	return r, err
}

// CancelErasure cancels a pending erasure.
func (s *Service) CancelErasure(ctx context.Context, p *auth.Principal) error {
	return s.tx(ctx, func(q *db.Queries, _ pgx.Tx) error {
		r, err := q.GetOpenErasureRequest(ctx, p.UserID)
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("erasure_not_found", "no pending erasure request")
		}
		if err != nil {
			return err
		}
		if r.Status != "pending" {
			return apperr.Conflict("erasure_in_progress", "the erasure is already running")
		}
		if err := q.UpdateGDPRRequest(ctx, db.UpdateGDPRRequestParams{ID: r.ID, Status: "cancelled"}); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{Entity: "gdpr_request", EntityID: &r.ID, Action: "gdpr.erasure_cancelled"})
	})
}

// exportDoc is the machine-readable export (GDPR art. 20).
type exportDoc struct {
	GeneratedAt   time.Time                   `json:"generated_at"`
	User          map[string]any              `json:"user"`
	Organizations []db.ListMyOrganizationsRow `json:"organizations"`
	Consents      []db.Consent                `json:"consents"`
	Sessions      []map[string]any            `json:"sessions"`
	Identity      *db.IdentityVerification    `json:"identity_verification,omitempty"`
	Requests      []db.GdprRequest            `json:"gdpr_requests"`
	Activity      []db.AuditEvent             `json:"activity"`
}

// RunExport builds the export file (worker job).
func (s *Service) RunExport(ctx context.Context, requestID uuid.UUID) error {
	q := db.New(s.Pool)
	r, err := q.GetGDPRRequest(ctx, requestID)
	if err != nil {
		return err
	}
	if r.Status != "pending" && r.Status != "failed" {
		return nil
	}
	_ = q.UpdateGDPRRequest(ctx, db.UpdateGDPRRequestParams{ID: r.ID, Status: "processing"})
	u, err := q.GetUser(ctx, r.UserID)
	if err != nil {
		return err
	}
	doc := exportDoc{GeneratedAt: time.Now().UTC(), User: map[string]any{
		"id": u.ID, "email": u.Email, "email_verified_at": u.EmailVerifiedAt, "display_name": u.DisplayName,
		"locale": u.Locale, "phone": u.Phone, "phone_verified_at": u.PhoneVerifiedAt,
		"identity_verified_at": u.IdentityVerifiedAt, "mfa_enabled": u.TotpEnabledAt != nil,
		"verification_level": u.VerificationLevel, "created_at": u.CreatedAt,
	}}
	if doc.Organizations, err = q.ListMyOrganizations(ctx, u.ID); err != nil {
		return err
	}
	if doc.Consents, err = q.ListConsents(ctx, u.ID); err != nil {
		return err
	}
	sess, err := q.ListUserSessions(ctx, u.ID)
	if err != nil {
		return err
	}
	for _, x := range sess {
		doc.Sessions = append(doc.Sessions, map[string]any{"client": x.Client, "ip": x.Ip, "user_agent": x.UserAgent,
			"created_at": x.CreatedAt, "last_seen_at": x.LastSeenAt})
	}
	if iv, err := q.GetIdentityVerification(ctx, u.ID); err == nil {
		doc.Identity = &iv
	}
	if doc.Requests, err = q.ListGDPRRequests(ctx, u.ID); err != nil {
		return err
	}
	if doc.Activity, err = q.ListAuditEventsByActor(ctx, &u.ID); err != nil {
		return err
	}
	body, err := json.MarshalIndent(doc, "", "  ")
	if err != nil {
		return err
	}
	key := fmt.Sprintf("gdpr/exports/%s/%s.json", u.ID, r.ID)
	if err := s.Blob.Put(ctx, key, "application/json", body); err != nil {
		_ = q.UpdateGDPRRequest(ctx, db.UpdateGDPRRequestParams{ID: r.ID, Status: "failed", Detail: ptr(err.Error())})
		return err
	}
	return s.tx(ctx, func(q *db.Queries, tx pgx.Tx) error {
		if err := q.UpdateGDPRRequest(ctx, db.UpdateGDPRRequestParams{ID: r.ID, Status: "done", ObjectKey: &key}); err != nil {
			return err
		}
		return s.send(ctx, tx, notify.Email, u.Email, u.Locale, "export_ready",
			map[string]any{"Link": s.Cfg.WebBaseURL + "/admin/settings/privacy"})
	})
}

// RunErasure pseudonymizes the account when the grace period is over (worker
// job). Sole owners of company organizations with other members must hand
// over ownership first; the request is then rejected with a reason.
func (s *Service) RunErasure(ctx context.Context, requestID uuid.UUID) error {
	return s.tx(ctx, func(q *db.Queries, tx pgx.Tx) error {
		r, err := q.GetGDPRRequest(ctx, requestID)
		if err != nil {
			return err
		}
		if r.Status != "pending" || r.ScheduledAt.After(time.Now()) {
			return nil
		}
		u, err := q.GetUser(ctx, r.UserID)
		if err != nil {
			return err
		}
		ms, err := q.ListUserMemberships(ctx, u.ID)
		if err != nil {
			return err
		}
		for _, m := range ms {
			if m.Kind == "company" && m.Role == "owner" && m.OwnerCount == 1 && m.MemberCount > 1 {
				reason := "transfer ownership of your organizations first"
				if err := q.UpdateGDPRRequest(ctx, db.UpdateGDPRRequestParams{ID: r.ID, Status: "rejected", Detail: &reason}); err != nil {
					return err
				}
				return s.send(ctx, tx, notify.Email, u.Email, u.Locale, "erasure_rejected",
					map[string]any{"Reason": reason, "Link": s.Cfg.WebBaseURL + "/admin/settings/privacy"})
			}
		}
		for _, m := range ms {
			if m.Kind == "personal" || m.MemberCount == 1 {
				if err := q.SoftDeleteOrganization(ctx, m.OrgID); err != nil {
					return err
				}
			}
			if m.Kind == "company" {
				if _, err := q.DeleteMembership(ctx, db.DeleteMembershipParams{OrgID: m.OrgID, UserID: u.ID}); err != nil {
					return err
				}
			}
		}
		if err := q.RevokeUserSessions(ctx, db.RevokeUserSessionsParams{UserID: u.ID}); err != nil {
			return err
		}
		if err := q.DeleteOAuthIdentities(ctx, u.ID); err != nil {
			return err
		}
		if err := q.DeleteRecoveryCodes(ctx, u.ID); err != nil {
			return err
		}
		// Seeker data from M4/M5: profiles, passport (with the income file), devices, groups.
		if err := q.DeleteRoommateProfile(ctx, u.ID); err != nil {
			return err
		}
		if key, err := q.DeletePassport(ctx, u.ID); err == nil && key != nil && s.Blob != nil {
			_ = s.Blob.Delete(ctx, *key)
		} else if err != nil && !errors.Is(err, pgx.ErrNoRows) {
			return err
		}
		if err := q.DeleteUserPushDevices(ctx, u.ID); err != nil {
			return err
		}
		if err := q.DeleteUserGroupMemberships(ctx, &u.ID); err != nil {
			return err
		}
		// Identity verifications stay while contracts may need them (legal-questions.md, Q-GDPR-1).
		if err := q.PseudonymizeUser(ctx, u.ID); err != nil {
			return err
		}
		if err := q.UpdateGDPRRequest(ctx, db.UpdateGDPRRequestParams{ID: r.ID, Status: "done"}); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{Entity: "user", EntityID: &u.ID, Action: "user.erased", ActorID: &u.ID})
	})
}
