package ai

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
)

// Tool is a function the model may call.
type Tool struct {
	Name        string         `json:"name"`
	Description string         `json:"description"`
	Parameters  map[string]any `json:"parameters"`
}

// ToolCall is one call the model made.
type ToolCall struct {
	Name      string
	Arguments json.RawMessage
}

// ChatMessage is one turn of a conversation.
type ChatMessage struct {
	Role    string `json:"role"` // system | user | assistant
	Content string `json:"content"`
}

// CallTools sends one request with tools and returns the calls the model
// chose plus any text. One round trip per user message keeps the shared
// Spark within its concurrency budget.
func (c *Client) CallTools(ctx context.Context, messages []ChatMessage, tools []Tool) ([]ToolCall, string, error) {
	type fn struct {
		Type     string `json:"type"`
		Function Tool   `json:"function"`
	}
	fns := make([]fn, len(tools))
	for i, t := range tools {
		fns[i] = fn{Type: "function", Function: t}
	}
	body, _ := json.Marshal(map[string]any{"model": c.Model, "messages": messages, "tools": fns, "tool_choice": "auto",
		"temperature": 0})
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.BaseURL+"/chat/completions", bytes.NewReader(body))
	if err != nil {
		return nil, "", err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+c.APIKey)
	res, err := c.HTTP.Do(req)
	if err != nil {
		return nil, "", fmt.Errorf("llm: %w", err)
	}
	defer res.Body.Close()
	raw, _ := io.ReadAll(io.LimitReader(res.Body, 4<<20))
	if res.StatusCode != http.StatusOK {
		return nil, "", fmt.Errorf("llm: status %d: %.300s", res.StatusCode, raw)
	}
	var cr struct {
		Choices []struct {
			Message struct {
				Content   string `json:"content"`
				ToolCalls []struct {
					Function struct {
						Name      string `json:"name"`
						Arguments string `json:"arguments"`
					} `json:"function"`
				} `json:"tool_calls"`
			} `json:"message"`
		} `json:"choices"`
	}
	if err := json.Unmarshal(raw, &cr); err != nil || len(cr.Choices) == 0 {
		return nil, "", fmt.Errorf("llm: unexpected response: %.300s", raw)
	}
	m := cr.Choices[0].Message
	var calls []ToolCall
	for _, tc := range m.ToolCalls {
		calls = append(calls, ToolCall{Name: tc.Function.Name, Arguments: json.RawMessage(tc.Function.Arguments)})
	}
	return calls, reThink.ReplaceAllString(m.Content, ""), nil
}
