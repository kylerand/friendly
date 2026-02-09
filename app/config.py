"""
Friendly Backend — Configuration

Single source of truth for all environment variables.
Uses pydantic-settings to validate on startup — if a required var is missing,
the app refuses to start with a clear error message.

Local dev: create a `.env` file from `.env.example`.
Railway: set these in the Railway dashboard → Variables.
"""

from functools import lru_cache

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # -- Supabase --
    supabase_url: str
    supabase_anon_key: str
    supabase_service_role_key: str

    # -- Supabase Postgres (direct connection via connection pooler) --
    database_url: str

    # -- Supabase JWT verification --
    # The JWT secret from Supabase → Settings → API → JWT Secret.
    # Used to verify access tokens on the backend without calling Supabase.
    supabase_jwt_secret: str

    # -- App --
    environment: str = "development"  # "development" | "pilot" | "production"
    allowed_origins: str = "*"        # Comma-separated for CORS
    log_level: str = "info"

    @property
    def is_pilot(self) -> bool:
        return self.environment == "pilot"

    @property
    def cors_origins(self) -> list[str]:
        return [o.strip() for o in self.allowed_origins.split(",")]

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "case_sensitive": False,
    }


@lru_cache
def get_settings() -> Settings:
    return Settings()  # type: ignore[call-arg]
