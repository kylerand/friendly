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
        try:
            result = (
                self._client.table("profiles")
                .select("*")
                .eq("id", user_id)
                .maybe_single()
                .execute()
            )
            return result.data if result else None
        except Exception:
            return None

    def upsert_profile(self, user_id: str, display_name: str, **kwargs: Any) -> dict[str, Any]:
        payload = {"id": user_id, "display_name": display_name, **kwargs}
        result = (
            self._client.table("profiles")
            .upsert(payload, on_conflict="id")
            .execute()
        )
        return result.data[0] if result.data else payload

    def update_profile(self, user_id: str, **kwargs: Any) -> dict[str, Any]:
        """Partial update of an existing profile. Only the supplied fields are changed;
        unspecified fields (including push_opt_in) are left untouched."""
        self._client.table("profiles").update(kwargs).eq("id", user_id).execute()
        return self.get_profile(user_id) or {}

    def delete_account(self, user_id: str) -> None:
        """Delete user profile and auth account.

        Profile row cascades to friendships, interactions, notes, reminders, etc.
        The auth.users row is removed via the admin API.
        """
        # Delete profile (cascades to all dependent tables)
        self._client.table("profiles").delete().eq("id", user_id).execute()
        # Delete Supabase Auth user
        self._client.auth.admin.delete_user(user_id)

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
        try:
            result = (
                self._client.table("friendships")
                .select("*")
                .eq("id", friendship_id)
                .maybe_single()
                .execute()
            )
            return result.data if result else None
        except Exception:
            return None

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
        try:
            result = (
                self._client.table("admin_users")
                .select("user_id, role, created_at")
                .eq("user_id", user_id)
                .maybe_single()
                .execute()
            )
            return result.data if result else None
        except Exception:
            return None

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
        try:
            result = (
                self._client.table("user_roles")
                .select("user_id, role, created_at")
                .eq("user_id", user_id)
                .maybe_single()
                .execute()
            )
            return result.data if result else None
        except Exception:
            return None

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

    def update_tester_report_github_issue(
        self, report_id: str, issue_url: str, issue_number: int
    ) -> dict[str, Any]:
        result = (
            self._client.table("tester_reports")
            .update({"github_issue_url": issue_url, "github_issue_number": issue_number})
            .eq("id", report_id)
            .execute()
        )
        return result.data[0] if result.data else {}

    def get_tester_report(self, report_id: str) -> dict[str, Any] | None:
        result = (
            self._client.table("tester_reports")
            .select("*")
            .eq("id", report_id)
            .execute()
        )
        return result.data[0] if result.data else None

    # -- Friend Notes --

    def get_friend_note(self, user_id: str, friend_id: str) -> dict[str, Any] | None:
        try:
            result = (
                self._client.table("friend_notes")
                .select("*")
                .eq("user_id", user_id)
                .eq("friend_id", friend_id)
                .maybe_single()
                .execute()
            )
            return result.data if result else None
        except Exception:
            return None

    def upsert_friend_note(self, user_id: str, friend_id: str, content: str) -> dict[str, Any]:
        payload = {
            "user_id": user_id,
            "friend_id": friend_id,
            "content": content,
        }
        result = (
            self._client.table("friend_notes")
            .upsert(payload, on_conflict="user_id,friend_id")
            .execute()
        )
        return result.data[0] if result.data else payload

    def delete_friend_note(self, user_id: str, friend_id: str) -> bool:
        self._client.table("friend_notes").delete().eq(
            "user_id", user_id
        ).eq("friend_id", friend_id).execute()
        return True

    # -- Friend Reminders --------------------------------------------------

    def get_friend_reminder(self, user_id: str, friend_id: str) -> dict[str, Any] | None:
        try:
            result = (
                self._client.table("friend_reminders")
                .select("*")
                .eq("user_id", user_id)
                .eq("friend_id", friend_id)
                .limit(1)
                .execute()
            )
            return result.data[0] if result.data else None
        except Exception:
            return None

    def list_friend_reminders(self, user_id: str) -> list[dict[str, Any]]:
        result = (
            self._client.table("friend_reminders")
            .select("*")
            .eq("user_id", user_id)
            .execute()
        )
        return result.data or []

    def upsert_friend_reminder(
        self, user_id: str, friend_id: str, text: str, interval_days: int
    ) -> dict[str, Any]:
        payload = {
            "user_id": user_id,
            "friend_id": friend_id,
            "text": text,
            "interval_days": interval_days,
        }
        result = (
            self._client.table("friend_reminders")
            .upsert(payload, on_conflict="user_id,friend_id")
            .execute()
        )
        return result.data[0] if result.data else payload

    def update_friend_reminder(
        self, user_id: str, friend_id: str, updates: dict[str, Any]
    ) -> dict[str, Any] | None:
        result = (
            self._client.table("friend_reminders")
            .update(updates)
            .eq("user_id", user_id)
            .eq("friend_id", friend_id)
            .execute()
        )
        return result.data[0] if result.data else None

    def delete_friend_reminder(self, user_id: str, friend_id: str) -> bool:
        self._client.table("friend_reminders").delete().eq(
            "user_id", user_id
        ).eq("friend_id", friend_id).execute()
        return True

    # -- Push / Nudge -------------------------------------------------------

    def update_push_token(self, user_id: str, token: str) -> None:
        self._client.table("profiles").update(
            {"push_token": token}
        ).eq("id", user_id).execute()

    def update_nudge_preferences(
        self, user_id: str, push_opt_in: bool | None = None,
        preferred_nudge_time: str | None = None,
    ) -> dict[str, Any]:
        payload: dict[str, Any] = {}
        if push_opt_in is not None:
            payload["push_opt_in"] = push_opt_in
        if preferred_nudge_time is not None:
            payload["preferred_nudge_time"] = preferred_nudge_time
        if not payload:
            return self.get_profile(user_id) or {}
        self._client.table("profiles").update(payload).eq("id", user_id).execute()
        return self.get_profile(user_id) or {}

    def get_nudge_preferences(self, user_id: str) -> dict[str, Any]:
        profile = self.get_profile(user_id)
        if not profile:
            return {}
        return {
            "push_opt_in": profile.get("push_opt_in", False),
            "preferred_nudge_time": profile.get("preferred_nudge_time", "18:00"),
            "last_nudge_sent_at": profile.get("last_nudge_sent_at"),
            "nudge_cycle_count": profile.get("nudge_cycle_count", 0),
        }

    # -- Warmth Snapshots ---------------------------------------------------

    def upsert_warmth_snapshot(self, user_id: str, data: dict[str, Any]) -> dict[str, Any]:
        payload = {"user_id": user_id, **data}
        # Keep only the latest snapshot per user
        self._client.table("warmth_snapshots").delete().eq("user_id", user_id).execute()
        result = self._client.table("warmth_snapshots").insert(payload).execute()
        return result.data[0] if result.data else payload

    def get_warmth_snapshot(self, user_id: str) -> dict[str, Any] | None:
        try:
            result = (
                self._client.table("warmth_snapshots")
                .select("*")
                .eq("user_id", user_id)
                .order("snapshot_at", desc=True)
                .limit(1)
                .maybe_single()
                .execute()
            )
            return result.data if result else None
        except Exception:
            return None

    # -- Nudge Log ----------------------------------------------------------

    def create_nudge_log(
        self, user_id: str, nudge_tier: str, copy_text: str,
        friend_id: str | None = None,
    ) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "user_id": user_id,
            "nudge_tier": nudge_tier,
            "copy_text": copy_text,
        }
        if friend_id:
            payload["friend_id"] = friend_id
        result = self._client.table("nudge_log").insert(payload).execute()
        return result.data[0] if result.data else payload

    def acknowledge_nudge(self, nudge_id: str) -> None:
        self._client.table("nudge_log").update(
            {"acknowledged_at": datetime.utcnow().isoformat()}
        ).eq("id", nudge_id).execute()

    def get_recent_nudge_count(self, user_id: str, since: datetime) -> int:
        result = (
            self._client.table("nudge_log")
            .select("id", count="exact")
            .eq("user_id", user_id)
            .gte("sent_at", since.isoformat())
            .execute()
        )
        return result.count or 0

    # -- Milestones ---------------------------------------------------------

    def list_milestones(self, user_id: str) -> list[dict[str, Any]]:
        result = (
            self._client.table("milestones")
            .select("*")
            .eq("user_id", user_id)
            .order("achieved_at", desc=True)
            .execute()
        )
        return result.data or []

    def create_milestone(self, user_id: str, milestone_key: str) -> dict[str, Any] | None:
        """Insert milestone if not already achieved. Returns None if duplicate."""
        try:
            result = self._client.table("milestones").insert({
                "user_id": user_id,
                "milestone_key": milestone_key,
            }).execute()
            return result.data[0] if result.data else None
        except Exception:
            return None  # unique constraint — already achieved

    def has_milestone(self, user_id: str, milestone_key: str) -> bool:
        try:
            result = (
                self._client.table("milestones")
                .select("id")
                .eq("user_id", user_id)
                .eq("milestone_key", milestone_key)
                .maybe_single()
                .execute()
            )
            return result.data is not None if result else False
        except Exception:
            return False

    # -- Rest Days ----------------------------------------------------------

    def add_rest_day(self, user_id: str, rest_date: str | None = None) -> dict[str, Any]:
        from datetime import date as d
        payload: dict[str, Any] = {"user_id": user_id}
        if rest_date:
            payload["rest_date"] = rest_date
        else:
            payload["rest_date"] = d.today().isoformat()
        try:
            result = self._client.table("rest_days").insert(payload).execute()
            return result.data[0] if result.data else payload
        except Exception:
            return payload  # already exists

    def count_rest_days_this_week(self, user_id: str) -> int:
        from datetime import date, timedelta
        today = date.today()
        week_start = today - timedelta(days=today.weekday())
        result = (
            self._client.table("rest_days")
            .select("id", count="exact")
            .eq("user_id", user_id)
            .gte("rest_date", week_start.isoformat())
            .execute()
        )
        return result.count or 0

    def is_rest_day(self, user_id: str, check_date: str | None = None) -> bool:
        from datetime import date as d
        date_str = check_date or d.today().isoformat()
        try:
            result = (
                self._client.table("rest_days")
                .select("id")
                .eq("user_id", user_id)
                .eq("rest_date", date_str)
                .maybe_single()
                .execute()
            )
            return result.data is not None if result else False
        except Exception:
            return False

    # -- Eligible users for nudge dispatch ----------------------------------

    def list_nudge_eligible_users(self) -> list[dict[str, Any]]:
        """Return profiles with push_opt_in=true and a push_token."""
        result = (
            self._client.table("profiles")
            .select("id, push_token, preferred_nudge_time, last_nudge_sent_at, nudge_cycle_count")
            .eq("push_opt_in", True)
            .not_.is_("push_token", "null")
            .execute()
        )
        return result.data or []

    def mark_nudge_sent(self, user_id: str) -> None:
        self._client.table("profiles").update({
            "last_nudge_sent_at": datetime.utcnow().isoformat(),
            "nudge_cycle_count": self._client.rpc(
                "increment_nudge_cycle", {"uid": user_id}
            ) if False else None,  # handled in Python
        }).eq("id", user_id).execute()

    def increment_nudge_cycle(self, user_id: str) -> None:
        profile = self.get_profile(user_id)
        count = (profile or {}).get("nudge_cycle_count", 0)
        self._client.table("profiles").update({
            "nudge_cycle_count": count + 1,
            "last_nudge_sent_at": datetime.utcnow().isoformat(),
        }).eq("id", user_id).execute()

    def reset_nudge_cycle(self, user_id: str) -> None:
        self._client.table("profiles").update({
            "nudge_cycle_count": 0,
        }).eq("id", user_id).execute()
