package api

import (
	"context"
	"encoding/json"
	"time"

	"github.com/google/uuid"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/terrareality/terrareality/services/api/internal/api/gen"
	"github.com/terrareality/terrareality/services/api/internal/applications"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
)

// appRow is the common shape of the application rows sqlc generates (they
// share column names; JSON keeps the mapping in one place).
type appRow struct {
	ID             uuid.UUID  `json:"id"`
	ListingID      uuid.UUID  `json:"listing_id"`
	OrgID          uuid.UUID  `json:"org_id"`
	GroupID        *uuid.UUID `json:"group_id"`
	Status         string     `json:"status"`
	Message        string     `json:"message"`
	Answers        []byte     `json:"answers"`
	PreferredFrom  *string    `json:"preferred_from"`
	DurationMonths *int       `json:"duration_months"`
	HouseholdSize  int        `json:"household_size"`
	RejectReason   *string    `json:"reject_reason"`
	AiStatus       string     `json:"ai_status"`
	AiSummary      []byte     `json:"ai_summary"`
	CreatedAt      time.Time  `json:"created_at"`
	SubmittedAt    *time.Time `json:"submitted_at"`
	ListingTitle   []byte     `json:"listing_title"`
	GroupName      *string    `json:"group_name"`
	MyConsentAt    *time.Time `json:"my_consent_at"`
	ConsentNeeded  bool       `json:"consent_needed"`
}

func appDTO(row any) gen.Application {
	r := convert[appRow](row)
	if r.GroupName != nil && *r.GroupName == "" {
		r.GroupName = nil
	}
	out := gen.Application{Id: r.ID, ListingId: r.ListingID, OrgId: r.OrgID, GroupId: r.GroupID, GroupName: r.GroupName,
		Status: gen.ApplicationStatus(r.Status), Message: &r.Message, DurationMonths: r.DurationMonths,
		HouseholdSize: r.HouseholdSize, ListingTitle: i18nDTO(r.ListingTitle), ConsentNeeded: r.ConsentNeeded,
		MyConsentAt: r.MyConsentAt, CreatedAt: r.CreatedAt, SubmittedAt: r.SubmittedAt}
	if r.PreferredFrom != nil {
		if t, err := time.Parse("2006-01-02", *r.PreferredFrom); err == nil {
			out.PreferredFrom = &openapi_types.Date{Time: t}
		}
	}
	if r.RejectReason != nil {
		rr := gen.RejectReason(*r.RejectReason)
		out.RejectReason = &rr
	}
	return out
}

func slotDTO(s db.SlotsWithAvailabilityRow) gen.ViewingSlot {
	return gen.ViewingSlot{Id: s.ID, StartsAt: s.StartsAt, DurationMin: int(s.DurationMin), Capacity: int(s.Capacity),
		Booked: int(s.Booked), Note: s.Note, Bookings: []struct {
			ApplicantName string             `json:"applicant_name"`
			ApplicationId openapi_types.UUID `json:"application_id"`
			HouseholdSize int                `json:"household_size"`
			Id            openapi_types.UUID `json:"id"`
		}{}}
}

func viewingDTO(v db.MyViewingsRow) gen.Viewing {
	return gen.Viewing{Id: v.ID, ApplicationId: v.ApplicationID, ListingId: v.ListingID, ListingTitle: i18nDTO(v.ListingTitle),
		City: v.City, StartsAt: v.StartsAt, DurationMin: int(v.DurationMin), Note: v.Note}
}

func (s *Server) applicationDetail(ctx context.Context, id uuid.UUID) (gen.ApplicationDetail, error) {
	p, err := principal(ctx)
	if err != nil {
		return gen.ApplicationDetail{}, err
	}
	d, err := s.Applications.Application(ctx, p, id)
	if err != nil {
		return gen.ApplicationDetail{}, err
	}
	out := gen.ApplicationDetail{Application: appDTO(d.GetApplicationRow), Consents: []gen.ApplicationConsent{}, Slots: []gen.ViewingSlot{}}
	for _, c := range d.Consents {
		out.Consents = append(out.Consents, gen.ApplicationConsent{UserId: c.UserID, DisplayName: c.DisplayName, ConsentedAt: c.ConsentedAt})
		if c.UserID == p.UserID {
			out.Application.ConsentNeeded, out.Application.MyConsentAt = true, c.ConsentedAt
		}
	}
	for _, sl := range d.Slots {
		out.Slots = append(out.Slots, slotDTO(sl))
	}
	if d.Booking != nil {
		v := viewingDTO(*d.Booking)
		out.Booking = &v
	}
	return out, nil
}

// ListMyApplications implements GET /v1/applications.
func (s *Server) ListMyApplications(ctx context.Context, _ gen.ListMyApplicationsRequestObject) (gen.ListMyApplicationsResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	rows, err := s.Applications.MyApplications(ctx, p)
	if err != nil {
		return nil, err
	}
	out := gen.ListMyApplications200JSONResponse{}
	for _, r := range rows {
		out = append(out, appDTO(r))
	}
	return out, nil
}

// CreateApplication implements POST /v1/applications.
func (s *Server) CreateApplication(ctx context.Context, r gen.CreateApplicationRequestObject) (gen.CreateApplicationResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.limit(ctx, "apply:"+p.UserID.String()); err != nil {
		return nil, err
	}
	in := applications.ApplyInput{ListingID: r.Body.ListingId, GroupID: r.Body.GroupId, HouseholdSize: 1}
	if r.Body.Message != nil {
		in.Message = *r.Body.Message
	}
	if r.Body.PrescreenAnswers != nil {
		in.Answers = *r.Body.PrescreenAnswers
	}
	if r.Body.PreferredFrom != nil {
		t := r.Body.PreferredFrom.Time
		in.PreferredFrom = &t
	}
	if r.Body.DurationMonths != nil {
		d := int32(*r.Body.DurationMonths)
		in.DurationMonths = &d
	}
	if r.Body.HouseholdSize != nil {
		in.HouseholdSize = int32(*r.Body.HouseholdSize)
	}
	id, err := s.Applications.Apply(ctx, p, in)
	if err != nil {
		return nil, err
	}
	d, err := s.applicationDetail(ctx, id)
	if err != nil {
		return nil, err
	}
	return gen.CreateApplication201JSONResponse(d), nil
}

// GetApplication implements GET /v1/applications/{applicationId}.
func (s *Server) GetApplication(ctx context.Context, r gen.GetApplicationRequestObject) (gen.GetApplicationResponseObject, error) {
	d, err := s.applicationDetail(ctx, r.ApplicationId)
	if err != nil {
		return nil, err
	}
	return gen.GetApplication200JSONResponse(d), nil
}

// ConsentApplication implements POST /v1/applications/{applicationId}/consent.
func (s *Server) ConsentApplication(ctx context.Context, r gen.ConsentApplicationRequestObject) (gen.ConsentApplicationResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Applications.Consent(ctx, p, r.ApplicationId); err != nil {
		return nil, err
	}
	return gen.ConsentApplication204Response{}, nil
}

// WithdrawApplication implements POST /v1/applications/{applicationId}/withdraw.
func (s *Server) WithdrawApplication(ctx context.Context, r gen.WithdrawApplicationRequestObject) (gen.WithdrawApplicationResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Applications.Withdraw(ctx, p, r.ApplicationId); err != nil {
		return nil, err
	}
	return gen.WithdrawApplication204Response{}, nil
}

// BookViewing implements POST /v1/applications/{applicationId}/bookings.
func (s *Server) BookViewing(ctx context.Context, r gen.BookViewingRequestObject) (gen.BookViewingResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	id, err := s.Applications.Book(ctx, p, r.ApplicationId, r.Body.SlotId)
	if err != nil {
		return nil, err
	}
	return gen.BookViewing201JSONResponse{Id: id}, nil
}

// CancelViewing implements DELETE /v1/viewing-bookings/{bookingId}.
func (s *Server) CancelViewing(ctx context.Context, r gen.CancelViewingRequestObject) (gen.CancelViewingResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Applications.CancelBooking(ctx, p, r.BookingId); err != nil {
		return nil, err
	}
	return gen.CancelViewing204Response{}, nil
}

// ListMyViewings implements GET /v1/me/viewings.
func (s *Server) ListMyViewings(ctx context.Context, _ gen.ListMyViewingsRequestObject) (gen.ListMyViewingsResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	rows, err := s.Applications.MyViewings(ctx, p)
	if err != nil {
		return nil, err
	}
	out := gen.ListMyViewings200JSONResponse{}
	for _, v := range rows {
		out = append(out, viewingDTO(v))
	}
	return out, nil
}

// ListListingApplications implements GET /v1/orgs/{orgId}/listings/{listingId}/applications.
func (s *Server) ListListingApplications(ctx context.Context, r gen.ListListingApplicationsRequestObject) (gen.ListListingApplicationsResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	rows, err := s.Applications.Applicants(ctx, p, r.OrgId, r.ListingId)
	if err != nil {
		return nil, err
	}
	out := gen.ListListingApplications200JSONResponse{}
	for _, a := range rows {
		item := gen.Applicant{Application: appDTO(a.ListListingApplicationsRow), ApplicantName: a.ApplicantName,
			VerificationLevel: gen.VerificationLevel(a.VerificationLevel), AiStatus: gen.ApplicantAiStatus(a.AiStatus),
			People: []gen.ApplicantPerson{}}
		prescreen := convert[[]gen.PrescreenAnswer](json.RawMessage(a.Answers))
		item.Prescreen = &prescreen
		if len(a.AiSummary) > 0 {
			sum := convert[gen.ApplicationSummary](json.RawMessage(a.AiSummary))
			item.AiSummary = &sum
		}
		for _, pp := range a.People {
			person := gen.ApplicantPerson{UserId: pp.ID, DisplayName: pp.Name, VerificationLevel: gen.VerificationLevel(pp.Verification),
				Insolvency: gen.ApplicantPersonInsolvency(pp.Insolvency)}
			if pp.IncomeProof != "" {
				u, n := pp.IncomeProof, pp.IncomeName
				person.IncomeProofUrl, person.IncomeProofName = &u, &n
			}
			item.People = append(item.People, person)
		}
		out = append(out, item)
	}
	return out, nil
}

// DecideApplication implements POST /v1/orgs/{orgId}/applications/{applicationId}/decision.
func (s *Server) DecideApplication(ctx context.Context, r gen.DecideApplicationRequestObject) (gen.DecideApplicationResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	reason := ""
	if r.Body.Reason != nil {
		reason = string(*r.Body.Reason)
	}
	if err := s.Applications.Decide(ctx, p, r.OrgId, r.ApplicationId, string(r.Body.Action), reason); err != nil {
		return nil, err
	}
	return gen.DecideApplication204Response{}, nil
}

// ListViewingSlots implements GET /v1/orgs/{orgId}/listings/{listingId}/viewing-slots.
func (s *Server) ListViewingSlots(ctx context.Context, r gen.ListViewingSlotsRequestObject) (gen.ListViewingSlotsResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	slots, bookings, err := s.Applications.Slots(ctx, p, r.OrgId, r.ListingId)
	if err != nil {
		return nil, err
	}
	out := gen.ListViewingSlots200JSONResponse{}
	for _, sl := range slots {
		dto := slotDTO(sl)
		for _, b := range bookings {
			if b.SlotID == sl.ID {
				dto.Bookings = append(dto.Bookings, struct {
					ApplicantName string             `json:"applicant_name"`
					ApplicationId openapi_types.UUID `json:"application_id"`
					HouseholdSize int                `json:"household_size"`
					Id            openapi_types.UUID `json:"id"`
				}{b.ApplicantName, b.ApplicationID, int(b.HouseholdSize), b.ID})
			}
		}
		out = append(out, dto)
	}
	return out, nil
}

// CreateViewingSlot implements POST /v1/orgs/{orgId}/listings/{listingId}/viewing-slots.
func (s *Server) CreateViewingSlot(ctx context.Context, r gen.CreateViewingSlotRequestObject) (gen.CreateViewingSlotResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	in := applications.SlotInput{StartsAt: r.Body.StartsAt, DurationMin: 20, Capacity: 1}
	if r.Body.DurationMin != nil {
		in.DurationMin = int32(*r.Body.DurationMin)
	}
	if r.Body.Capacity != nil {
		in.Capacity = int32(*r.Body.Capacity)
	}
	if r.Body.Note != nil {
		in.Note = *r.Body.Note
	}
	sl, err := s.Applications.CreateSlot(ctx, p, r.OrgId, r.ListingId, in)
	if err != nil {
		return nil, err
	}
	return gen.CreateViewingSlot201JSONResponse(slotDTO(db.SlotsWithAvailabilityRow{ID: sl.ID, StartsAt: sl.StartsAt,
		DurationMin: sl.DurationMin, Capacity: sl.Capacity, Note: sl.Note})), nil
}

// DeleteViewingSlot implements DELETE /v1/orgs/{orgId}/viewing-slots/{slotId}.
func (s *Server) DeleteViewingSlot(ctx context.Context, r gen.DeleteViewingSlotRequestObject) (gen.DeleteViewingSlotResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Applications.DeleteSlot(ctx, p, r.OrgId, r.SlotId); err != nil {
		return nil, err
	}
	return gen.DeleteViewingSlot204Response{}, nil
}

// ---------------------------------------------------------------------------
// Groups.

func (s *Server) groupDTO(g applications.Group) gen.Group {
	out := gen.Group{Id: g.ID, Name: g.Name, Joined: g.Joined, CreatedAt: g.CreatedAt, Members: []gen.GroupMember{},
		Messages: []gen.GroupMessage{}}
	for _, m := range g.Members {
		out.Members = append(out.Members, gen.GroupMember{Id: m.ID, UserId: m.UserID, InvitedEmail: m.InvitedEmail,
			Role: gen.GroupMemberRole(m.Role), Joined: m.JoinedAt != nil, DisplayName: m.DisplayName,
			VerificationLevel: gen.VerificationLevel(m.VerificationLevel)})
	}
	for _, m := range g.Messages {
		out.Messages = append(out.Messages, gen.GroupMessage{Id: m.ID, SenderId: m.SenderID, SenderName: m.SenderName,
			Body: m.Body, CreatedAt: m.CreatedAt})
	}
	return out
}

// ListMyGroups implements GET /v1/groups.
func (s *Server) ListMyGroups(ctx context.Context, _ gen.ListMyGroupsRequestObject) (gen.ListMyGroupsResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	rows, err := s.Applications.MyGroups(ctx, p)
	if err != nil {
		return nil, err
	}
	out := gen.ListMyGroups200JSONResponse{}
	for _, g := range rows {
		out = append(out, gen.GroupSummary{Id: g.ID, Name: g.Name, Role: gen.GroupSummaryRole(g.Role), Joined: g.JoinedAt != nil,
			Members: int(g.Members), CreatedAt: g.CreatedAt})
	}
	return out, nil
}

// CreateGroup implements POST /v1/groups.
func (s *Server) CreateGroup(ctx context.Context, r gen.CreateGroupRequestObject) (gen.CreateGroupResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	var invites []string
	if r.Body.Invite != nil {
		for _, e := range *r.Body.Invite {
			invites = append(invites, string(e))
		}
	}
	id, err := s.Applications.CreateGroup(ctx, p, r.Body.Name, invites)
	if err != nil {
		return nil, err
	}
	g, err := s.Applications.Group(ctx, p, id)
	if err != nil {
		return nil, err
	}
	return gen.CreateGroup201JSONResponse(s.groupDTO(g)), nil
}

// GetGroup implements GET /v1/groups/{groupId}.
func (s *Server) GetGroup(ctx context.Context, r gen.GetGroupRequestObject) (gen.GetGroupResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	g, err := s.Applications.Group(ctx, p, r.GroupId)
	if err != nil {
		return nil, err
	}
	return gen.GetGroup200JSONResponse(s.groupDTO(g)), nil
}

// InviteToGroup implements POST /v1/groups/{groupId}/invitations.
func (s *Server) InviteToGroup(ctx context.Context, r gen.InviteToGroupRequestObject) (gen.InviteToGroupResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Applications.Invite(ctx, p, r.GroupId, string(r.Body.Email)); err != nil {
		return nil, err
	}
	return gen.InviteToGroup204Response{}, nil
}

// JoinGroup implements POST /v1/groups/{groupId}/join.
func (s *Server) JoinGroup(ctx context.Context, r gen.JoinGroupRequestObject) (gen.JoinGroupResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Applications.Join(ctx, p, r.GroupId); err != nil {
		return nil, err
	}
	return gen.JoinGroup204Response{}, nil
}

// LeaveGroup implements POST /v1/groups/{groupId}/leave.
func (s *Server) LeaveGroup(ctx context.Context, r gen.LeaveGroupRequestObject) (gen.LeaveGroupResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Applications.Leave(ctx, p, r.GroupId); err != nil {
		return nil, err
	}
	return gen.LeaveGroup204Response{}, nil
}

// SendGroupMessage implements POST /v1/groups/{groupId}/messages.
func (s *Server) SendGroupMessage(ctx context.Context, r gen.SendGroupMessageRequestObject) (gen.SendGroupMessageResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	m, err := s.Applications.SendGroupMessage(ctx, p, r.GroupId, r.Body.Body)
	if err != nil {
		return nil, err
	}
	return gen.SendGroupMessage201JSONResponse{Id: m.ID, SenderId: m.SenderID, Body: m.Body, CreatedAt: m.CreatedAt,
		SenderName: m.SenderName}, nil
}

// ---------------------------------------------------------------------------
// Roommates and passport.

func roommateDTO(p applications.Profile) gen.RoommateProfile {
	out := gen.RoommateProfile{Active: p.Active, BudgetMax: p.BudgetMax, HasRoom: p.HasRoom, About: &p.About,
		AdminPath: &p.AdminPath, AreaLabel: &p.AreaLabel, Lifestyle: []gen.RoommateProfileLifestyle{}}
	for _, l := range p.Lifestyle {
		out.Lifestyle = append(out.Lifestyle, gen.RoommateProfileLifestyle(l))
	}
	if p.MoveIn != nil {
		out.MoveIn = &openapi_types.Date{Time: *p.MoveIn}
	}
	return out
}

func matchDTOs(rows []applications.Match) []gen.RoommateMatch {
	out := []gen.RoommateMatch{}
	for _, m := range rows {
		prof := applications.Profile{Active: true, AdminPath: m.AdminPath, AreaLabel: m.AreaLabel, BudgetMax: m.BudgetMax,
			About: m.About, Lifestyle: m.Lifestyle, HasRoom: m.HasRoom}
		if m.MoveIn.Valid {
			t := m.MoveIn.Time
			prof.MoveIn = &t
		}
		out = append(out, gen.RoommateMatch{UserId: m.UserID, DisplayName: m.DisplayName,
			VerificationLevel: gen.VerificationLevel(m.VerificationLevel), Profile: roommateDTO(prof), Score: m.Score})
	}
	return out
}

// GetRoommateProfile implements GET /v1/me/roommate-profile.
func (s *Server) GetRoommateProfile(ctx context.Context, _ gen.GetRoommateProfileRequestObject) (gen.GetRoommateProfileResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	prof, err := s.Applications.RoommateProfile(ctx, p)
	if err != nil {
		return nil, err
	}
	if prof == nil {
		return nil, apperr.NotFound("profile_not_found", "no roommate profile yet")
	}
	return gen.GetRoommateProfile200JSONResponse(roommateDTO(*prof)), nil
}

// SaveRoommateProfile implements PUT /v1/me/roommate-profile.
func (s *Server) SaveRoommateProfile(ctx context.Context, r gen.SaveRoommateProfileRequestObject) (gen.SaveRoommateProfileResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	in := applications.Profile{Active: r.Body.Active, BudgetMax: r.Body.BudgetMax, HasRoom: r.Body.HasRoom}
	if r.Body.AdminPath != nil {
		in.AdminPath = *r.Body.AdminPath
	}
	if r.Body.AreaLabel != nil {
		in.AreaLabel = *r.Body.AreaLabel
	}
	if r.Body.About != nil {
		in.About = *r.Body.About
	}
	if r.Body.MoveIn != nil {
		t := r.Body.MoveIn.Time
		in.MoveIn = &t
	}
	for _, l := range r.Body.Lifestyle {
		in.Lifestyle = append(in.Lifestyle, string(l))
	}
	prof, err := s.Applications.SaveRoommateProfile(ctx, p, in)
	if err != nil {
		return nil, err
	}
	return gen.SaveRoommateProfile200JSONResponse(roommateDTO(*prof)), nil
}

// ListRoommates implements GET /v1/roommates.
func (s *Server) ListRoommates(ctx context.Context, r gen.ListRoommatesRequestObject) (gen.ListRoommatesResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	area := ""
	if r.Params.Area != nil {
		area = *r.Params.Area
	}
	rows, err := s.Applications.Roommates(ctx, p, area)
	if err != nil {
		return nil, err
	}
	return gen.ListRoommates200JSONResponse(matchDTOs(rows)), nil
}

// ListListingRoommates implements GET /v1/orgs/{orgId}/listings/{listingId}/roommates.
func (s *Server) ListListingRoommates(ctx context.Context, r gen.ListListingRoommatesRequestObject) (gen.ListListingRoommatesResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	rows, err := s.Applications.ListingRoommates(ctx, p, r.OrgId, r.ListingId)
	if err != nil {
		return nil, err
	}
	return gen.ListListingRoommates200JSONResponse(matchDTOs(rows)), nil
}

func passportDTO(pp applications.Passport) gen.Passport {
	return gen.Passport{VerificationLevel: gen.VerificationLevel(pp.Verification), IncomeProofName: pp.IncomeFilename,
		IncomeUploadedAt: pp.IncomeAt, Insolvency: gen.PassportInsolvency(pp.ISIRStatus), InsolvencyCheckedAt: pp.ISIRCheckedAt}
}

// GetPassport implements GET /v1/me/passport.
func (s *Server) GetPassport(ctx context.Context, _ gen.GetPassportRequestObject) (gen.GetPassportResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	pp, err := s.Applications.Passport(ctx, p)
	if err != nil {
		return nil, err
	}
	return gen.GetPassport200JSONResponse(passportDTO(pp)), nil
}

// CreateIncomeUpload implements POST /v1/me/passport/income.
func (s *Server) CreateIncomeUpload(ctx context.Context, r gen.CreateIncomeUploadRequestObject) (gen.CreateIncomeUploadResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	u, err := s.Applications.CreateIncomeUpload(ctx, p, string(r.Body.ContentType), r.Body.SizeBytes)
	if err != nil {
		return nil, err
	}
	return gen.CreateIncomeUpload201JSONResponse{Key: u.Key, UploadUrl: u.UploadURL}, nil
}

// CompleteIncomeUpload implements POST /v1/me/passport/income/complete.
func (s *Server) CompleteIncomeUpload(ctx context.Context, r gen.CompleteIncomeUploadRequestObject) (gen.CompleteIncomeUploadResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Applications.CompleteIncomeUpload(ctx, p, r.Body.Key, r.Body.Filename); err != nil {
		return nil, err
	}
	pp, err := s.Applications.Passport(ctx, p)
	if err != nil {
		return nil, err
	}
	return gen.CompleteIncomeUpload200JSONResponse(passportDTO(pp)), nil
}

// DeleteIncomeProof implements DELETE /v1/me/passport/income.
func (s *Server) DeleteIncomeProof(ctx context.Context, _ gen.DeleteIncomeProofRequestObject) (gen.DeleteIncomeProofResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Applications.DeleteIncomeProof(ctx, p); err != nil {
		return nil, err
	}
	return gen.DeleteIncomeProof204Response{}, nil
}

// CheckInsolvency implements POST /v1/me/passport/insolvency-check.
func (s *Server) CheckInsolvency(ctx context.Context, _ gen.CheckInsolvencyRequestObject) (gen.CheckInsolvencyResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if _, err := s.Applications.CheckInsolvency(ctx, p); err != nil {
		return nil, err
	}
	pp, err := s.Applications.Passport(ctx, p)
	if err != nil {
		return nil, err
	}
	return gen.CheckInsolvency200JSONResponse(passportDTO(pp)), nil
}
