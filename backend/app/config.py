from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    ai_provider: str = "mock"
    anthropic_api_key: str = ""
    ai_model: str = "claude-sonnet-5-5"
    app_keys: str = "dev-key-food,dev-key-bricks"
    daily_limit: int = 20
    max_image_mb: int = 8
    db_path: str = "data/limits.db"
    log_level: str = "INFO"

    @property
    def app_key_set(self) -> set[str]:
        return {k.strip() for k in self.app_keys.split(",") if k.strip()}


settings = Settings()
