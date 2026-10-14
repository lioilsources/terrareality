# LLM routes on the DGX Spark (AiStack)

TerraReality does not run its own inference stack. It uses the existing AiStack
LiteLLM gateway on the Spark (same pattern as ChatShop), reached over LAN/VPN.
Add these routes to the gateway config:

| Route | Purpose | Suggested backend |
|---|---|---|
| `terra` | chat-first search with tool calling, attribute extraction, listing text drafts | Qwen3-32B (vLLM), shares weights with `shop` |
| `terra-embed` | listing embeddings (1024 dim, pgvector) | BAAI/bge-m3, vLLM `--runner pooling` |
| `terra-vision` | photo tagging in `services/vision` | a vision-language model, e.g. Qwen2.5-VL-7B/32B |

Fallback chain: `terra -> fallback` (cloud model), enabled only behind the
`ai.cloud_fallback` feature flag. Every AI output is a suggestion that a human
approves (ADR 0003).

Clients only know `LLM_BASE_URL` (OpenAI-compatible) and the route names above,
so routes can be re-pointed without touching application code.
