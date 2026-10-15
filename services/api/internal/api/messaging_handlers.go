package api

import (
	"context"
	"encoding/json"
	"slices"

	"github.com/google/uuid"

	"github.com/terrareality/terrareality/services/api/internal/api/gen"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/listing"
	"github.com/terrareality/terrareality/services/api/internal/messaging"
	"github.com/terrareality/terrareality/services/api/internal/realtime"
)

// convert maps between service and API types that share a JSON shape.
func convert[T any](in any) T {
	var out T
	b, _ := json.Marshal(in)
	_ = json.Unmarshal(b, &out)
	return out
}

func (s *Server) conversationDTO(c messaging.Conversation) gen.Conversation {
	out := gen.Conversation{Id: c.ID, ListingId: c.ListingID, OrgId: c.OrgID, OrgName: c.OrgName, SeekerId: c.SeekerID,
		SeekerName: c.SeekerName, ListingTitle: i18nDTO(c.ListingTitle), Role: gen.ConversationRole(c.Role),
		LastMessageAt: c.LastMessageAt, LastMessage: c.LastBody, LastSenderId: c.LastSenderID, Unread: int(c.Unread),
		Blocked: c.BlockedAt != nil, BlockedByMe: c.BlockedByMe, CreatedAt: c.CreatedAt}
	if c.CoverKey != nil {
		u := s.Listings.PhotoURLs(*c.CoverKey, c.CoverOrientation)["thumb"]
		out.CoverUrl = &u
	}
	return out
}

func messageDTO(m messaging.Message) gen.Message { return convert[gen.Message](m) }

// ListConversations implements GET /v1/conversations.
func (s *Server) ListConversations(ctx context.Context, r gen.ListConversationsRequestObject) (gen.ListConversationsResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	rows, err := s.Messages.List(ctx, p, r.Params.OrgId, r.Params.As != nil)
	if err != nil {
		return nil, err
	}
	out := gen.ListConversations200JSONResponse{}
	for _, c := range rows {
		out = append(out, s.conversationDTO(c))
	}
	return out, nil
}

// StartConversation implements POST /v1/conversations.
func (s *Server) StartConversation(ctx context.Context, r gen.StartConversationRequestObject) (gen.StartConversationResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.limit(ctx, "conv:"+p.UserID.String()); err != nil {
		return nil, err
	}
	var answers map[string]string
	if r.Body.PrescreenAnswers != nil {
		answers = *r.Body.PrescreenAnswers
	}
	id, msg, err := s.Messages.Start(ctx, p, r.Body.ListingId, r.Body.Body, answers)
	if err != nil {
		return nil, err
	}
	return gen.StartConversation201JSONResponse{ConversationId: id, Message: messageDTO(msg)}, nil
}

// GetConversation implements GET /v1/conversations/{conversationId}.
func (s *Server) GetConversation(ctx context.Context, r gen.GetConversationRequestObject) (gen.GetConversationResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	v, err := s.Messages.Get(ctx, p, r.ConversationId)
	if err != nil {
		return nil, err
	}
	prescreen := convert[[]gen.PrescreenAnswer](v.Prescreen)
	if prescreen == nil {
		prescreen = []gen.PrescreenAnswer{}
	}
	return gen.GetConversation200JSONResponse{Conversation: s.conversationDTO(v.Conversation), PeerReadAt: v.PeerReadAt,
		Prescreen: prescreen}, nil
}

// ListMessages implements GET /v1/conversations/{conversationId}/messages.
func (s *Server) ListMessages(ctx context.Context, r gen.ListMessagesRequestObject) (gen.ListMessagesResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	var limit int32
	if r.Params.Limit != nil {
		limit = int32(*r.Params.Limit)
	}
	msgs, err := s.Messages.Messages(ctx, p, r.ConversationId, r.Params.Before, limit)
	if err != nil {
		return nil, err
	}
	out := gen.ListMessages200JSONResponse{}
	for _, m := range msgs {
		out = append(out, messageDTO(m))
	}
	return out, nil
}

// SendMessage implements POST /v1/conversations/{conversationId}/messages.
func (s *Server) SendMessage(ctx context.Context, r gen.SendMessageRequestObject) (gen.SendMessageResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	body := ""
	if r.Body.Body != nil {
		body = *r.Body.Body
	}
	var ids []uuid.UUID
	if r.Body.AttachmentIds != nil {
		ids = *r.Body.AttachmentIds
	}
	msg, err := s.Messages.Send(ctx, p, r.ConversationId, body, ids)
	if err != nil {
		return nil, err
	}
	return gen.SendMessage201JSONResponse{ConversationId: r.ConversationId, Message: messageDTO(msg)}, nil
}

// MarkConversationRead implements POST /v1/conversations/{conversationId}/read.
func (s *Server) MarkConversationRead(ctx context.Context, r gen.MarkConversationReadRequestObject) (gen.MarkConversationReadResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Messages.MarkRead(ctx, p, r.ConversationId); err != nil {
		return nil, err
	}
	return gen.MarkConversationRead204Response{}, nil
}

// SetConversationBlocked implements PUT /v1/conversations/{conversationId}/block.
func (s *Server) SetConversationBlocked(ctx context.Context, r gen.SetConversationBlockedRequestObject) (gen.SetConversationBlockedResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Messages.SetBlocked(ctx, p, r.ConversationId, r.Body.Blocked); err != nil {
		return nil, err
	}
	return gen.SetConversationBlocked204Response{}, nil
}

// ReportConversation implements POST /v1/conversations/{conversationId}/reports.
func (s *Server) ReportConversation(ctx context.Context, r gen.ReportConversationRequestObject) (gen.ReportConversationResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	note := ""
	if r.Body.Note != nil {
		note = *r.Body.Note
	}
	id, err := s.Messages.Report(ctx, p, r.ConversationId, r.Body.MessageId, string(r.Body.Reason), note)
	if err != nil {
		return nil, err
	}
	return gen.ReportConversation201JSONResponse{Id: id}, nil
}

// CreateAttachmentUpload implements POST /v1/conversations/{conversationId}/attachments.
func (s *Server) CreateAttachmentUpload(ctx context.Context, r gen.CreateAttachmentUploadRequestObject) (gen.CreateAttachmentUploadResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	u, err := s.Messages.CreateUpload(ctx, p, r.ConversationId, r.Body.Filename, string(r.Body.ContentType), r.Body.SizeBytes)
	if err != nil {
		return nil, err
	}
	return gen.CreateAttachmentUpload201JSONResponse{Id: u.ID, UploadUrl: u.UploadURL, ExpiresAt: u.ExpiresAt}, nil
}

// CompleteAttachmentUpload implements POST /v1/attachments/{attachmentId}/complete.
func (s *Server) CompleteAttachmentUpload(ctx context.Context, r gen.CompleteAttachmentUploadRequestObject) (gen.CompleteAttachmentUploadResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	a, err := s.Messages.CompleteUpload(ctx, p, r.AttachmentId)
	if err != nil {
		return nil, err
	}
	return gen.CompleteAttachmentUpload200JSONResponse(convert[gen.Attachment](a)), nil
}

// RealtimeToken implements POST /v1/realtime/token.
func (s *Server) RealtimeToken(ctx context.Context, _ gen.RealtimeTokenRequestObject) (gen.RealtimeTokenResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	tok, exp, url := s.Messages.RealtimeToken(p)
	return gen.RealtimeToken200JSONResponse{Url: url, Token: tok, ExpiresAt: exp, Channel: realtime.UserChannel(p.UserID)}, nil
}

// ConversationRealtimeToken implements POST /v1/conversations/{conversationId}/realtime-token.
func (s *Server) ConversationRealtimeToken(ctx context.Context, r gen.ConversationRealtimeTokenRequestObject) (gen.ConversationRealtimeTokenResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	tok, ch, exp, err := s.Messages.SubscribeToken(ctx, p, r.ConversationId)
	if err != nil {
		return nil, err
	}
	return gen.ConversationRealtimeToken200JSONResponse{Channel: ch, Token: tok, ExpiresAt: exp}, nil
}

func templateDTO(t db.ReplyTemplate) gen.ReplyTemplate {
	return gen.ReplyTemplate{Id: t.ID, Title: t.Title, Body: t.Body, UpdatedAt: t.UpdatedAt}
}

// ListReplyTemplates implements GET /v1/orgs/{orgId}/reply-templates.
func (s *Server) ListReplyTemplates(ctx context.Context, r gen.ListReplyTemplatesRequestObject) (gen.ListReplyTemplatesResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	rows, err := s.Messages.Templates(ctx, p, r.OrgId)
	if err != nil {
		return nil, err
	}
	out := gen.ListReplyTemplates200JSONResponse{}
	for _, t := range rows {
		out = append(out, templateDTO(t))
	}
	return out, nil
}

// CreateReplyTemplate implements POST /v1/orgs/{orgId}/reply-templates.
func (s *Server) CreateReplyTemplate(ctx context.Context, r gen.CreateReplyTemplateRequestObject) (gen.CreateReplyTemplateResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	t, err := s.Messages.SaveTemplate(ctx, p, r.OrgId, nil, r.Body.Title, r.Body.Body)
	if err != nil {
		return nil, err
	}
	return gen.CreateReplyTemplate201JSONResponse(templateDTO(t)), nil
}

// UpdateReplyTemplate implements PUT /v1/orgs/{orgId}/reply-templates/{templateId}.
func (s *Server) UpdateReplyTemplate(ctx context.Context, r gen.UpdateReplyTemplateRequestObject) (gen.UpdateReplyTemplateResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	id := r.TemplateId
	t, err := s.Messages.SaveTemplate(ctx, p, r.OrgId, &id, r.Body.Title, r.Body.Body)
	if err != nil {
		return nil, err
	}
	return gen.UpdateReplyTemplate200JSONResponse(templateDTO(t)), nil
}

// DeleteReplyTemplate implements DELETE /v1/orgs/{orgId}/reply-templates/{templateId}.
func (s *Server) DeleteReplyTemplate(ctx context.Context, r gen.DeleteReplyTemplateRequestObject) (gen.DeleteReplyTemplateResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Messages.DeleteTemplate(ctx, p, r.OrgId, r.TemplateId); err != nil {
		return nil, err
	}
	return gen.DeleteReplyTemplate204Response{}, nil
}

// SetListingPrescreen implements PUT /v1/orgs/{orgId}/listings/{listingId}/prescreen.
func (s *Server) SetListingPrescreen(ctx context.Context, r gen.SetListingPrescreenRequestObject) (gen.SetListingPrescreenResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	qs, err := s.Messages.SetPrescreen(ctx, p, r.OrgId, r.ListingId, convert[[]messaging.PrescreenQuestion](*r.Body))
	if err != nil {
		return nil, err
	}
	return gen.SetListingPrescreen200JSONResponse(prescreenDTO(qs)), nil
}

func prescreenDTO(qs []messaging.PrescreenQuestion) []gen.PrescreenQuestion {
	out := convert[[]gen.PrescreenQuestion](qs)
	if out == nil {
		out = []gen.PrescreenQuestion{}
	}
	return out
}

// prescreenOf decodes the stored questions of a listing.
func prescreenOf(raw []byte) []gen.PrescreenQuestion {
	var qs []messaging.PrescreenQuestion
	_ = json.Unmarshal(raw, &qs)
	return prescreenDTO(qs)
}

// ListNotifications implements GET /v1/me/notifications.
func (s *Server) ListNotifications(ctx context.Context, _ gen.ListNotificationsRequestObject) (gen.ListNotificationsResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	rows, unread, err := s.Messages.Notifications(ctx, p)
	if err != nil {
		return nil, err
	}
	out := gen.ListNotifications200JSONResponse{Items: []gen.Notification{}, Unread: int(unread)}
	for _, n := range rows {
		out.Items = append(out.Items, gen.Notification{Id: n.ID, Kind: n.Kind, Data: objectOf(n.Data), Link: n.Link,
			ReadAt: n.ReadAt, CreatedAt: n.CreatedAt})
	}
	return out, nil
}

// MarkNotificationsRead implements POST /v1/me/notifications/read.
func (s *Server) MarkNotificationsRead(ctx context.Context, r gen.MarkNotificationsReadRequestObject) (gen.MarkNotificationsReadResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	var id *uuid.UUID
	if r.Body != nil {
		id = r.Body.Id
	}
	if err := s.Messages.MarkNotificationsRead(ctx, p, id); err != nil {
		return nil, err
	}
	return gen.MarkNotificationsRead204Response{}, nil
}

// GetNotificationPreferences implements GET /v1/me/notification-preferences.
func (s *Server) GetNotificationPreferences(ctx context.Context, _ gen.GetNotificationPreferencesRequestObject) (gen.GetNotificationPreferencesResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	prefs, err := s.Messages.GetPreferences(ctx, p)
	if err != nil {
		return nil, err
	}
	return gen.GetNotificationPreferences200JSONResponse(convert[gen.NotificationPreferences](prefs)), nil
}

// SetNotificationPreferences implements PUT /v1/me/notification-preferences.
func (s *Server) SetNotificationPreferences(ctx context.Context, r gen.SetNotificationPreferencesRequestObject) (gen.SetNotificationPreferencesResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	prefs, err := s.Messages.SetPreferences(ctx, p, convert[messaging.Preferences](r.Body))
	if err != nil {
		return nil, err
	}
	return gen.SetNotificationPreferences200JSONResponse(convert[gen.NotificationPreferences](prefs)), nil
}

func deviceDTO(d db.PushDevice) gen.PushDevice {
	return gen.PushDevice{Id: d.ID, Platform: gen.PushDevicePlatform(d.Platform), Label: d.Label, CreatedAt: d.CreatedAt,
		LastSeenAt: d.LastSeenAt}
}

// ListPushDevices implements GET /v1/me/push-devices.
func (s *Server) ListPushDevices(ctx context.Context, _ gen.ListPushDevicesRequestObject) (gen.ListPushDevicesResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	rows, err := s.Messages.Devices(ctx, p)
	if err != nil {
		return nil, err
	}
	out := gen.ListPushDevices200JSONResponse{}
	for _, d := range rows {
		out = append(out, deviceDTO(d))
	}
	return out, nil
}

// RegisterPushDevice implements POST /v1/me/push-devices.
func (s *Server) RegisterPushDevice(ctx context.Context, r gen.RegisterPushDeviceRequestObject) (gen.RegisterPushDeviceResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	var keys json.RawMessage
	if r.Body.Keys != nil {
		keys, _ = json.Marshal(r.Body.Keys)
	}
	label := ""
	if r.Body.Label != nil {
		label = *r.Body.Label
	}
	d, err := s.Messages.RegisterDevice(ctx, p, string(r.Body.Platform), r.Body.Token, keys, label)
	if err != nil {
		return nil, err
	}
	return gen.RegisterPushDevice201JSONResponse(deviceDTO(d)), nil
}

// DeletePushDevice implements DELETE /v1/me/push-devices/{deviceId}.
func (s *Server) DeletePushDevice(ctx context.Context, r gen.DeletePushDeviceRequestObject) (gen.DeletePushDeviceResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Messages.DeleteDevice(ctx, p, r.DeviceId); err != nil {
		return nil, err
	}
	return gen.DeletePushDevice204Response{}, nil
}

func moderationDTO(c db.GetModerationCaseRow) gen.ModerationCase {
	out := gen.ModerationCase{Id: c.ID, Kind: gen.ModerationCaseKind(c.Kind), Source: gen.ModerationCaseSource(c.Source),
		ConversationId: c.ConversationID, ListingId: c.SubjectListingID,
		MessageId: c.MessageID, Reason: c.Reason, Note: c.Note, Status: gen.ModerationCaseStatus(c.Status),
		ReporterName: nonEmpty(c.ReporterName), ReporterEmail: nonEmpty(c.ReporterEmail), ReportedId: c.ReportedID,
		ReportedName: c.ReportedName, ReportedEmail: c.ReportedEmail, ListingTitle: i18nDTO(c.ListingTitle),
		MessageBody: c.MessageBody, AiStatus: gen.ModerationCaseAiStatus(c.AiStatus), DecisionNote: c.DecisionNote,
		CreatedAt: c.CreatedAt}
	if c.Kind == messaging.KindListing {
		anon := c.ReporterAnonymous
		out.ReporterAnonymous = &anon
	}
	if len(c.AiSuggestion) > 0 {
		sug := convert[gen.ModerationSuggestion](json.RawMessage(c.AiSuggestion))
		out.AiSuggestion = &sug
	}
	if c.Decision != nil {
		d := gen.ModerationVerdict(*c.Decision)
		out.Decision = &d
	}
	return out
}

// BackofficeListModeration implements GET /v1/backoffice/moderation.
func (s *Server) BackofficeListModeration(ctx context.Context, _ gen.BackofficeListModerationRequestObject) (gen.BackofficeListModerationResponseObject, error) {
	if _, err := s.staff(ctx); err != nil {
		return nil, err
	}
	rows, err := s.Messages.Queue(ctx)
	if err != nil {
		return nil, err
	}
	out := gen.BackofficeListModeration200JSONResponse{}
	for _, r := range rows {
		out = append(out, moderationDTO(db.GetModerationCaseRow(r)))
	}
	return out, nil
}

// BackofficeGetModeration implements GET /v1/backoffice/moderation/{caseId}.
func (s *Server) BackofficeGetModeration(ctx context.Context, r gen.BackofficeGetModerationRequestObject) (gen.BackofficeGetModerationResponseObject, error) {
	if _, err := s.staff(ctx); err != nil {
		return nil, err
	}
	c, err := s.Messages.Case(ctx, r.CaseId)
	if err != nil {
		return nil, err
	}
	out := gen.BackofficeGetModeration200JSONResponse{Case: moderationDTO(c.GetModerationCaseRow), Transcript: []gen.TranscriptMessage{}}
	for _, m := range c.Transcript {
		role := gen.ConversationRoleOwner
		if m.FromSeeker {
			role = gen.ConversationRoleSeeker
		}
		flags := m.Flags
		if flags == nil {
			flags = []string{}
		}
		out.Transcript = append(out.Transcript, gen.TranscriptMessage{Id: m.ID, Role: role, SenderName: m.SenderName,
			Body: m.Body, Flags: flags, Removed: m.RemovedAt != nil, CreatedAt: m.CreatedAt})
	}
	return out, nil
}

// BackofficeDecideModeration implements POST /v1/backoffice/moderation/{caseId}/decision.
func (s *Server) BackofficeDecideModeration(ctx context.Context, r gen.BackofficeDecideModerationRequestObject) (gen.BackofficeDecideModerationResponseObject, error) {
	p, err := s.staff(ctx)
	if err != nil {
		return nil, err
	}
	note := ""
	if r.Body.Note != nil {
		note = *r.Body.Note
	}
	decide := s.Messages.Decide
	if slices.Contains(listing.ReportDecisions, string(r.Body.Decision)) {
		decide = s.Listings.DecideReport // DSA listing report
	}
	if err := decide(ctx, p, r.CaseId, string(r.Body.Decision), note); err != nil {
		return nil, err
	}
	return gen.BackofficeDecideModeration204Response{}, nil
}

// GetPushConfig implements GET /v1/push/config.
func (s *Server) GetPushConfig(context.Context, gen.GetPushConfigRequestObject) (gen.GetPushConfigResponseObject, error) {
	return gen.GetPushConfig200JSONResponse{VapidPublicKey: s.VAPIDPublicKey}, nil
}

func nonEmpty(v string) *string {
	if v == "" {
		return nil
	}
	return &v
}

// ReportListing implements POST /v1/listings/{listingId}/reports (DSA
// notice; signed-in users and anonymous visitors).
func (s *Server) ReportListing(ctx context.Context, r gen.ReportListingRequestObject) (gen.ReportListingResponseObject, error) {
	in := listing.ReportInput{Reason: string(r.Body.Reason), Explanation: r.Body.Explanation}
	if r.Body.Email != nil {
		in.Email = string(*r.Body.Email)
	}
	if r.Body.Name != nil {
		in.Name = *r.Body.Name
	}
	if r.Body.Locale != nil {
		in.Locale = string(*r.Body.Locale)
	}
	id, err := s.Listings.Report(ctx, auth.FromContext(ctx), r.ListingId, in)
	if err != nil {
		return nil, err
	}
	return gen.ReportListing201JSONResponse{Id: id}, nil
}
