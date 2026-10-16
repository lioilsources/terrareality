package leasing

import (
	"testing"

	"github.com/jackc/pgx/v5/pgtype"

	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
)

func TestCheckLandlordReason(t *testing.T) {
	indefinite := db.Lease{Template: "byt_doba_neurcita"}
	fixed := db.Lease{Template: "byt_doba_urcita", EndsOn: pgtype.Date{Valid: true}}
	cases := []struct {
		name string
		l    db.Lease
		in   NoticeInput
		code string
	}{
		{"no reason", indefinite, NoticeInput{}, "landlord_notice_reason_required"},
		{"unknown reason", indefinite, NoticeInput{Reason: "dislike"}, "landlord_notice_reason_required"},
		{"breach", fixed, NoticeInput{Reason: NoticeGrossBreach}, ""},
		{"conviction", fixed, NoticeInput{Reason: NoticeConviction}, ""},
		{"public interest", fixed, NoticeInput{Reason: NoticePublicInterest}, ""},
		{"other without explanation", indefinite, NoticeInput{Reason: NoticeOtherSerious, Explanation: "  "}, "landlord_notice_reason_required"},
		{"other with explanation", indefinite, NoticeInput{Reason: NoticeOtherSerious, Explanation: "Opakované rušení sousedů."}, ""},
		{"own use, indefinite", indefinite, NoticeInput{Reason: NoticeOwnUse}, ""},
		{"own use, fixed term", fixed, NoticeInput{Reason: NoticeOwnUse}, "notice_reason_not_applicable"},
	}
	for _, c := range cases {
		err := checkLandlordReason(c.l, c.in)
		if c.code == "" {
			if err != nil {
				t.Errorf("%s: %v", c.name, err)
			}
			continue
		}
		if e, ok := apperr.As(err); !ok || e.Code != c.code || e.Status != 422 {
			t.Errorf("%s: %v, want %s", c.name, err, c.code)
		}
	}
}

func TestSignProvidersFollowSigners(t *testing.T) {
	s := &Service{Signers: map[string]SignatureProvider{"mock": MockSigner{}}}
	got := s.SignProviders()
	if len(got) != 1 || got[0] != (ProviderInfo{ID: "mock", Level: LevelSimple}) {
		t.Fatalf("providers %+v", got)
	}
	s.Signers["bankid_sign"] = MockSigner{}
	if got = s.SignProviders(); len(got) != 2 || got[0].ID != "bankid_sign" || got[0].Level != LevelQualified {
		t.Fatalf("preferred first %+v", got)
	}
	if got = (&Service{}).SignProviders(); len(got) != 0 {
		t.Fatalf("no signers %+v", got)
	}
}
