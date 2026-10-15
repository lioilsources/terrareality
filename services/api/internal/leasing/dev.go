package leasing

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/terrareality/terrareality/services/api/internal/db"
)

// DevBankHandler injects a transaction into the mock bank and syncs the
// connection at once (dev/test only: E2E "a simulated bank transaction is
// matched"). Mounted at /dev/bank/transactions when the mock bank is active.
func (s *Service) DevBankHandler(mock *MockBank) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "POST only", http.StatusMethodNotAllowed)
			return
		}
		var in struct {
			ConnectionID   uuid.UUID `json:"connection_id"`
			Amount         int64     `json:"amount"`
			VariableSymbol string    `json:"variable_symbol"`
			SpecificSymbol string    `json:"specific_symbol"`
			Counterparty   string    `json:"counterparty"`
		}
		if err := json.NewDecoder(r.Body).Decode(&in); err != nil || in.Amount == 0 {
			http.Error(w, "connection_id and amount are required", http.StatusBadRequest)
			return
		}
		conn, err := db.New(s.Pool).GetBankConnection(r.Context(), in.ConnectionID)
		if err != nil {
			http.Error(w, "unknown connection", http.StatusNotFound)
			return
		}
		mock.Add(conn.AccountID, Transaction{ExternalID: uuid.NewString(), BookedOn: s.now(), Amount: in.Amount,
			Currency: "CZK", VariableSymbol: in.VariableSymbol, SpecificSymbol: in.SpecificSymbol,
			CounterpartyName: in.Counterparty, Remittance: "VS " + in.VariableSymbol + " SS " + in.SpecificSymbol})
		res, err := s.Sync(r.Context(), conn.ID)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{"new": res.New, "matched": res.Matched, "suggested": res.Suggested,
			"at": time.Now().UTC()})
	})
}

// DevEscalateHandler fires the D+7 escalation of a lease's oldest unpaid
// due date at once, as the workflow timer would (dev/test only: E2E "an
// escalation raises the risk score"). Mounted at /dev/leases/{id}/escalate.
func (s *Service) DevEscalateHandler() http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rest, ok := strings.CutSuffix(strings.TrimPrefix(r.URL.Path, "/dev/leases/"), "/escalate")
		id, err := uuid.Parse(rest)
		if r.Method != http.MethodPost || !ok || err != nil {
			http.Error(w, "POST /dev/leases/{id}/escalate", http.StatusBadRequest)
			return
		}
		today := s.now()
		due, err := db.New(s.Pool).OldestOverdueDue(r.Context(), db.OldestOverdueDueParams{LeaseID: id, DueOn: date(&today)})
		if err != nil || !due.Valid {
			http.Error(w, "no unpaid share is due", http.StatusConflict)
			return
		}
		unpaid, err := (&Activities{S: s}).Remind(r.Context(), id, due.Time, "escalation")
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{"due_on": due.Time.Format("2006-01-02"), "unpaid": unpaid})
	})
}
