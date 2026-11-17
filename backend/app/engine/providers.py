"""AI-провайдери. Двигун працює з інтерфейсом AIProvider, тож модель можна замінити одним рядком у .env.

- GeminiProvider     — Google Gemini (є безкоштовний рівень з лімітами) — за замовчуванням
- AnthropicProvider  — Claude (платно за запити, стабільна якість і ліміти)
- FallbackProvider   — спершу Gemini, а якщо ліміт вичерпано чи сервіс недоступний — Claude
- MockProvider       — тестові відповіді без мережі й ключів

Кожен провайдер сам знає, яку модель брати на кожен крок: "analyze" (фото), "refine", "detail".
"""
from __future__ import annotations

import base64
import copy
import json
import logging
import re
from abc import ABC, abstractmethod
from typing import Any

import httpx

from .base import AIRequest
from .errors import AIBadResponseError, AIUnavailableError

log = logging.getLogger("photoai.ai")


class AIQuotaError(AIUnavailableError):
    """Ліміт провайдера вичерпано (429) — привід перемкнутися на запасний."""


def inline_refs(schema: dict[str, Any]) -> dict[str, Any]:
    """Розгортає $ref/$defs від Pydantic у плоску схему — так її стабільніше розуміють моделі."""
    schema = copy.deepcopy(schema)
    defs = schema.pop("$defs", {})

    def walk(node: Any) -> Any:
        if isinstance(node, dict):
            if "$ref" in node:
                name = node["$ref"].split("/")[-1]
                resolved = walk(copy.deepcopy(defs[name]))
                extra = {k: v for k, v in node.items() if k != "$ref"}
                return {**resolved, **walk(extra)}
            return {k: walk(v) for k, v in node.items()}
        if isinstance(node, list):
            return [walk(v) for v in node]
        return node

    return walk(schema)


def parse_json_loose(text: str) -> dict[str, Any]:
    """JSON з відповіді моделі: напряму, з ```-блоку або від першої { до останньої }."""
    text = text.strip()
    for candidate in (
        text,
        (m.group(1) if (m := re.search(r"```(?:json)?\s*(.*?)```", text, re.S)) else None),
        text[text.find("{"): text.rfind("}") + 1] if "{" in text else None,
    ):
        if not candidate:
            continue
        try:
            value = json.loads(candidate)
        except json.JSONDecodeError:
            continue
        if isinstance(value, dict):
            return value
    raise AIBadResponseError("AI повернув неочікуваний формат, спробуй ще раз")


class AIProvider(ABC):
    name = "ai"

    @abstractmethod
    async def generate(self, req: AIRequest, mock_output: dict[str, Any] | None = None) -> dict[str, Any]:
        """Повертає сирий dict, який потім валідується моделлю результату профілю."""

    @abstractmethod
    async def generate_text(self, system: str, user: str, max_tokens: int, mock_text: str | None = None) -> str:
        """Вільний текст (Markdown) — для детального рецепта."""


class MockProvider(AIProvider):
    """Без мережі й ключів: повертає приклад відповіді від самого профілю."""

    name = "mock"

    async def generate(self, req: AIRequest, mock_output: dict[str, Any] | None = None) -> dict[str, Any]:
        if mock_output is None:
            raise AIUnavailableError("Для цього профілю немає тестових даних")
        return copy.deepcopy(mock_output)

    async def generate_text(self, system, user, max_tokens, mock_text=None) -> str:
        if mock_text is None:
            raise AIUnavailableError("Для цього профілю немає тестових даних")
        return mock_text


class GeminiProvider(AIProvider):
    """Google Gemini через REST (generateContent). Ключ: https://aistudio.google.com/apikey"""

    name = "gemini"
    URL = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"

    def __init__(self, api_key: str, models: dict[str, str], timeout: float, max_tokens: int,
                 client: httpx.AsyncClient | None = None):
        if not api_key:
            raise RuntimeError("PHOTOAI_GEMINI_API_KEY не задано")
        self.api_key = api_key
        self.models = models
        self.max_tokens = max_tokens
        self.client = client or httpx.AsyncClient(timeout=timeout)

    async def _call(self, model: str, system: str, parts: list[dict[str, Any]], max_tokens: int,
                    json_mode: bool, vision: bool = False) -> str:
        body: dict[str, Any] = {
            "systemInstruction": {"parts": [{"text": system}]},
            "contents": [{"role": "user", "parts": parts}],
            "generationConfig": {"maxOutputTokens": max_tokens},
        }
        if vision:
            # Без цього Gemini стискає фото до ~258 токенів — дрібні етикетки й продукти на задніх полицях губляться
            body["generationConfig"]["mediaResolution"] = "MEDIA_RESOLUTION_HIGH"
            body["generationConfig"]["temperature"] = 0.2
        if json_mode:
            body["generationConfig"]["responseMimeType"] = "application/json"
        try:
            r = await self.client.post(self.URL.format(model=model), json=body,
                                       headers={"x-goog-api-key": self.api_key})
        except httpx.HTTPError as e:
            log.warning("Gemini недоступний: %s", e)
            raise AIUnavailableError("AI тимчасово недоступний, спробуй ще раз") from e

        if r.status_code == 429:
            log.warning("Gemini: ліміт вичерпано (%s)", r.text[:200])
            raise AIQuotaError("AI зараз перевантажений, спробуй трохи пізніше")
        if r.status_code in (401, 403) or (r.status_code == 400 and "API key" in r.text):
            log.error("Gemini: ключ невірний або без доступу: %s", r.text[:300])
            raise AIUnavailableError("Сервер неправильно налаштований (ключ AI)")
        if r.status_code == 404:
            log.error("Gemini: модель %s не знайдено — перевір PHOTOAI_GEMINI_MODEL_*", model)
            raise AIUnavailableError("Сервер неправильно налаштований (модель AI)")
        if r.status_code >= 400:
            log.warning("Gemini %s: %s", r.status_code, r.text[:300])
            raise AIUnavailableError("AI тимчасово недоступний, спробуй ще раз")

        data = r.json()
        cand = (data.get("candidates") or [{}])[0]
        reason = cand.get("finishReason", "")
        text = "".join(p.get("text", "") for p in cand.get("content", {}).get("parts", []) if not p.get("thought"))
        if not text.strip():
            if reason in ("SAFETY", "PROHIBITED_CONTENT", "BLOCKLIST", "IMAGE_SAFETY"):
                raise AIBadResponseError("AI не зміг обробити це фото. Спробуй інше")
            if reason == "MAX_TOKENS":
                raise AIBadResponseError("Відповідь AI обрізана — збільш PHOTOAI_MAX_TOKENS_JSON")
            raise AIBadResponseError("AI повернув порожню відповідь, спробуй ще раз")
        return text

    async def generate(self, req: AIRequest, mock_output: dict[str, Any] | None = None) -> dict[str, Any]:
        parts: list[dict[str, Any]] = []
        for n, jpeg in enumerate(req.images_jpeg, start=1):
            if len(req.images_jpeg) > 1:
                parts.append({"text": f"Фото {n}:"})
            parts.append({"inlineData": {"mimeType": "image/jpeg", "data": base64.b64encode(jpeg).decode()}})
        schema = json.dumps(inline_refs(req.output_schema), ensure_ascii=False)
        parts.append({"text": f"{req.user_text}\n\nВідповідай ЛИШЕ одним JSON-об'єктом за цією JSON Schema "
                              f"(без пояснень і без ```):\n{schema}"})
        model = self.models.get(req.mode, self.models["refine"])  # нові дії (напр. plan) — на моделі «refine»
        text = await self._call(model, req.system, parts, self.max_tokens, json_mode=True,
                                vision=bool(req.images_jpeg))
        return parse_json_loose(text)

    async def generate_text(self, system, user, max_tokens, mock_text=None) -> str:
        return (await self._call(self.models["detail"], system, [{"text": user}], max_tokens, json_mode=False)).strip()


class AnthropicProvider(AIProvider):
    name = "anthropic"
    TOOL_NAME = "submit_result"

    def __init__(self, api_key: str, models: dict[str, str], timeout: float, max_tokens: int):
        if not api_key:
            raise RuntimeError("PHOTOAI_ANTHROPIC_API_KEY не задано")
        from anthropic import AsyncAnthropic

        self.client = AsyncAnthropic(api_key=api_key, timeout=timeout, max_retries=2)
        self.models = models
        self.max_tokens = max_tokens

    async def generate(self, req: AIRequest, mock_output: dict[str, Any] | None = None) -> dict[str, Any]:
        import anthropic

        content: list[dict[str, Any]] = []
        for n, jpeg in enumerate(req.images_jpeg, start=1):
            if len(req.images_jpeg) > 1:
                content.append({"type": "text", "text": f"Фото {n}:"})
            content.append({
                "type": "image",
                "source": {"type": "base64", "media_type": "image/jpeg", "data": base64.b64encode(jpeg).decode()},
            })
        content.append({"type": "text", "text": req.user_text})

        tool = {
            "name": self.TOOL_NAME,
            "description": "Поверни результат строго за цією схемою.",
            "input_schema": inline_refs(req.output_schema),
        }
        try:
            msg = await self.client.messages.create(
                model=self.models.get(req.mode, self.models["refine"]),
                max_tokens=self.max_tokens,
                **({"temperature": 0.2} if req.images_jpeg else {}),
                system=req.system,
                messages=[{"role": "user", "content": content}],
                tools=[tool],
                tool_choice={"type": "tool", "name": self.TOOL_NAME},
            )
        except anthropic.APIError as e:
            raise self._map_error(e) from e

        for block in msg.content:
            if block.type == "tool_use" and block.name == self.TOOL_NAME:
                return dict(block.input)
        if msg.stop_reason == "max_tokens":
            raise AIBadResponseError("Відповідь AI обрізана — збільш PHOTOAI_MAX_TOKENS_JSON")
        raise AIBadResponseError("AI не повернув структурований результат")

    async def generate_text(self, system, user, max_tokens, mock_text=None) -> str:
        import anthropic

        try:
            msg = await self.client.messages.create(
                model=self.models["detail"], max_tokens=max_tokens, system=system,
                messages=[{"role": "user", "content": user}],
            )
        except anthropic.APIError as e:
            raise self._map_error(e) from e
        text = "".join(b.text for b in msg.content if b.type == "text").strip()
        if not text:
            raise AIBadResponseError("AI повернув порожню відповідь")
        return text

    @staticmethod
    def _map_error(e: Exception) -> Exception:
        import anthropic

        if isinstance(e, anthropic.RateLimitError):
            return AIQuotaError("AI зараз перевантажений, спробуй трохи пізніше")
        if isinstance(e, anthropic.AuthenticationError | anthropic.PermissionDeniedError):
            log.error("Ключ Anthropic невірний або без доступу: %s", e)
            return AIUnavailableError("Сервер неправильно налаштований (ключ AI)")
        if isinstance(e, anthropic.NotFoundError):
            log.error("Модель не знайдено — перевір PHOTOAI_MODEL_*: %s", e)
            return AIUnavailableError("Сервер неправильно налаштований (модель AI)")
        if isinstance(e, anthropic.BadRequestError) and "credit" in str(e).lower():
            log.error("На рахунку Anthropic закінчились кошти: %s", e)
            return AIQuotaError("AI тимчасово недоступний")
        log.warning("AI недоступний: %s", e)
        return AIUnavailableError("AI тимчасово недоступний, спробуй ще раз")


class FallbackProvider(AIProvider):
    """Спершу основний (напр. безкоштовний Gemini); якщо він недоступний або ліміт вичерпано — запасний."""

    def __init__(self, primary: AIProvider, backup: AIProvider):
        self.primary, self.backup = primary, backup
        self.name = f"{primary.name}+{backup.name}"

    async def generate(self, req, mock_output=None):
        try:
            return await self.primary.generate(req, mock_output)
        except AIUnavailableError as e:
            log.info("%s недоступний (%s) — перемикаюсь на %s", self.primary.name, e.message, self.backup.name)
            return await self.backup.generate(req, mock_output)

    async def generate_text(self, system, user, max_tokens, mock_text=None):
        try:
            return await self.primary.generate_text(system, user, max_tokens, mock_text)
        except AIUnavailableError as e:
            log.info("%s недоступний (%s) — перемикаюсь на %s", self.primary.name, e.message, self.backup.name)
            return await self.backup.generate_text(system, user, max_tokens, mock_text)


def build_provider(settings) -> AIProvider:
    def anthropic_():
        return AnthropicProvider(settings.anthropic_api_key, settings.anthropic_models,
                                 settings.ai_timeout_seconds, settings.max_tokens_json)

    def gemini_():
        return GeminiProvider(settings.gemini_api_key, settings.gemini_models,
                              settings.ai_timeout_seconds, settings.max_tokens_json)

    if settings.ai_provider == "gemini":
        # Є ще й ключ Claude — він страхує, коли безкоштовний ліміт Gemini закінчився
        return FallbackProvider(gemini_(), anthropic_()) if settings.anthropic_api_key else gemini_()
    if settings.ai_provider == "anthropic":
        return anthropic_()
    if settings.ai_provider == "mock":
        return MockProvider()
    raise RuntimeError(f"Невідомий PHOTOAI_AI_PROVIDER: {settings.ai_provider} (gemini | anthropic | mock)")
