package portfolio

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/terrareality/terrareality/services/api/internal/db"
)

var prague = func() *time.Location {
	if l, err := time.LoadLocation("Europe/Prague"); err == nil {
		return l
	}
	return time.UTC
}()

// Scorer recomputes lease risk scores (system context: the worker).
type Scorer struct {
	Pool *pgxpool.Pool
	Log  *slog.Logger     // nil: slog.Default
	Now  func() time.Time // tests
}

func (s *Scorer) now() time.Time {
	if s.Now != nil {
		return s.Now()
	}
	return time.Now()
}

// today is the current Prague date at midnight UTC (dates are compared as
// calendar days).
func today(now time.Time) time.Time {
	t := now.In(prague)
	return time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, time.UTC)
}

// Input loads the model input of a lease.
func (s *Scorer) Input(ctx context.Context, q *db.Queries, l db.Lease) (Input, error) {
	day := today(s.now())
	in := Input{Today: day, State: l.State, Monthly: l.RentAmount + l.ServicesAmount, Rent: l.RentAmount,
		Deposit: l.DepositAmount, NoticeGiven: l.NoticeOn.Valid}
	if l.EndsOn.Valid {
		t := l.EndsOn.Time
		in.EndsOn = &t
	}
	parties, err := q.RiskPartyStats(ctx, db.RiskPartyStatsParams{AsOf: pgDate(day), LeaseID: l.ID})
	if err != nil {
		return in, err
	}
	for _, p := range parties {
		pp := Party{Overdue: p.Overdue, DepositUnpaid: p.DepositUnpaid, DepositPaid: p.DepositPaid, HasAccount: p.UserID != nil,
			Verification: p.Verification, IncomeProof: p.IncomeProof, Insolvency: p.IsirStatus}
		if p.OldestUnpaid.Valid {
			t := p.OldestUnpaid.Time
			pp.OldestUnpaid = &t
		}
		in.Parties = append(in.Parties, pp)
	}
	n, err := q.CountLeaseEventsSince(ctx, db.CountLeaseEventsSinceParams{LeaseID: l.ID, Kind: "payment_escalated",
		CreatedAt: s.now().AddDate(-1, 0, 0)})
	if err != nil {
		return in, err
	}
	in.Escalations = int(n)
	if mp := municipalityPath(l.AdminPath.String); mp != "" {
		m, err := q.MarketStats(ctx, db.MarketStatsParams{Path: mp, Currency: l.Currency})
		if err != nil {
			return in, err
		}
		in.MedianRent, in.MarketListings, in.AvgListingDays = m.MedianRent, int(m.Listings), m.AvgAgeDays
	}
	return in, nil
}

// municipalityPath cuts an admin path to the municipality level
// (cz.<region>.<municipality>).
func municipalityPath(p string) string {
	dots := 0
	for i, c := range p {
		if c == '.' {
			dots++
			if dots == 3 {
				return p[:i]
			}
		}
	}
	if dots == 2 {
		return p
	}
	return ""
}

// Weights loads the organization's factor weights.
func Weights(ctx context.Context, q *db.Queries, orgID uuid.UUID) (map[string]int, error) {
	b, err := q.GetRiskSettings(ctx, orgID)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	var w map[string]int
	return w, json.Unmarshal(b, &w)
}

// Recompute scores one lease and stores the score and this month's snapshot.
func (s *Scorer) Recompute(ctx context.Context, id uuid.UUID) (Result, error) {
	var res Result
	err := pgx.BeginFunc(ctx, s.Pool, func(tx pgx.Tx) error {
		q := db.New(tx)
		l, err := q.GetLease(ctx, id)
		if err != nil {
			return err
		}
		switch l.State {
		case "signed", "active", "notice_given":
		default:
			return q.ClearLeaseRisk(ctx, id)
		}
		if !l.AdminPath.Valid { // leases from before M6b, or created before the place was known
			place, err := Locate(ctx, q, l.ListingID, nil, l.PropertyAddress)
			if err != nil {
				return err
			}
			if place.AdminPath != "" {
				if err := q.SetLeaseLocation(ctx, db.SetLeaseLocationParams{ID: l.ID, UnitID: place.UnitID, AdminPath: place.AdminPath,
					Lat: place.Lat, Lng: place.Lng}); err != nil {
					return err
				}
				l.AdminPath.String, l.AdminPath.Valid = place.AdminPath, true
			}
		}
		in, err := s.Input(ctx, q, l)
		if err != nil {
			return err
		}
		w, err := Weights(ctx, q, l.OrgID)
		if err != nil {
			return err
		}
		res = Score(in, w)
		factors, err := json.Marshal(res.Factors)
		if err != nil {
			return err
		}
		if err := q.UpsertLeaseRisk(ctx, db.UpsertLeaseRiskParams{LeaseID: id, OrgID: l.OrgID, Score: int32(res.Score),
			Band: res.Band, Factors: factors, ModelVersion: ModelVersion}); err != nil {
			return err
		}
		return q.UpsertLeaseRiskHistory(ctx, db.UpsertLeaseRiskHistoryParams{LeaseID: id, OrgID: l.OrgID,
			Period: in.Today.Format("2006-01"), Score: int32(res.Score), Band: res.Band, Monthly: in.Monthly})
	})
	return res, err
}

// RecomputeStale rescores leases with new events, stale or missing scores
// and returns how many were rescored. A lease that fails is logged, marked
// on its score row (lease_risk.last_error / failed_at, S-P1) and skipped, so
// one broken lease does not stop the others; a marked lease waits an hour
// before the next attempt (StaleRiskLeaseIDs) and is ordered last. Only when
// every lease failed is an error returned.
func (s *Scorer) RecomputeStale(ctx context.Context) (int, error) {
	ids, err := db.New(s.Pool).StaleRiskLeaseIDs(ctx, ModelVersion)
	if err != nil {
		return 0, err
	}
	log := s.Log
	if log == nil {
		log = slog.Default()
	}
	done := 0
	var first error
	for _, id := range ids {
		if _, err := s.Recompute(ctx, id); err != nil {
			if ctx.Err() != nil {
				return done, ctx.Err()
			}
			log.Error("lease risk recompute failed", "lease_id", id, "err", err)
			if _, merr := db.New(s.Pool).MarkLeaseRiskFailed(ctx, db.MarkLeaseRiskFailedParams{LeaseID: id,
				LastError: err.Error()}); merr != nil {
				log.Warn("mark lease risk failure", "lease_id", id, "err", merr)
			}
			if first == nil {
				first = fmt.Errorf("lease %s: %w", id, err)
			}
			continue
		}
		done++
	}
	if done == 0 && first != nil {
		return 0, fmt.Errorf("risk recompute: all %d leases failed, first %w", len(ids), first)
	}
	return done, nil
}

// RecomputeOrg rescores every running lease of an organization (after the
// weights changed).
func (s *Scorer) RecomputeOrg(ctx context.Context, orgID uuid.UUID) error {
	rows, err := db.New(s.Pool).RentRollLeases(ctx, db.RentRollLeasesParams{OrgID: orgID, AsOf: pgDate(today(s.now()))})
	if err != nil {
		return err
	}
	for _, r := range rows {
		if _, err := s.Recompute(ctx, r.ID); err != nil {
			return err
		}
	}
	return nil
}
