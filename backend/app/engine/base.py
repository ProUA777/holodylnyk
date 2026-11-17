"""Базові типи двигуна «фото → AI → дія».

Кожна ніша (LEGO, рецепти, шафа, деталі...) — це окремий Profile.
Двигун не знає нічого про конкретну нішу: він бере фото, просить у профілю
промпт і схему відповіді, викликає AI і повертає перевірений результат.
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any, Callable, ClassVar

from pydantic import BaseModel


@dataclass
class AIRequest:
    system: str
    user_text: str
    output_schema: dict[str, Any]   # JSON Schema відповіді
    images_jpeg: list[bytes] = field(default_factory=list)  # порожньо — текстовий запит (перерахунок)
    profile_id: str = ""
    mode: str = "analyze"            # "analyze" | "refine" — провайдер бере свою модель для цього кроку


@dataclass
class Action:
    """Додаткова дія профілю без фото (напр. «меню на тиждень»): POST /v1/{profile}/action/{name}."""

    input_model: type[BaseModel]                 # має поле params (параметри профілю)
    result_model: type[BaseModel]
    prompt: Callable[[Any], str]                 # data -> текст запиту
    postprocess: Callable[[Any, Any], Any] | None = None   # (result, data) -> result
    mock: Callable[[], dict[str, Any]] | None = None


class Profile(ABC):
    """Опис однієї ніші. Щоб додати нову апку — створи підклас і зареєструй його."""

    id: ClassVar[str]
    title: ClassVar[str]
    description: ClassVar[str] = ""
    params_model: ClassVar[type[BaseModel]]
    result_model: ClassVar[type[BaseModel]]
    # Модель вхідних даних для перерахунку без фото (None — не підтримується)
    refine_model: ClassVar[type[BaseModel] | None] = None
    # Вхідні дані для детального текстового результату (None — не підтримується)
    detail_model: ClassVar[type[BaseModel] | None] = None
    # Додаткові дії: {"plan": Action(...)}
    actions: ClassVar[dict[str, Action]] = {}

    @abstractmethod
    def system_prompt(self, params: BaseModel) -> str: ...

    @abstractmethod
    def analyze_prompt(self, params: BaseModel, photo_count: int = 1) -> str: ...

    def refine_prompt(self, data: BaseModel) -> str:  # pragma: no cover - перевизначається
        raise NotImplementedError

    def detail_prompt(self, data: BaseModel) -> tuple[str, str]:  # pragma: no cover
        """Повертає (system, user) для детального тексту."""
        raise NotImplementedError

    def detail_cache_key(self, data: BaseModel) -> str:  # pragma: no cover
        raise NotImplementedError

    def postprocess_detail(self, text: str) -> str:
        return text.strip()

    def mock_detail(self) -> str | None:
        return None

    def postprocess(self, result: BaseModel, params: BaseModel) -> BaseModel:
        """Хук для чистки відповіді AI (обрізати зайве, впорядкувати тощо)."""
        return result

    def mock_output(self, mode: str) -> dict[str, Any] | None:
        """Приклад відповіді для MockProvider (розробка без ключа, тести)."""
        return None

    def describe(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "supports_refine": self.refine_model is not None,
            "supports_detail": self.detail_model is not None,
            "actions": sorted(self.actions),
            "params_schema": self.params_model.model_json_schema(),
        }
