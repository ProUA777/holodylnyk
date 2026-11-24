"""HTTP API двигуна PhotoAI.

POST /v1/{profile}/analyze   multipart: image=<файл> (до 3 разів), params=<JSON, необов'язково>
POST /v1/{profile}/refine    JSON: перерахунок без фото
POST /v1/{profile}/detail    JSON: детальний текст (рецепт) → {"markdown", "cached"}
POST /v1/{profile}/action/{name}  JSON: додаткова дія профілю (напр. recipes/action/plan — меню на тиждень)
GET  /v1/profiles            список профілів і їхніх параметрів
GET  /health

Заголовки від апки: X-API-Key (ключ апки), X-Device-Id (випадковий id телефона для денних лімітів).
У відповіді: X-Quota-Remaining — скільки ще таких запитів сьогодні (-1 = без ліміту).
"""
from __future__ import annotations

import json
import logging
import re
import time
from collections import defaultdict, deque
from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, File, Form, Header, HTTPException, Request, Response, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, JSONResponse
from pydantic import ValidationError

from .config import Settings, get_settings
from .engine.engine import Engine
from .engine.errors import EngineError
from .engine.providers import build_provider
from .engine.store import Store
from .privacy import privacy_html
from .profiles.homework import HomeworkProfile
from .profiles.outfits import OutfitsProfile
from .profiles.plants import PlantsProfile
from .profiles.repair import RepairProfile
from .profiles.recipes import RecipesProfile

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
log = logging.getLogger("photoai")

DEVICE_RE = re.compile(r"^[A-Za-z0-9-]{8,64}$")


def build_engine(settings: Settings, store: Store) -> Engine:
    engine = Engine(build_provider(settings), store,
                    max_upload_mb=settings.max_upload_mb, image_max_side=settings.image_max_side,
                    max_tokens_detail=settings.max_tokens_detail)
    engine.register(RecipesProfile())
    engine.register(PlantsProfile())
    engine.register(OutfitsProfile())
    engine.register(RepairProfile())
    engine.register(HomeworkProfile())
    # Нові апки підключаються тут: engine.register(LegoProfile()), engine.register(PartsProfile()) ...
    return engine


class RateLimiter:
    """Ковзне вікно в пам'яті (захист від спаму за хвилину). Денні ліміти — у SQLite (Store)."""

    def __init__(self, per_minute: int):
        self.per_minute = per_minute
        self.hits: dict[str, deque[float]] = defaultdict(deque)

    def check(self, key: str) -> None:
        if self.per_minute <= 0:
            return
        now = time.monotonic()
        q = self.hits[key]
        while q and now - q[0] > 60:
            q.popleft()
        if len(q) >= self.per_minute:
            raise HTTPException(status_code=429, detail={"code": "rate_limited", "message": "Забагато запитів, зачекай хвилинку"})
        q.append(now)


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    store = Store(settings.db_path)
    store.cleanup()
    app.state.settings = settings
    app.state.store = store
    app.state.engine = build_engine(settings, store)
    app.state.ai_name = app.state.engine.provider.name
    app.state.limiter = RateLimiter(settings.rate_limit_per_minute)
    log.info("PhotoAI запущено: AI=%s, profiles=%s", app.state.ai_name, [p["id"] for p in app.state.engine.list()])
    if not settings.api_key_set:
        log.warning("PHOTOAI_API_KEYS порожній — сервер відкритий для всіх. Для продакшну обов'язково задай ключ.")
    yield


app = FastAPI(title="PhotoAI Engine", version="1.1.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in get_settings().cors_origins.split(",")],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
    expose_headers=["X-Quota-Remaining"],
)


@app.exception_handler(EngineError)
async def engine_error_handler(_: Request, exc: EngineError):
    return JSONResponse(status_code=exc.status_code, content={"code": exc.code, "message": exc.message})


@app.exception_handler(HTTPException)
async def http_error_handler(_: Request, exc: HTTPException):
    body = exc.detail if isinstance(exc.detail, dict) else {"code": "http_error", "message": str(exc.detail)}
    return JSONResponse(status_code=exc.status_code, content=body, headers=getattr(exc, "headers", None))


class Client:
    """Хто робить запит: пристрій (для денних лімітів) і IP (щоб не обходили ліміт новим id)."""

    def __init__(self, device: str | None, ip: str):
        self.device = device
        self.ip = ip

    def quota_keys(self, settings: Settings, kind: str) -> list[tuple[str, int]]:
        limit = settings.daily_limit(kind)
        ip_key = ("ip:" + self.ip, limit * settings.ip_limit_multiplier if limit else 0)
        if self.device:
            return [("dev:" + self.device, limit), ip_key]
        return [("ip:" + self.ip, limit)]


def guard(request: Request, x_api_key: str | None = Header(default=None),
          x_device_id: str | None = Header(default=None)) -> Client:
    settings: Settings = request.app.state.settings
    allowed = settings.api_key_set
    if allowed and x_api_key not in allowed:
        raise HTTPException(status_code=401, detail={"code": "unauthorized", "message": "Невірний API-ключ"})
    ip = request.client.host if request.client else "anon"
    device = x_device_id if x_device_id and DEVICE_RE.match(x_device_id) else None
    request.app.state.limiter.check(device or ip)
    return Client(device, ip)


async def with_quota(request: Request, client: Client, kind: str, response: Response, call):
    """Списує денний ліміт, виконує виклик AI; якщо AI впав — повертає ліміт назад."""
    settings: Settings = request.app.state.settings
    store: Store = request.app.state.store
    keys = client.quota_keys(settings, kind)
    remaining = store.take(keys, kind)
    try:
        result = await call()
    except Exception:
        store.refund([k for k, _ in keys], kind)
        raise
    response.headers["X-Quota-Remaining"] = str(remaining)
    return result


def parse(model, raw):
    try:
        return model.model_validate(raw)
    except ValidationError as e:
        raise HTTPException(status_code=422, detail={"code": "bad_params", "message": str(e)}) from e


async def read_json(request: Request):
    try:
        return await request.json()
    except (json.JSONDecodeError, UnicodeDecodeError) as e:
        raise HTTPException(status_code=422, detail={"code": "bad_params", "message": "Тіло запиту — не JSON"}) from e


@app.get("/health")
async def health(request: Request):
    return {"status": "ok", "ai": request.app.state.ai_name}


@app.get("/privacy", response_class=HTMLResponse)
async def privacy(request: Request, lang: str = "uk"):
    settings: Settings = request.app.state.settings
    return privacy_html(lang if lang in ("uk", "pl") else "uk", settings.app_owner, settings.contact_email,
                        request.app.state.ai_name)


@app.get("/v1/profiles")
async def profiles(request: Request):
    return request.app.state.engine.list()


@app.post("/v1/{profile_id}/analyze")
async def analyze(request: Request, response: Response, profile_id: str,
                  image: list[UploadFile] = File(...), params: str | None = Form(default=None),
                  client: Client = Depends(guard)):
    engine: Engine = request.app.state.engine
    profile = engine.get(profile_id)
    try:
        raw_params = json.loads(params) if params else {}
    except json.JSONDecodeError as e:
        raise HTTPException(status_code=422, detail={"code": "bad_params", "message": "params — не JSON"}) from e
    parsed = parse(profile.params_model, raw_params)
    settings: Settings = request.app.state.settings
    if len(image) > settings.max_photos:
        raise HTTPException(status_code=422, detail={"code": "too_many_photos",
                                                     "message": f"Не більше {settings.max_photos} фото за раз"})
    limit = int(settings.max_upload_mb * 1024 * 1024)
    raws = [await f.read(limit + 1) for f in image]
    # Одна відправка = один запит з ліміту, скільки б фото в ній не було
    result = await with_quota(request, client, "analyze", response, lambda: engine.analyze(profile_id, raws, parsed))
    return result.model_dump(mode="json")


@app.post("/v1/{profile_id}/refine")
async def refine(request: Request, response: Response, profile_id: str, client: Client = Depends(guard)):
    engine: Engine = request.app.state.engine
    profile = engine.get(profile_id)
    if profile.refine_model is None:
        raise HTTPException(status_code=400, detail={"code": "unsupported", "message": "Перерахунок не підтримується"})
    data = parse(profile.refine_model, await read_json(request))
    result = await with_quota(request, client, "refine", response, lambda: engine.refine(profile_id, data))
    return result.model_dump(mode="json")


@app.post("/v1/{profile_id}/detail")
async def detail(request: Request, response: Response, profile_id: str, client: Client = Depends(guard)):
    engine: Engine = request.app.state.engine
    profile = engine.get(profile_id)
    if profile.detail_model is None:
        raise HTTPException(status_code=400, detail={"code": "unsupported", "message": "Детальний результат не підтримується"})
    data = parse(profile.detail_model, await read_json(request))
    cached = engine.cached_detail(profile_id, data)
    if cached is not None:  # з кешу — безкоштовно й не з'їдає ліміт
        return {"markdown": cached, "cached": True}
    text = await with_quota(request, client, "detail", response, lambda: engine.detail(profile_id, data))
    return {"markdown": text, "cached": False}


@app.post("/v1/{profile_id}/action/{name}")
async def action(request: Request, response: Response, profile_id: str, name: str, client: Client = Depends(guard)):
    engine: Engine = request.app.state.engine
    act = engine.get(profile_id).actions.get(name)
    if act is None:
        raise HTTPException(status_code=404, detail={"code": "unknown_action", "message": f"Невідома дія: {name}"})
    data = parse(act.input_model, await read_json(request))
    result = await with_quota(request, client, name, response, lambda: engine.action(profile_id, name, data))
    return result.model_dump(mode="json")
