from typing import Literal

from pydantic import BaseModel, Field, HttpUrl

# Controlled vocabulary for photo tags. Tags outside this list are dropped so
# that downstream filters (catalog attributes) stay predictable.
TAG_VOCABULARY: tuple[str, ...] = (
    "kitchen",
    "bathroom",
    "bedroom",
    "living_room",
    "hallway",
    "balcony",
    "terrace",
    "garden",
    "garage",
    "cellar",
    "exterior",
    "floor_plan",
    "view",
    "furnished",
    "unfurnished",
    "dishwasher",
    "washing_machine",
    "bathtub",
    "shower",
    "fireplace",
    "air_conditioning",
    "elevator",
    "parking",
    "pets_visible",
    "people_visible",
    "licence_plate_visible",
)

RoomType = Literal[
    "kitchen",
    "bathroom",
    "bedroom",
    "living_room",
    "hallway",
    "balcony",
    "exterior",
    "floor_plan",
    "other",
]


class AnalyzeRequest(BaseModel):
    image_url: HttpUrl
    locale: Literal["cs", "en"] = "cs"


class AnalyzeResponse(BaseModel):
    """Suggestions only. A human confirms them before anything is published
    (docs/ADR/0003-human-in-the-loop-ai.md)."""

    room_type: RoomType
    tags: list[str] = Field(default_factory=list)
    caption: str = ""
    needs_privacy_review: bool = False
    model: str
    mock: bool
