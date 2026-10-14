from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI, HTTPException

from . import __doc__ as service_doc
from .analyzer import analyze
from .config import settings
from .models import AnalyzeRequest, AnalyzeResponse


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
