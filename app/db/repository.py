"""
Friendly Backend — Repository

Database operations against Supabase Postgres via the supabase-py client.
Replaces the old InMemoryStorage with real persistence.

Design decisions:
- Uses the service_role client so the backend controls authorization
  logic (not RLS) — RLS is the safety net, not the primary control.
- All methods accept/return plain dicts or Pydantic models.
- No ORM. Simple insert/select via PostgREST.
- Each method is a thin wrapper. Business logic stays in services/.
"""

from datetime import datetime
from typing import Any

from supabase import Client

from app.db import get_supabase_admin


class Repository:
    """Thin data-access layer over Supabase Postgres."""

    def __init__(self, client: Client | None = None):
        self._client = client or get_supabase_admin()

    # -- Profiles --

    def get_profile(self, user_id: str) -> dict[str, Any] | None:
        result = (
            self._client.table("profiles")
            .select("*")
            .eq("id", user_id)
            .maybe_single()
            .execute()
        )
        return result.data

    def upsert_profile(self, user_id: str, display_name: str, **kwargs: Any) -> dict[str, Any]:
        payload = {"id": user_id, "display_name": display_name, **kwargs}
        result = (
            self._client.table("profiles")
            .upsert(payload, on_conflict="id")
            .execute()
        )
        return result.data[0] if result.data else payload

    def search_profiles(self, query: str, exclude_id: str | None = None, limit: int = 20) -> list[dict[str, Any]]:
        """Search profiles by display_name (case-insensitive partial match)."""
        builder = (
            self._client.table("profiles")
            .select("id, display_name, avatar_url, created_at")
            .ilike("display_name", f"%{query}%")
            .limit(limit)
        )
        if exclude_id:
            builder = builder.neq("id", exclude_id)
        result = builder.execute()
        return result.data or []

    # -- Friendships --

    def create_friendship(self, user_id: str, friend_id: str) -> dict[str, Any]:
        result = (
            self._client.table("friendships")
            .insert({"user_id": user_id, "friend_id": friend_id, "status": "pending"})
            .execute()
        )
        return result.data[0]

    def update_friendship_status(self, friendship_id: str, status: str) -> dict[str, Any]:
        result = (
            self._client.table("friendships")
            .update({"status": status})
            .eq("id", friendship_id)
            .execute()
        )
        return result.data[0] if result.data else {}

    def list_friendships(self, user_id: str) -> list[dict[str, Any]]:
        result = (
            self._client.table("friendships")
            .select("*")
            .or_(f"user_id.eq.{user_id},friend_id.eq.{user_id}")
            .execute()
        )
        return result.data or []

    def get_friendship(self, friendship_id: str) -> dict[str, Any] | None:
        result = (
            self._client.table("friendships")
            .select("*")
            .eq("id", friendship_id)
            .maybe_single()
            .execute()
        )
        return result.data

    # -- Check-ins --

    def create_check_in(
        self, user_id: str, comfort: int, connection: int, energy: int, notes: str = ""
    ) -> dict[str, Any]:
        result = (
            self._client.table("check_ins")
            .insert({
                "user_id": user_id,
                "comfort": comfort,
                "connection": connection,
                "energy": energy,
                "notes": notes,
            })
            .execute()
        )
        return result.data[0]

    def list_check_ins(self, user_id: str, limit: int = 20) -> list[dict[str, Any]]:
        result = (
            self._client.table("check_ins")
            .select("*")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .limit(limit)
            .execute()
        )
        return result.data or []

    # -- Interactions --

    def create_interaction(
        self, user_id: str, target_id: str, interaction_type: str = "message", metadata: dict | None = None
    ) -> dict[str, Any]:
        result = (
            self._client.table("interactions")
            .insert({
                "user_id": user_id,
                "target_id": target_id,
                "type": interaction_type,
                "metadata": metadata or {},
            })
            .execute()
        )
        return result.data[0]

    def list_interactions(self, user_id: str, limit: int = 50) -> list[dict[str, Any]]:
        result = (
            self._client.table("interactions")
            .select("*")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .limit(limit)
            .execute()
        )
        return result.data or []

    # -- Ambient signals --

    def create_ambient_signal(
        self, user_id: str, signal_type: str, value: float, tags: list[str] | None = None
    ) -> dict[str, Any]:
        result = (
            self._client.table("ambient_signals")
            .insert({
                "user_id": user_id,
                "signal_type": signal_type,
                "value": value,
                "tags": tags or [],
            })
            .execute()
        )
        return result.data[0]

    def list_ambient_signals(self, user_id: str, limit: int = 50) -> list[dict[str, Any]]:
        result = (
            self._client.table("ambient_signals")
            .select("*")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .limit(limit)
            .execute()
        )
        return result.data or []

    # -- Health --

    def health_check(self) -> bool:
        """Quick check that the DB is reachable."""
        try:
            self._client.table("profiles").select("id").limit(1).execute()
            return True
        except Exception:
            return False
