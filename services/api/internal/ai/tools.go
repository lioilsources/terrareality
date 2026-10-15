package ai

import (
	"context"
	"encoding/json"
	"fmt"
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
	raw, _, err := c.post(ctx, func(model string) []byte {
		body, _ := json.Marshal(map[string]any{"model": model, "messages": messages, "tools": fns, "tool_choice": "auto",
			"temperature": 0})
		return body
	})
	if err != nil {
		return nil, "", err
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
