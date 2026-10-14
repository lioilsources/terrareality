"""Photo analysis. Mock mode is deterministic so UI and tests run without a GPU."""

import hashlib
import json
import re

import httpx

from .config import Settings
from .models import TAG_VOCABULARY, AnalyzeRequest, AnalyzeResponse

ROOMS = ("kitchen", "bathroom", "bedroom", "living_room", "hallway", "balcony", "exterior", "floor_plan")
PRIVACY_TAGS = {"people_visible", "licence_plate_visible"}

PROMPT = """You label photos of rental flats for a listing platform.
Return ONLY a JSON object with keys:
  "room_type": one of {rooms} or "other",
  "tags": array of zero or more of {tags},
  "caption": one short sentence in {lang} describing the photo for a listing.
Tag "people_visible" if any person or face is visible and "licence_plate_visible" if a car plate is readable."""


def mock_analyze(req: AnalyzeRequest) -> AnalyzeResponse:
    digest = hashlib.sha256(str(req.image_url).encode()).digest()
    room = ROOMS[digest[0] % len(ROOMS)]
    tags = sorted({TAG_VOCABULARY[b % len(TAG_VOCABULARY)] for b in digest[1:4]} - PRIVACY_TAGS)
    caption = f"Mock: {room.replace('_', ' ')}" if req.locale == "en" else f"Mock: {room}"
    return AnalyzeResponse(room_type=room, tags=tags, caption=caption, model="mock", mock=True)


def parse_model_output(text: str, model: str) -> AnalyzeResponse:
    """Extract the JSON object from a model reply and clamp it to the vocabulary."""
    match = re.search(r"\{.*\}", text, re.DOTALL)
    if not match:
        raise ValueError("model reply contains no JSON object")
    data = json.loads(match.group(0))
    room = data.get("room_type", "other")
    if room not in ROOMS:
        room = "other"
    tags = sorted({t for t in data.get("tags", []) if t in TAG_VOCABULARY})
    return AnalyzeResponse(
        room_type=room,
        tags=tags,
        caption=str(data.get("caption", ""))[:300],
        needs_privacy_review=bool(PRIVACY_TAGS & set(tags)),
        model=model,
        mock=False,
    )


async def analyze(req: AnalyzeRequest, settings: Settings, client: httpx.AsyncClient) -> AnalyzeResponse:
    if settings.mock:
        return mock_analyze(req)
    prompt = PROMPT.format(
        rooms=", ".join(ROOMS), tags=", ".join(TAG_VOCABULARY), lang="Czech" if req.locale == "cs" else "English"
    )
    body = {
        "model": settings.vision_model,
        "temperature": 0,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {"type": "image_url", "image_url": {"url": str(req.image_url)}},
                ],
            }
        ],
    }
    resp = await client.post(
        f"{settings.llm_base_url.rstrip('/')}/chat/completions",
        json=body,
        headers={"Authorization": f"Bearer {settings.llm_api_key}"},
        timeout=settings.request_timeout_s,
    )
    resp.raise_for_status()
    text = resp.json()["choices"][0]["message"]["content"]
    return parse_model_output(text, settings.vision_model)
