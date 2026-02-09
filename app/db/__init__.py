"""
Friendly Backend — Supabase Client

Initializes two Supabase clients:
- `supabase_admin`: uses the service_role_key for backend operations that
  bypass RLS (e.g., reading cross-user data for drift computation).
- `supabase_anon`: uses the anon_key, respects RLS, for operations that
  should be scoped to the authenticated user.

For direct Postgres queries (if needed later), use DATABASE_URL with asyncpg.
For the pilot, the Supabase Python client is sufficient.
"""

from supabase import create_client, Client

from app.config import get_settings


def get_supabase_admin() -> Client:
    """Service-role client — bypasses RLS. Use only in backend services."""
    settings = get_settings()
    return create_client(settings.supabase_url, settings.supabase_service_role_key)


def get_supabase_anon() -> Client:
    """Anon client — respects RLS. Suitable for user-scoped operations."""
    settings = get_settings()
    return create_client(settings.supabase_url, settings.supabase_anon_key)
