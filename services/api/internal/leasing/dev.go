package leasing

import (
	"encoding/json"
	"net/http"
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
