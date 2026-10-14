package applications

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"path"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/isir"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
)

// Passport is the caller's Tenant Passport v0.
type Passport struct {
	Verification   string
	IncomeFilename *string
	IncomeAt       *time.Time
	ISIRStatus     string
	ISIRCheckedAt  *time.Time
}

// Passport returns the caller's passport.
func (s *Service) Passport(ctx context.Context, p *auth.Principal) (Passport, error) {
	u, err := db.New(s.Pool).GetUser(ctx, p.UserID)
	if err != nil {
		return Passport{}, err
	}
	out := Passport{ISIRStatus: "unchecked", Verification: "none"}
	if u.VerificationLevel != nil {
		out.Verification = *u.VerificationLevel
	}
	err = s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		r, err := q.GetPassport(ctx, p.UserID)
		if errors.Is(err, pgx.ErrNoRows) {
			return nil
		}
		if err != nil {
			return err
		}
		out.IncomeFilename, out.IncomeAt = r.IncomeFilename, r.IncomeUploadedAt
		out.ISIRStatus, out.ISIRCheckedAt = r.IsirStatus, r.IsirCheckedAt
		return nil
	})
	return out, err
}

// IncomeUpload is a presigned upload slot for an income proof.
type IncomeUpload struct {
	Key       string
	UploadURL string
}

// CreateIncomeUpload reserves a storage key for the caller's income proof.
func (s *Service) CreateIncomeUpload(ctx context.Context, p *auth.Principal, contentType string, size int64) (IncomeUpload, error) {
	if contentType != "application/pdf" && contentType != "image/jpeg" && contentType != "image/png" {
		return IncomeUpload{}, apperr.Unprocessable("attachment_type", "upload a PDF, JPEG or PNG")
	}
	if size <= 0 || size > 10<<20 {
		return IncomeUpload{}, apperr.Unprocessable("attachment_size", "the file is limited to 10 MB")
	}
	key := fmt.Sprintf("passports/%s/income-%s", p.UserID, uuid.NewString())
	u, err := s.Blob.PresignPut(ctx, key, 15*time.Minute)
	return IncomeUpload{Key: key, UploadURL: u}, err
}

// CompleteIncomeUpload checks the uploaded file and attaches it to the
// passport, replacing an earlier one.
func (s *Service) CompleteIncomeUpload(ctx context.Context, p *auth.Principal, key, filename string) error {
	if !strings.HasPrefix(key, "passports/"+p.UserID.String()+"/") {
		return apperr.NotFound("upload_not_found", "upload not found")
	}
	data, err := s.Blob.Get(ctx, key)
	if err != nil {
		return apperr.Unprocessable("attachment_missing", "upload the file first")
	}
	sniffed := http.DetectContentType(data)
	if !strings.HasPrefix(sniffed, "application/pdf") && !strings.HasPrefix(sniffed, "image/") {
		_ = s.Blob.Delete(ctx, key)
		return apperr.Unprocessable("attachment_type", "upload a PDF, JPEG or PNG")
	}
	if status, _, err := s.Scanner.Scan(ctx, data); err != nil {
		return err
	} else if status == "infected" {
		_ = s.Blob.Delete(ctx, key)
		return apperr.Unprocessable("attachment_infected", "the file was rejected by the malware scanner")
	}
	filename = path.Base(strings.ReplaceAll(filename, "\\", "/"))
	if filename == "" || filename == "." || len(filename) > 200 {
		filename = "potvrzeni-prijmu"
	}
	var old *string
	err = s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if r, err := q.GetPassport(ctx, p.UserID); err == nil {
			old = r.IncomeKey
		}
		if err := q.SetPassportIncome(ctx, db.SetPassportIncomeParams{UserID: p.UserID, IncomeKey: &key, IncomeFilename: &filename}); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{Entity: "tenant_passport", EntityID: &p.UserID, Action: "passport.income_upload"})
	})
	if err == nil && old != nil && *old != key {
		_ = s.Blob.Delete(ctx, *old)
	}
	return err
}

// DeleteIncomeProof removes the caller's income proof.
func (s *Service) DeleteIncomeProof(ctx context.Context, p *auth.Principal) error {
	var old *string
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if r, err := q.GetPassport(ctx, p.UserID); err == nil {
			old = r.IncomeKey
		}
		if err := q.ClearPassportIncome(ctx, p.UserID); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{Entity: "tenant_passport", EntityID: &p.UserID, Action: "passport.income_delete"})
	})
	if err == nil && old != nil {
		_ = s.Blob.Delete(ctx, *old)
	}
	return err
}

// CheckInsolvency looks the caller up in ISIR. It needs a verified identity
// (name and birth date from BankID) and runs at most once a day.
func (s *Service) CheckInsolvency(ctx context.Context, p *auth.Principal) (string, error) {
	sys := db.New(s.Pool)
	id, err := sys.GetIdentityVerification(ctx, p.UserID)
	if errors.Is(err, pgx.ErrNoRows) || (err == nil && (id.FamilyName == nil || !id.Birthdate.Valid)) {
		return "", apperr.Unprocessable("identity_required", "verify your identity with BankID first")
	}
	if err != nil {
		return "", err
	}
	if r, err := sys.GetPassport(ctx, p.UserID); err == nil && r.IsirCheckedAt != nil &&
		time.Since(*r.IsirCheckedAt) < 24*time.Hour && r.IsirStatus != "error" {
		return r.IsirStatus, nil
	}
	given := ""
	if id.GivenName != nil {
		given = *id.GivenName
	}
	status, cerr := s.ISIR.Check(ctx, isir.Person{GivenName: given, FamilyName: *id.FamilyName, Birthdate: id.Birthdate.Time})
	if cerr != nil {
		s.Log.Warn("isir check", "err", cerr)
		status = "error"
	}
	err = s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if err := q.SetPassportISIR(ctx, db.SetPassportISIRParams{UserID: p.UserID, IsirStatus: status}); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{Entity: "tenant_passport", EntityID: &p.UserID, Action: "passport.isir_check",
			Diff: map[string]any{"status": status}})
	})
	return status, err
}
