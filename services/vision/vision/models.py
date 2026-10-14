from typing import Literal

from pydantic import BaseModel, Field, HttpUrl, field_validator

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


class Region(BaseModel):
    """Normalized bounding box (0..1) of a face or a licence plate."""

    label: Literal["face", "licence_plate", "person", "other"] = "other"
    box: tuple[float, float, float, float]

    @field_validator("box")
    @classmethod
    def _clamp(cls, v: tuple[float, float, float, float]) -> tuple[float, float, float, float]:
        x0, y0, x1, y1 = (min(1.0, max(0.0, float(c))) for c in v)
        if x1 <= x0 or y1 <= y0:
            raise ValueError("empty box")
        return (x0, y0, x1, y1)


class AnalyzeResponse(BaseModel):
    """Suggestions only. A human confirms them before anything is published
    (docs/ADR/0003-human-in-the-loop-ai.md)."""

    room_type: RoomType
    tags: list[str] = Field(default_factory=list)
    caption: str = ""
    needs_privacy_review: bool = False
    regions: list[Region] = Field(default_factory=list)
    model: str
    mock: bool


class RedactRequest(BaseModel):
    image_url: HttpUrl
    # Empty list blurs the whole image (fallback when the model gave no boxes).
    regions: list[Region] = Field(default_factory=list)
