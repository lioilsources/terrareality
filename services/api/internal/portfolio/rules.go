package portfolio

import (
	"encoding/json"
	"fmt"
)

// Rules override jurisdiction defaults for a municipality or a group. Nil
// fields inherit. Reminder days are relative to the due date.
type Rules struct {
	ReminderBeforeDays *int `json:"reminder_before_days,omitempty"` // default 3 (D-3)
	OverdueDays        *int `json:"overdue_days,omitempty"`         // default 1 (D+1)
	EscalationDays     *int `json:"escalation_days,omitempty"`      // default 7 (D+7)
	DepositMonths      *int `json:"deposit_months,omitempty"`       // suggested deposit, capped by the jurisdiction
	NoticeMonths       *int `json:"notice_months,omitempty"`
}

// Defaults of the CZ jurisdiction (the workflow's built-in stages).
func Defaults() Rules {
	b, o, e, n := 3, 1, 7, 3
	return Rules{ReminderBeforeDays: &b, OverdueDays: &o, EscalationDays: &e, NoticeMonths: &n}
}

// Merge applies the set fields of over on top of r.
func (r Rules) Merge(over Rules) Rules {
	if over.ReminderBeforeDays != nil {
		r.ReminderBeforeDays = over.ReminderBeforeDays
	}
	if over.OverdueDays != nil {
		r.OverdueDays = over.OverdueDays
	}
	if over.EscalationDays != nil {
		r.EscalationDays = over.EscalationDays
	}
	if over.DepositMonths != nil {
		r.DepositMonths = over.DepositMonths
	}
	if over.NoticeMonths != nil {
		r.NoticeMonths = over.NoticeMonths
	}
	return r
}

// Validate checks the ranges of set fields.
func (r Rules) Validate(depositMaxMonths int) error {
	check := func(name string, v *int, lo, hi int) error {
		if v != nil && (*v < lo || *v > hi) {
			return fmt.Errorf("%s must be %d to %d", name, lo, hi)
		}
		return nil
	}
	if err := check("reminder_before_days", r.ReminderBeforeDays, 0, 14); err != nil {
		return err
	}
	if err := check("overdue_days", r.OverdueDays, 1, 14); err != nil {
		return err
	}
	if err := check("escalation_days", r.EscalationDays, 2, 30); err != nil {
		return err
	}
	if r.OverdueDays != nil && r.EscalationDays != nil && *r.EscalationDays <= *r.OverdueDays {
		return fmt.Errorf("escalation must come after the overdue reminder")
	}
	if err := check("deposit_months", r.DepositMonths, 0, depositMaxMonths); err != nil {
		return err
	}
	return check("notice_months", r.NoticeMonths, 1, 12)
}

// ParseRules decodes stored rules.
func ParseRules(b []byte) (Rules, error) {
	var r Rules
	if len(b) == 0 {
		return r, nil
	}
	err := json.Unmarshal(b, &r)
	return r, err
}
