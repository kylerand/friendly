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
    # Classic names
    supabase_anon_key: str | None = None
    supabase_service_role_key: str | None = None
    # New 2024+ naming (publishable vs secret)
    supabase_publishable_key: str | None = None
    supabase_secret_key: str | None = None

    # -- Supabase Postgres (direct connection via connection pooler) --
    database_url: str

    # -- Supabase JWT verification --
    # The JWT secret from Supabase → Settings → API → JWT Secret.
    # Used to verify HS*-signed access tokens locally. If your project
    # uses asymmetric tokens (ES*/RS*), you can leave this blank and the
    # backend will verify via the Supabase JWKS endpoint.
    supabase_jwt_secret: str | None = None

    # -- GitHub (optional — enables "Create GitHub Issue" from feedback) --
    github_token: str | None = None
    github_repo: str = "kylerand/friendly-admin-webui"
    github_repo_api: str = "kylerand/friendly"
    github_repo_mobile: str = "kylerand/friendly-mobile"
    github_repo_web: str = "kylerand/friendly-admin-webui"

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
    s = Settings()  # type: ignore[call-arg]

    # Backwards-compatible mapping: prefer new names when present
    if not s.supabase_anon_key and s.supabase_publishable_key:
        s.supabase_anon_key = s.supabase_publishable_key
    if not s.supabase_service_role_key and s.supabase_secret_key:
        s.supabase_service_role_key = s.supabase_secret_key

    return s
