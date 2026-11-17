"""AI-провайдери. Додати нового = написати функцію з тим самим підписом."""
import asyncio
import base64
import io
import json
import logging
import re

import httpx
from PIL import Image, ImageOps

from .config import settings

log = logging.getLogger("photoai.ai")

LANG_NAMES = {"uk": "Ukrainian", "pl": "Polish", "en": "English"}
MAX_SIDE = 1568  # оптимальний розмір для vision-моделей, економить токени


class AIError(Exception):
    pass


class BadImage(ValueError):
    pass


def prepare_image(raw: bytes) -> tuple[str, str]:
    """Зменшує фото і повертає (base64, media_type)."""
    try:
        img = Image.open(io.BytesIO(raw))
        img = ImageOps.exif_transpose(img)  # фото з телефона часто «лежить на боці»
        img = img.convert("RGB")
    except Exception as e:
        raise BadImage("Файл не є зображенням") from e
    img.thumbnail((MAX_SIDE, MAX_SIDE))
    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=85)
    return base64.b64encode(buf.getvalue()).decode(), "image/jpeg"


def extract_json(text: str) -> dict:
    text = text.strip()
    text = re.sub(r"^```(?:json)?\s*|\s*```$", "", text)
    start, end = text.find("{"), text.rfind("}")
    if start == -1 or end == -1:
        raise AIError("Модель не повернула JSON")
    try:
        return json.loads(text[start : end + 1])
    except json.JSONDecodeError as e:
        raise AIError("Некоректний JSON від моделі") from e


_CATALOGS: dict[str, str] = {}


def _catalog_text(profile: dict) -> str:
    """Catalog list injected into the prompt so the model can only pick ids that exist in the app."""
    name = profile.get("catalog_file")
    if not name:
        return ""
    if name not in _CATALOGS:
        from pathlib import Path
        f = Path(__file__).parent / "profiles" / name
        _CATALOGS[name] = f.read_text(encoding="utf-8") if f.exists() else ""
    return _CATALOGS[name]


def catalog_ids(profile: dict) -> set[str]:
    return {line.split("|", 1)[0].strip() for line in _catalog_text(profile).splitlines() if "|" in line}


def clean_result(profile: dict, result: dict) -> dict:
    """Drop catalog ids the model made up and keep at most 6 matches."""
    ids = catalog_ids(profile)
    if ids and isinstance(result.get("matches"), list):
        seen, kept = set(), []
        for m in result["matches"]:
            mid = m.get("id") if isinstance(m, dict) else None
            if mid in ids and mid not in seen:
                seen.add(mid)
                kept.append({"id": mid, "why": str(m.get("why") or "")[:200]})
        result["matches"] = kept[:6]
    return result


async def analyze(profile: dict, b64: str, media_type: str, lang: str) -> dict:
    instruction = profile["instruction"].replace("{lang}", LANG_NAMES.get(lang, "English")).replace("{catalog}", _catalog_text(profile))
    if settings.ai_provider == "anthropic":
        return clean_result(profile, await _anthropic(profile["system"], instruction, b64, media_type))
    return clean_result(profile, _mock(profile["id"], lang))


async def _anthropic(system: str, instruction: str, b64: str, media_type: str) -> dict:
    if not settings.anthropic_api_key:
        raise AIError("ANTHROPIC_API_KEY не задано")
    payload = {
        "model": settings.ai_model,
        "max_tokens": 4000,
        "system": system,
        "messages": [{
            "role": "user",
            "content": [
                {"type": "image", "source": {"type": "base64", "media_type": media_type, "data": b64}},
                {"type": "text", "text": instruction},
            ],
        }],
    }
    headers = {
        "x-api-key": settings.anthropic_api_key,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
    }
    r = None
    for attempt in range(2):  # одна повторна спроба при перевантаженні
        try:
            async with httpx.AsyncClient(timeout=110) as client:
                r = await client.post("https://api.anthropic.com/v1/messages", json=payload, headers=headers)
        except httpx.HTTPError as e:
            if attempt == 0:
                await asyncio.sleep(1.5)
                continue
            raise AIError("AI-сервіс недоступний") from e
        if r.status_code in (429, 500, 502, 503, 529) and attempt == 0:
            log.warning("AI busy (%s), retrying", r.status_code)
            await asyncio.sleep(2)
            continue
        break
    if r is None or r.status_code != 200:
        raise AIError(f"AI-сервіс відповів {r.status_code if r is not None else '—'}")
    data = r.json()
    usage = data.get("usage", {})
    log.info("AI ok: in=%s out=%s tokens", usage.get("input_tokens"), usage.get("output_tokens"))
    text = "".join(b.get("text", "") for b in data.get("content", []) if b.get("type") == "text")
    return extract_json(text)


def _mock(profile_id: str, lang: str) -> dict:
    """Тестова відповідь — щоб робити UI без витрат на API."""
    if profile_id == "brick_builder":
        return {
            "readable": True,
            "source": "instructions",
            "depicted": "золотий дракон",
            "pieces": {"total_estimate": None, "colors": [
                {"name": "золотий", "hex": "#D9A93A", "count": 30}, {"name": "темно-зелений", "hex": "#1F6B5A", "count": 28},
                {"name": "сірий", "hex": "#8E949A", "count": 8}, {"name": "рожевий прозорий", "hex": "#E0457B", "count": 1}],
                "notable": ["шарніри", "вигнуті деталі-кігті"]},
            "matches": [
                {"id": "dragon", "why": "Тестова відповідь (mock): той самий дракон, у золото-зелених кольорах."},
                {"id": "pagoda", "why": "Східна тема й ті самі кольори."},
                {"id": "fortress", "why": "Замок для дракона."},
                {"id": "made-up-id", "why": "Цей id відфільтрується."},
                {"id": "chest", "why": "Скарб, який охороняє дракон."},
            ],
            "ideas": [
                {"title": "Драконове гніздо", "emoji": "🥚", "difficulty": "easy", "minutes": 10,
                 "description": "Гніздо із золотими яйцями.", "uses": ["зелені пластини", "золоті 1×1"],
                 "steps": ["Виклади зелене коло з пластин.", "Додай бортик із зелених цеглинок.", "Поклади всередину золоті 1×1."]},
            ],
            "retake_hint": None,
        }
    return {
        "readable": True,
        "product_name": "Печиво «Тест»",
        "verdict": "ok",
        "score": 58,
        "summary": "Тестова відповідь (mock). Багато цукру, але без небезпечних добавок.",
        "sugar": {"per_100g": 24.0, "level": "high"},
        "salt": {"per_100g": 0.4, "level": "low"},
        "additives": [
            {"code": "E322", "name": "Лецитин", "risk": "low", "note": "Емульгатор, зазвичай безпечний."},
            {"code": "E500", "name": "Харчова сода", "risk": "low", "note": "Розпушувач."},
        ],
        "allergens": ["глютен", "молоко"],
        "pros": ["Немає консервантів"],
        "cons": ["Високий вміст цукру"],
        "retake_hint": None,
    }
