from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Environment-driven settings. Empty LLM_BASE_URL switches to mock mode."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    llm_base_url: str = ""
    llm_api_key: str = "not-needed"
    vision_model: str = "terra-vision"
    request_timeout_s: float = 60.0

    @property
    def mock(self) -> bool:
        return not self.llm_base_url


settings = Settings()
