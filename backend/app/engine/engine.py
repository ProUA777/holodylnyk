"""Ядро: реєстр профілів і загальний конвеєр фото → AI → перевірений результат."""
from __future__ import annotations

import logging
from typing import Any

from pydantic import BaseModel, ValidationError

from .base import AIRequest, Profile
from .errors import AIBadResponseError, EngineError, ProfileNotFoundError
from .images import prepare_image
from .providers import AIProvider
from .store import Store

log = logging.getLogger("photoai.engine")


class Engine:
    def __init__(self, provider: AIProvider, store: Store, *, max_upload_mb: float, image_max_side: int,
                 max_tokens_detail: int):
        self.provider = provider
        self.store = store
        self.max_upload_mb = max_upload_mb
        self.image_max_side = image_max_side
        self.max_tokens_detail = max_tokens_detail
        self._profiles: dict[str, Profile] = {}

    # --- реєстр -------------------------------------------------------------
    def register(self, profile: Profile) -> None:
        if profile.id in self._profiles:
            raise ValueError(f"Профіль {profile.id} уже зареєстровано")
        self._profiles[profile.id] = profile

    def get(self, profile_id: str) -> Profile:
        try:
            return self._profiles[profile_id]
        except KeyError:
            raise ProfileNotFoundError(f"Невідомий профіль: {profile_id}") from None

    def list(self) -> list[dict[str, Any]]:
        return [p.describe() for p in self._profiles.values()]

    # --- конвеєр ------------------------------------------------------------
    async def analyze(self, profile_id: str, images: list[bytes], params: BaseModel) -> BaseModel:
        profile = self.get(profile_id)
        if not images:
            raise EngineError("Додай хоча б одне фото")
        jpegs = [prepare_image(img, self.max_upload_mb, self.image_max_side) for img in images]
        req = AIRequest(
            system=profile.system_prompt(params),
            user_text=profile.analyze_prompt(params, len(jpegs)),
            output_schema=profile.result_model.model_json_schema(),
            images_jpeg=jpegs,
            profile_id=profile.id,
            mode="analyze",
        )
        return await self._run(profile, req, params)

    async def refine(self, profile_id: str, data: BaseModel) -> BaseModel:
        profile = self.get(profile_id)
        if profile.refine_model is None:
            raise EngineError("Цей профіль не підтримує перерахунок")
        params = data.params  # type: ignore[attr-defined]
        req = AIRequest(
            system=profile.system_prompt(params),
            user_text=profile.refine_prompt(data),
            output_schema=profile.result_model.model_json_schema(),
            profile_id=profile.id,
            mode="refine",
        )
        return await self._run(profile, req, params)

    def cached_detail(self, profile_id: str, data: BaseModel) -> str | None:
        profile = self.get(profile_id)
        return self.store.get_detail(f"{profile.id}:{profile.detail_cache_key(data)}")

    async def detail(self, profile_id: str, data: BaseModel) -> str:
        profile = self.get(profile_id)
        if profile.detail_model is None:
            raise EngineError("Цей профіль не підтримує детальний результат")
        system, user = profile.detail_prompt(data)
        text = await self.provider.generate_text(system, user, self.max_tokens_detail, mock_text=profile.mock_detail())
        text = profile.postprocess_detail(text)
        if not text:
            raise AIBadResponseError("AI повернув порожній рецепт, спробуй ще раз")
        self.store.put_detail(f"{profile.id}:{profile.detail_cache_key(data)}", profile.id, text)
        return text

    async def action(self, profile_id: str, name: str, data: BaseModel) -> BaseModel:
        profile = self.get(profile_id)
        act = profile.actions.get(name)
        if act is None:
            raise ProfileNotFoundError(f"Невідома дія: {name}")
        params = data.params  # type: ignore[attr-defined]
        req = AIRequest(
            system=profile.system_prompt(params),
            user_text=act.prompt(data),
            output_schema=act.result_model.model_json_schema(),
            profile_id=profile.id,
            mode=name,
        )
        raw = await self.provider.generate(req, mock_output=act.mock() if act.mock else None)
        try:
            result = act.result_model.model_validate(raw)
        except ValidationError as e:
            log.warning("Невалідна відповідь AI для %s/%s: %s", profile.id, name, e)
            raise AIBadResponseError("AI повернув неочікуваний формат, спробуй ще раз") from e
        return act.postprocess(result, data) if act.postprocess else result

    async def _run(self, profile: Profile, req: AIRequest, params: BaseModel) -> BaseModel:
        raw = await self.provider.generate(req, mock_output=profile.mock_output(req.mode))
        try:
            result = profile.result_model.model_validate(raw)
        except ValidationError as e:
            log.warning("Невалідна відповідь AI для %s: %s", profile.id, e)
            raise AIBadResponseError("AI повернув неочікуваний формат, спробуй ще раз") from e
        return profile.postprocess(result, params)
