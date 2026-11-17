import json
import logging
import time
from pathlib import Path

from fastapi import FastAPI, File, Form, Header, HTTPException, Request, UploadFile
from pydantic import BaseModel, Field
from fastapi.responses import FileResponse

from .ai import AIError, BadImage, analyze, prepare_image
from .config import settings
from .limiter import DailyLimiter, ReportStore

logging.basicConfig(level=settings.log_level, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
log = logging.getLogger("photoai")

HERE = Path(__file__).parent
PROFILES = {p.stem: json.loads(p.read_text(encoding="utf-8")) for p in (HERE / "profiles").glob("*.json")}
LANGS = ("uk", "pl", "en")

app = FastAPI(title="PhotoAI Engine", version="1.0.0", docs_url=None, redoc_url=None)
limiter = DailyLimiter(settings.db_path)
reports = ReportStore(limiter)


@app.get("/health")
def health():
    return {"ok": True, "provider": settings.ai_provider, "profiles": sorted(PROFILES)}


@app.get("/privacy")
def privacy():
    """Privacy policy page — link it in Google Play Console."""
    return FileResponse(HERE / "static" / "privacy.html", media_type="text/html; charset=utf-8")


@app.get("/v1/profiles")
def profiles():
    return [{"id": p["id"], "title": p["title"]} for p in PROFILES.values()]


@app.post("/v1/analyze/{profile_id}")
async def analyze_photo(
    profile_id: str,
    request: Request,
    image: UploadFile = File(...),
    lang: str = Form("uk"),
    x_app_key: str = Header(""),
    x_device_id: str = Header(""),
):
    if x_app_key not in settings.app_key_set:
        raise HTTPException(401, "Невірний ключ застосунку")
    profile = PROFILES.get(profile_id)
    if not profile:
        raise HTTPException(404, "Невідомий профіль")

    raw = await image.read(settings.max_image_mb * 1024 * 1024 + 1)
    if len(raw) > settings.max_image_mb * 1024 * 1024:
        raise HTTPException(413, "Фото завелике")
    try:
        b64, media_type = prepare_image(raw)
    except BadImage as e:
        raise HTTPException(400, str(e))
    finally:
        del raw  # the photo is never written to disk

    client_id = (x_device_id or (request.client.host if request.client else "unknown"))[:64]
    if limiter.used(client_id) >= settings.daily_limit:
        raise HTTPException(429, "Денний ліміт вичерпано")

    started = time.monotonic()
    try:
        result = await analyze(profile, b64, media_type, lang if lang in LANGS else "en")
    except AIError as e:
        log.warning("analyze failed: %s", e)
        raise HTTPException(502, str(e))  # a failed scan does not use up the limit

    used = limiter.add(client_id)
    log.info("analyze %s ok in %.1fs (used %d/%d)", profile_id, time.monotonic() - started, used, settings.daily_limit)
    return {"profile": profile_id, "remaining_today": max(0, settings.daily_limit - used), "result": result}


class Report(BaseModel):
    profile: str = Field(max_length=40)
    lang: str = Field(default="uk", max_length=5)
    reason: str = Field(max_length=40)
    content: str = Field(default="", max_length=4000)


@app.post("/v1/report")
def report(r: Report, x_app_key: str = Header("")):
    """Flag an inappropriate or wrong AI answer. Only the answer text is kept, never the photo."""
    if x_app_key not in settings.app_key_set:
        raise HTTPException(401, "Невірний ключ застосунку")
    reports.add(r.profile, r.lang, r.reason, r.content)
    log.warning("AI answer reported: %s / %s", r.profile, r.reason)
    return {"ok": True}
