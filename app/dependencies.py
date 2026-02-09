"""
Friendly Backend — Dependency Injection

Provides shared dependencies for FastAPI route handlers.
The repository is the primary data-access dependency.
The auth dependency provides the current user's UUID from the JWT.
"""

from functools import lru_cache

from app.db.repository import Repository
from app.middleware.auth import get_current_user_id  # noqa: F401 — re-export


@lru_cache
def get_repository() -> Repository:
    return Repository()

