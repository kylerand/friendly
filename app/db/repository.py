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

    def update_ambient_signal(self, signal_id: str, **kwargs: Any) -> dict[str, Any]:
        """Update fields on an ambient signal (e.g. value for beacon deactivation)."""
        result = (
            self._client.table("ambient_signals")
            .update(kwargs)
            .eq("id", signal_id)
            .execute()
        )
        return result.data[0] if result.data else {}

    def list_received_care_signals(self, user_id: str, days: int = 7) -> list[dict[str, Any]]:
        """
        List care signals where this user is the recipient (target_id).

        Returns interactions of type 'care_signal' directed at the user
        within the given number of days. Includes sender profile info.
        """
        from datetime import datetime, timedelta, timezone

        cutoff = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()
        result = (
            self._client.table("interactions")
            .select("id, user_id, target_id, type, metadata, created_at")
            .eq("target_id", user_id)
            .eq("type", "care_signal")
            .gte("created_at", cutoff)
            .order("created_at", desc=True)
            .execute()
        )
        signals = result.data or []

        # Resolve sender names
        for s in signals:
            sender = self.get_profile(s["user_id"])
            s["sender_name"] = sender.get("display_name", "Someone") if sender else "Someone"

        return signals

    # -- Health --

    def health_check(self) -> bool:
        """Quick check that the DB is reachable."""
        try:
            self._client.table("profiles").select("id").limit(1).execute()
            return True
        except Exception:
            return False

    # -- Admin access --

    def get_admin_user(self, user_id: str) -> dict[str, Any] | None:
        result = (
            self._client.table("admin_users")
            .select("user_id, role, created_at")
            .eq("user_id", user_id)
            .maybe_single()
            .execute()
        )
        return result.data

    def list_admin_users(self) -> list[dict[str, Any]]:
        result = (
            self._client.table("admin_users")
            .select("user_id, role, created_at, profiles(id, display_name, avatar_url, phone_number, email, created_at)")
            .order("created_at", desc=True)
            .execute()
        )
        return result.data or []

    def upsert_admin_user(self, user_id: str, role: str) -> dict[str, Any]:
        result = (
            self._client.table("admin_users")
            .upsert({"user_id": user_id, "role": role}, on_conflict="user_id")
            .execute()
        )
        return result.data[0] if result.data else {"user_id": user_id, "role": role}

    def delete_admin_user(self, user_id: str) -> None:
        self._client.table("admin_users").delete().eq("user_id", user_id).execute()

    def list_profiles_admin(self, query: str | None = None, limit: int = 50) -> list[dict[str, Any]]:
        builder = (
            self._client.table("profiles")
            .select("id, display_name, avatar_url, phone_number, email, created_at")
            .order("created_at", desc=True)
            .limit(limit)
        )
        if query:
            builder = builder.ilike("display_name", f"%{query}%")
        result = builder.execute()
        return result.data or []

    def list_friendships_admin(self, user_id: str | None = None, limit: int = 100) -> list[dict[str, Any]]:
        builder = (
            self._client.table("friendships")
            .select("id, user_id, friend_id, status, created_at, updated_at")
            .order("created_at", desc=True)
            .limit(limit)
        )
        if user_id:
            builder = builder.or_(f"user_id.eq.{user_id},friend_id.eq.{user_id}")
        result = builder.execute()
        return result.data or []

    def count_table(self, table: str) -> int:
        result = self._client.table(table).select("id", count="exact").limit(1).execute()
        return int(result.count or 0)

    # -- Tester feedback --

    def get_user_role(self, user_id: str) -> dict[str, Any] | None:
        result = (
            self._client.table("user_roles")
            .select("user_id, role, created_at")
            .eq("user_id", user_id)
            .maybe_single()
            .execute()
        )
        return result.data

    def create_tester_report(self, payload: dict[str, Any]) -> dict[str, Any]:
        result = self._client.table("tester_reports").insert(payload).execute()
        return result.data[0] if result.data else payload

    def list_tester_reports(
        self,
        user_id: str | None = None,
        status: str | None = None,
        report_type: str | None = None,
        limit: int = 100,
    ) -> list[dict[str, Any]]:
        builder = (
            self._client.table("tester_reports")
            .select(
                "id, user_id, type, title, description, severity, screenshots, device, app_version, contact, status, created_at, updated_at"
            )
            .order("created_at", desc=True)
            .limit(limit)
        )
        if user_id:
            builder = builder.eq("user_id", user_id)
        if status:
            builder = builder.eq("status", status)
        if report_type:
            builder = builder.eq("type", report_type)
        result = builder.execute()
        return result.data or []

    def update_tester_report_status(self, report_id: str, status: str) -> dict[str, Any]:
        result = (
            self._client.table("tester_reports")
            .update({"status": status})
            .eq("id", report_id)
            .execute()
        )
        return result.data[0] if result.data else {}
