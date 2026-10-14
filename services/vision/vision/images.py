"""Image download, downscaling for the model and privacy blur."""

import base64
import io

import httpx
from PIL import Image, ImageFilter, ImageOps

from .models import Region

MAX_DOWNLOAD = 25 * 1024 * 1024
MODEL_SIDE = 1024  # longest side sent to the vision model


async def fetch(url: str, client: httpx.AsyncClient, timeout: float) -> bytes:
    """Download an image (a short-lived presigned URL) with a size cap."""
    async with client.stream("GET", url, timeout=timeout) as resp:
        resp.raise_for_status()
        buf = bytearray()
        async for chunk in resp.aiter_bytes():
            buf.extend(chunk)
            if len(buf) > MAX_DOWNLOAD:
                raise ValueError("image too large")
    return bytes(buf)


def open_image(data: bytes) -> Image.Image:
    img = Image.open(io.BytesIO(data))
    img = ImageOps.exif_transpose(img)  # originals keep orientation separately; be safe
    return img.convert("RGB")


def to_data_url(data: bytes) -> str:
    """Downscale and encode as a JPEG data URL so the LLM never needs to reach our storage."""
    img = open_image(data)
    img.thumbnail((MODEL_SIDE, MODEL_SIDE))
    out = io.BytesIO()
    img.save(out, format="JPEG", quality=85)
    return "data:image/jpeg;base64," + base64.b64encode(out.getvalue()).decode()


def redact(data: bytes, regions: list[Region]) -> bytes:
    """Blur regions (or the whole image when none are given) and return a JPEG without metadata."""
    img = open_image(data)
    w, h = img.size
    radius = max(8, min(w, h) // 25)
    boxes = [r.box for r in regions] or [(0.0, 0.0, 1.0, 1.0)]
    for x0, y0, x1, y1 in boxes:
        # Grow the box a little so edges of faces and plates are covered.
        pad_x, pad_y = (x1 - x0) * 0.1, (y1 - y0) * 0.1
        box = (
            int(max(0, x0 - pad_x) * w),
            int(max(0, y0 - pad_y) * h),
            int(min(1, x1 + pad_x) * w),
            int(min(1, y1 + pad_y) * h),
        )
        if box[2] <= box[0] or box[3] <= box[1]:
            continue
        img.paste(img.crop(box).filter(ImageFilter.GaussianBlur(radius)), box)
    out = io.BytesIO()
    img.save(out, format="JPEG", quality=90)
    return out.getvalue()
