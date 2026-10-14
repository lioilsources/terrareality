from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI, HTTPException, Response

from . import __doc__ as service_doc
from .analyzer import analyze
from .config import settings
from .images import fetch, redact
from .models import AnalyzeRequest, AnalyzeResponse, RedactRequest


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.http = httpx.AsyncClient()
    yield
    await app.state.http.aclose()


app = FastAPI(title="terra-vision", description=service_doc, version="0.1.0", lifespan=lifespan)


@app.get("/healthz")
async def healthz() -> dict:
    return {"status": "ok", "mock": settings.mock, "model": "mock" if settings.mock else settings.vision_model}


@app.post("/v1/photos/analyze", response_model=AnalyzeResponse)
async def photos_analyze(req: AnalyzeRequest) -> AnalyzeResponse:
    try:
        return await analyze(req, settings, app.state.http)
    except httpx.HTTPError as e:
        raise HTTPException(status_code=502, detail=f"LLM gateway error: {e}") from e
    except ValueError as e:
        raise HTTPException(status_code=502, detail=f"Unusable model output: {e}") from e


@app.post("/v1/photos/redact", response_class=Response, responses={200: {"content": {"image/jpeg": {}}}})
async def photos_redact(req: RedactRequest) -> Response:
    """Blur faces and licence plates. Runs locally (no LLM), also in mock mode.
    Called only after the owner accepted the privacy suggestion."""
    try:
        data = await fetch(str(req.image_url), app.state.http, settings.request_timeout_s)
        return Response(content=redact(data, req.regions), media_type="image/jpeg")
    except httpx.HTTPError as e:
        raise HTTPException(status_code=502, detail=f"cannot fetch image: {e}") from e
    except (ValueError, OSError) as e:
        raise HTTPException(status_code=422, detail=f"unusable image: {e}") from e
