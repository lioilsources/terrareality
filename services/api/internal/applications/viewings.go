package applications

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/org"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
)

// SlotInput is a new viewing slot.
type SlotInput struct {
	StartsAt    time.Time
	DurationMin int32
	Capacity    int32
	Note        string
}

// CreateSlot adds a viewing slot to a listing.
func (s *Service) CreateSlot(ctx context.Context, p *auth.Principal, orgID, listingID uuid.UUID, in SlotInput) (db.ViewingSlot, error) {
	if !in.StartsAt.After(time.Now()) {
		return db.ViewingSlot{}, apperr.Unprocessable("slot_in_past", "the viewing must be in the future")
	}
	in.DurationMin = min(max(in.DurationMin, 5), 240)
	in.Capacity = min(max(in.Capacity, 1), 50)
	var out db.ViewingSlot
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermMessages); err != nil {
			return err
		}
		if _, err := q.GetListing(ctx, db.GetListingParams{ID: listingID, OrgID: orgID}); err != nil {
			return apperr.NotFound("listing_not_found", "listing not found")
		}
		var err error
		out, err = q.CreateViewingSlot(ctx, db.CreateViewingSlotParams{OrgID: orgID, ListingID: listingID,
			StartsAt: in.StartsAt, DurationMin: in.DurationMin, Capacity: in.Capacity, Note: in.Note})
		if err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "viewing_slot", EntityID: &out.ID, Action: "viewing.slot_create"})
	})
	return out, err
}

// DeleteSlot removes a slot (bookings are cancelled with it).
func (s *Service) DeleteSlot(ctx context.Context, p *auth.Principal, orgID, id uuid.UUID) error {
	return s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermMessages); err != nil {
			return err
		}
		n, err := q.DeleteViewingSlot(ctx, db.DeleteViewingSlotParams{ID: id, OrgID: orgID})
		if err != nil {
			return err
		}
		if n == 0 {
			return apperr.NotFound("slot_not_found", "slot not found")
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "viewing_slot", EntityID: &id, Action: "viewing.slot_delete"})
	})
}

// Slots lists a listing's upcoming slots with bookings (landlord).
func (s *Service) Slots(ctx context.Context, p *auth.Principal, orgID, listingID uuid.UUID) ([]db.SlotsWithAvailabilityRow, []db.ListSlotBookingsRow, error) {
	var bookings []db.ListSlotBookingsRow
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermMessages); err != nil {
			return err
		}
		if _, err := q.GetListing(ctx, db.GetListingParams{ID: listingID, OrgID: orgID}); err != nil {
			return apperr.NotFound("listing_not_found", "listing not found")
		}
		var err error
		bookings, err = q.ListSlotBookings(ctx, listingID)
		return err
	})
	if err != nil {
		return nil, nil, err
	}
	slots, err := db.New(s.Pool).SlotsWithAvailability(ctx, listingID)
	return slots, bookings, err
}

var errSlotFull = apperr.Conflict("slot_full", "this viewing is fully booked")

// Book reserves a slot for an application (replacing an earlier booking)
// and schedules reminders 24 and 2 hours before.
func (s *Service) Book(ctx context.Context, p *auth.Principal, appID, slotID uuid.UUID) (uuid.UUID, error) {
	var app db.GetApplicationRow
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		var err error
		app, err = q.GetApplication(ctx, appID)
		if errors.Is(err, pgx.ErrNoRows) {
			return errAppNotFound
		}
		return err
	})
	if err != nil {
		return uuid.Nil, err
	}
	if app.Status != StatusSubmitted && app.Status != StatusInvited {
		return uuid.Nil, apperr.Conflict("application_closed", "viewings can be booked for open applications only")
	}
	var booking db.ViewingBooking
	err = s.system(ctx, func(q *db.Queries, tx pgx.Tx) error {
		slot, err := q.LockSlot(ctx, slotID)
		if errors.Is(err, pgx.ErrNoRows) || (err == nil && slot.ListingID != app.ListingID) {
			return apperr.NotFound("slot_not_found", "slot not found")
		}
		if err != nil {
			return err
		}
		if !slot.StartsAt.After(time.Now()) {
			return apperr.Conflict("slot_in_past", "this viewing has already started")
		}
		if err := q.CancelApplicationBookings(ctx, appID); err != nil {
			return err
		}
		n, err := q.CountSlotBookings(ctx, slotID)
		if err != nil {
			return err
		}
		if n >= slot.Capacity {
			return errSlotFull
		}
		if booking, err = q.InsertBooking(ctx, db.InsertBookingParams{SlotID: slotID, ApplicationID: appID, BookedBy: &p.UserID}); err != nil {
			return err
		}
		if err := audit.Record(ctx, q, audit.Event{OrgID: &app.OrgID, Entity: "viewing_booking", EntityID: &booking.ID,
			Action: "viewing.book", Diff: map[string]any{"slot_id": slotID, "application_id": appID}}); err != nil {
			return err
		}
		if s.Jobs != nil {
			for _, before := range []time.Duration{24 * time.Hour, 2 * time.Hour} {
				if at := slot.StartsAt.Add(-before); at.After(time.Now()) {
					if err := s.Jobs.ViewingReminder(ctx, tx, booking.ID, at); err != nil {
						return err
					}
				}
			}
		}
		members, err := q.OrgMessagingMembers(ctx, app.OrgID)
		if err != nil {
			return err
		}
		to := make([]recipient, 0, len(members))
		for _, m := range members {
			to = append(to, recipient{ID: m.ID, Email: m.Email, Locale: m.Locale})
		}
		return s.notifyAll(ctx, q, tx, to, "viewing_booked",
			s.WebBaseURL+"/admin/orgs/"+app.OrgID.String()+"/listings/"+app.ListingID.String()+"/zajemci",
			map[string]any{"ListingTitle": i18n(app.ListingTitle), "When": slot.StartsAt.In(prague).Format("2. 1. 2006 15:04")})
	})
	return booking.ID, err
}

var prague = func() *time.Location {
	l, err := time.LoadLocation("Europe/Prague")
	if err != nil {
		return time.UTC
	}
	return l
}()

// CancelBooking cancels one of the caller's bookings.
func (s *Service) CancelBooking(ctx context.Context, p *auth.Principal, id uuid.UUID) error {
	return s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		n, err := q.CancelBooking(ctx, id)
		if err != nil {
			return err
		}
		if n == 0 {
			return apperr.NotFound("booking_not_found", "booking not found")
		}
		return audit.Record(ctx, q, audit.Event{Entity: "viewing_booking", EntityID: &id, Action: "viewing.cancel"})
	})
}

// MyViewings lists the caller's upcoming viewings.
func (s *Service) MyViewings(ctx context.Context, p *auth.Principal) ([]db.MyViewingsRow, error) {
	var out []db.MyViewingsRow
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		var err error
		out, err = q.MyViewings(ctx, p.UserID)
		return err
	})
	return out, err
}
