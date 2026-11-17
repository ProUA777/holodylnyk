"""Налаштування двигуна. Усе береться зі змінних оточення або файлу .env."""
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_prefix="PHOTOAI_", extra="ignore")

    # "gemini"    — Google Gemini (є безкоштовний рівень); якщо задано й ключ Claude — він страхує
    # "anthropic" — Claude (платно за запити)
    # "mock"      — тестові відповіді без ключа (розробка, тести)
    ai_provider: str = "mock"
    gemini_api_key: str = ""
    anthropic_api_key: str = ""
    ai_timeout_seconds: float = 90.0

    # Gemini: модель на кожен крок. "gemini-flash-latest" — завжди найновіша Flash.
    # Актуальні назви: https://aistudio.google.com (Get code) або https://ai.google.dev/gemini-api/docs/models
    gemini_model_analyze: str = "gemini-flash-latest"
    gemini_model_refine: str = "gemini-flash-latest"
    gemini_model_detail: str = "gemini-flash-latest"

    # Claude: окрема модель на кожен крок — дешева й швидка, де можна, сильна — де треба якість
    model_analyze: str = "claude-haiku-5-5"   # фото → продукти + список страв
    model_refine: str = "claude-haiku-5-5"    # перерахунок / «ще рецепти» без фото
    model_detail: str = "claude-sonnet-5-5"   # детальний рецепт (текст)
    max_tokens_json: int = 8192
    max_tokens_detail: int = 3000

    # Обробка фото
    max_upload_mb: float = 10.0       # на одне фото
    max_photos: int = 3               # холодильник + морозилка + полиця
    image_max_side: int = 1568

    # Захист від зловживань
    rate_limit_per_minute: int = 10   # на пристрій/IP, усі запити разом
    daily_photo_limit: int = 10       # фото на пристрій за добу (0 = без ліміту)
    daily_refine_limit: int = 40      # перерахунків на пристрій за добу
    daily_detail_limit: int = 30      # нових детальних рецептів (з кешу — безкоштовно)
    daily_plan_limit: int = 5         # меню на тиждень
    ip_limit_multiplier: int = 5      # з однієї IP: ліміт × 5 (кілька телефонів в одній Wi-Fi)
    api_keys: str = ""                # через кому; порожньо = без перевірки (тільки для розробки)

    db_path: str = "data/photoai.sqlite3"  # ліміти й кеш детальних рецептів

    # Для політики конфіденційності (/privacy) — її посилання вказується в Google Play і App Store
    app_owner: str = "Greater Koreec Project Group"
    contact_email: str = "email-не-вказано@example.com"
    cors_origins: str = "*"

    @property
    def api_key_set(self) -> set[str]:
        return {k.strip() for k in self.api_keys.split(",") if k.strip()}

    @property
    def anthropic_models(self) -> dict[str, str]:
        return {"analyze": self.model_analyze, "refine": self.model_refine, "detail": self.model_detail}

    @property
    def gemini_models(self) -> dict[str, str]:
        return {"analyze": self.gemini_model_analyze, "refine": self.gemini_model_refine,
                "detail": self.gemini_model_detail}

    def daily_limit(self, kind: str) -> int:
        return {"analyze": self.daily_photo_limit, "refine": self.daily_refine_limit,
                "detail": self.daily_detail_limit}.get(kind, self.daily_plan_limit)


@lru_cache
def get_settings() -> Settings:
    return Settings()
