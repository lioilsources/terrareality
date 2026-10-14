# LLM on the DGX Spark (AiStack)

TerraReality does not run its own inference stack. It calls the AiStack LiteLLM gateway on the Spark
over the LAN (`LLM_BASE_URL=http://<spark-lan-ip>:8080/v1`, dummy API key). The public Cloudflare
endpoint is not used by apps without the owner's approval.

## Routes (agreed with the AiStack operator, 2026-10-14)

| Use | Route | Status |
|---|---|---|
| Attribute extraction, listing texts, chat-first search (tool calling, JSON) | `openclaw-default` (Qwen3.6-35B-A3B, 64k context) | in use |
| Listing embeddings (1024 dim, pgvector) | `shop-embed` (bge-m3) or a CPU sidecar | not running; waiting for the owner's decision. Until then `EMBEDDINGS_MODEL` stays empty and similar-listing features are off |
| Photo tagging in `services/vision` | `vl` (Qwen2.5-VL-7B, ~22 GB) | not running; waiting for a decision when it may run. Vision stays in mock mode |

There are no `terra*` routes. Route changes are pull requests to the AiStack repo
(`deploy/litellm_config.yaml`); deploying them (pull + LiteLLM restart on the Spark) is done by the
operator or the owner, never by this project.

## Operating rules

- Schedule: LLM routes are up 13:00–07:00; 07:00–13:00 the GPU belongs to ComfyUI and every LLM
  call fails. AI suggestions are River jobs with retries spanning about 7 hours, so they finish
  once the window opens. The UI shows "generating" meanwhile.
- At most 4 parallel interactive requests from TerraReality.
- Batch jobs (bulk extraction, tagging, embedding backfills) are announced to the operator first
  (window, count, estimate), are resumable by id and stop at 06:57.
- No own containers on the Spark without the owner's approval.

Every AI output is a suggestion that a human approves (ADR 0003).
