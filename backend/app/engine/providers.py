"""AI-провайдери. Двигун працює з інтерфейсом AIProvider, тож модель можна замінити."""
from __future__ import annotations

import base64
import copy
import logging
from abc import ABC, abstractmethod
from typing import Any

from .base import AIRequest
from .errors import AIBadResponseError, AIUnavailableError

log = logging.getLogger("photoai.ai")


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


class AIProvider(ABC):
    @abstractmethod
    async def generate(self, req: AIRequest, mock_output: dict[str, Any] | None = None) -> dict[str, Any]:
        """Повертає сирий dict, який потім валідується моделлю результату профілю."""

    @abstractmethod
    async def generate_text(self, system: str, user: str, model: str, max_tokens: int,
                            mock_text: str | None = None) -> str:
        """Вільний текст (Markdown) — для детального рецепта."""


class MockProvider(AIProvider):
    """Без мережі й ключів: повертає приклад відповіді від самого профілю."""

    async def generate(self, req: AIRequest, mock_output: dict[str, Any] | None = None) -> dict[str, Any]:
        if mock_output is None:
            raise AIUnavailableError("Для цього профілю немає тестових даних")
        return copy.deepcopy(mock_output)

    async def generate_text(self, system, user, model, max_tokens, mock_text=None) -> str:
        if mock_text is None:
            raise AIUnavailableError("Для цього профілю немає тестових даних")
        return mock_text


class AnthropicProvider(AIProvider):
    TOOL_NAME = "submit_result"

    def __init__(self, api_key: str, default_model: str, timeout: float, max_tokens: int):
        if not api_key:
            raise RuntimeError("PHOTOAI_ANTHROPIC_API_KEY не задано")
        from anthropic import AsyncAnthropic

        self.client = AsyncAnthropic(api_key=api_key, timeout=timeout, max_retries=2)
        self.model = default_model
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
                model=req.model or self.model,
                max_tokens=self.max_tokens,
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
            raise AIBadResponseError("Відповідь AI обрізана — збільш PHOTOAI_AI_MAX_TOKENS")
        raise AIBadResponseError("AI не повернув структурований результат")

    async def generate_text(self, system, user, model, max_tokens, mock_text=None) -> str:
        import anthropic

        try:
            msg = await self.client.messages.create(
                model=model, max_tokens=max_tokens, system=system,
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

        if isinstance(e, anthropic.AuthenticationError | anthropic.PermissionDeniedError):
            log.error("Ключ Anthropic невірний або без доступу: %s", e)
            return AIUnavailableError("Сервер неправильно налаштований (ключ AI)")
        if isinstance(e, anthropic.NotFoundError):
            log.error("Модель не знайдено — перевір PHOTOAI_MODEL_*: %s", e)
            return AIUnavailableError("Сервер неправильно налаштований (модель AI)")
        if isinstance(e, anthropic.BadRequestError) and "credit" in str(e).lower():
            log.error("На рахунку Anthropic закінчились кошти: %s", e)
            return AIUnavailableError("AI тимчасово недоступний")
        log.warning("AI недоступний: %s", e)
        return AIUnavailableError("AI тимчасово недоступний, спробуй ще раз")


def build_provider(settings) -> AIProvider:
    if settings.ai_provider == "anthropic":
        return AnthropicProvider(settings.anthropic_api_key, settings.model_analyze,
                                 settings.ai_timeout_seconds, settings.max_tokens_json)
    if settings.ai_provider == "mock":
        return MockProvider()
    raise RuntimeError(f"Невідомий PHOTOAI_AI_PROVIDER: {settings.ai_provider}")
