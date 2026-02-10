"""
Nudges Router

Server-side nudge computation for the caring-rhythm system.
Determines which friends a user should be nudged to reach out to,
based on interaction recency and connection drift.

All operations are scoped to the authenticated user via JWT.

Design philosophy (from NUDGE_SYSTEM.md):
- Max 1 nudge per day, max 4 per absence cycle
- Escalating warmth, never guilt
- "Protect the channel" — never destroy push notification trust
"""

from datetime import datetime, timedelta, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.db.repository import Repository
from app.dependencies import get_current_user_id, get_repository

router = APIRouter(prefix="/nudges", tags=["nudges"])


# --------------------------------------------------------------------------
# Response models
# --------------------------------------------------------------------------

class FriendSuggestion(BaseModel):
    friend_id: str
    friend_name: str
    days_since_contact: int


class WarmthSnapshot(BaseModel):
    """Server-computed warmth state for the authenticated user."""
    warmth_tier: str  # 'radiant' | 'warm' | 'gentle' | 'quiet'
    week_streak: int
    days_since_outreach: int
    suggested_friend: Optional[FriendSuggestion] = None
    nudge_tier: Optional[str] = None  # escalation tier, null if active recently


class NudgeEligibility(BaseModel):
    """Whether a push notification should be sent, and what content."""
    eligible: bool
    reason: str
    nudge_tier: Optional[str] = None
    copy: Optional[str] = None
    friend_name: Optional[str] = None


# --------------------------------------------------------------------------
# Nudge copy (server-side, for push dispatch)
# --------------------------------------------------------------------------

NUDGE_COPY = {
    "gentle_observation": [
        "Your people are still here whenever you're ready. 💛",
        "No rush. Just a gentle hello from Friendly. 🫧",
    ],
    "warm_invitation": [
        "It's been a quiet week. Even a quick hello can mean a lot.",
        "A small reach-out can go a long way. Someone might be thinking of you too.",
    ],
    "caring_concern": [
        "{name} might appreciate hearing from you. One small reach-out?",
        "It's been a little while since you and {name} connected.",
    ],
    "respectful_silence": [
        "We'll keep things warm here. Come back whenever feels right. 🫧",
        "No pressure, no rush. Friendly is here when you need it. 💛",
    ],
}


# --------------------------------------------------------------------------
# Warmth computation helpers
# --------------------------------------------------------------------------

def _compute_warmth_tier(week_streak: int, had_activity_this_week: bool) -> str:
    if week_streak >= 3:
        return "radiant"
    if week_streak >= 1:
        return "warm"
    if had_activity_this_week:
        return "gentle"
    return "quiet"


def _compute_nudge_tier(days_since_activity: int) -> Optional[str]:
    if days_since_activity >= 21:
        return "respectful_silence"
    if days_since_activity >= 14:
        return "caring_concern"
    if days_since_activity >= 7:
        return "warm_invitation"
    if days_since_activity >= 3:
        return "gentle_observation"
    return None


def _pick_copy(tier: str, friend_name: Optional[str] = None) -> str:
    import random
    variants = NUDGE_COPY.get(tier, NUDGE_COPY["gentle_observation"])
    raw = random.choice(variants)
    if friend_name:
        return raw.replace("{name}", friend_name)
    return raw


# --------------------------------------------------------------------------
# Endpoints
# --------------------------------------------------------------------------

@router.get("/warmth", response_model=WarmthSnapshot)
def get_warmth(
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """
    Compute the user's current caring-rhythm warmth snapshot.

    Returns warmth tier, week streak, friend suggestion, and nudge tier.
    """
    now = datetime.now(timezone.utc)
    week_start = now - timedelta(days=now.weekday())
    week_start = week_start.replace(hour=0, minute=0, second=0, microsecond=0)

    # Fetch recent interactions and check-ins
    interactions = repo.list_interactions(user_id, limit=200)
    check_ins = repo.list_check_ins(user_id, limit=50)

    # Find the most recent activity timestamp
    all_timestamps = []
    for i in interactions:
        ts = i.get("created_at")
        if isinstance(ts, str):
            ts = datetime.fromisoformat(ts)
        if ts:
            all_timestamps.append(ts)
    for c in check_ins:
        ts = c.get("created_at")
        if isinstance(ts, str):
            ts = datetime.fromisoformat(ts)
        if ts:
            all_timestamps.append(ts)

    all_timestamps.sort(reverse=True)
    last_outreach = all_timestamps[0] if all_timestamps else None

    if last_outreach:
        # Ensure timezone-aware comparison
        if last_outreach.tzinfo is None:
            last_outreach = last_outreach.replace(tzinfo=timezone.utc)
        days_since = (now - last_outreach).days
    else:
        days_since = 999

    # Check this week's activity
    had_activity_this_week = any(
        (ts.replace(tzinfo=timezone.utc) if ts.tzinfo is None else ts) >= week_start
        for ts in all_timestamps
    )

    # Compute week streak (simplified — count consecutive weeks with activity)
    week_streak = 0
    check_week = week_start
    for _ in range(52):  # max 1 year
        prev_week = check_week - timedelta(days=7)
        week_had_activity = any(
            prev_week <= (ts.replace(tzinfo=timezone.utc) if ts.tzinfo is None else ts) < check_week
            for ts in all_timestamps
        )
        if week_had_activity:
            week_streak += 1
            check_week = prev_week
        else:
            break

    if had_activity_this_week:
        week_streak += 1

    # Find friend with longest gap
    friendships = repo.list_friendships(user_id)
    suggested = None
    longest_gap = 6  # Only suggest if 7+ days

    for f in friendships:
        if f.get("status") != "confirmed":
            continue
        friend_id = f["friend_id"] if f["user_id"] == user_id else f["user_id"]
        # Find last interaction with this friend
        friend_interactions = [
            i for i in interactions if i.get("target_id") == friend_id
        ]
        if friend_interactions:
            last_ts = max(
                (datetime.fromisoformat(i["created_at"]) if isinstance(i["created_at"], str) else i["created_at"])
                for i in friend_interactions
            )
            if last_ts.tzinfo is None:
                last_ts = last_ts.replace(tzinfo=timezone.utc)
            gap = (now - last_ts).days
        else:
            gap = 999

        if gap > longest_gap:
            longest_gap = gap
            # Fetch friend's name
            friend_profile = repo.get_profile(friend_id)
            friend_name = friend_profile.get("display_name", "a friend") if friend_profile else "a friend"
            suggested = FriendSuggestion(
                friend_id=friend_id,
                friend_name=friend_name,
                days_since_contact=gap,
            )

    tier = _compute_warmth_tier(week_streak, had_activity_this_week)
    nudge_tier = _compute_nudge_tier(days_since)

    return WarmthSnapshot(
        warmth_tier=tier,
        week_streak=week_streak,
        days_since_outreach=days_since,
        suggested_friend=suggested,
        nudge_tier=nudge_tier,
    )


@router.get("/eligible", response_model=NudgeEligibility)
def check_nudge_eligibility(
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """
    Check if a push notification should be dispatched for this user.

    Returns eligibility status, escalation tier, and suggested copy.
    Used by background jobs or server-side push dispatch.
    """
    warmth = get_warmth(user_id=user_id, repo=repo)

    if warmth.nudge_tier is None:
        return NudgeEligibility(
            eligible=False,
            reason="User active recently — no nudge needed",
        )

    friend_name = warmth.suggested_friend.friend_name if warmth.suggested_friend else None
    copy = _pick_copy(warmth.nudge_tier, friend_name)

    return NudgeEligibility(
        eligible=True,
        reason=f"User absent for {warmth.days_since_outreach} days — {warmth.nudge_tier} tier",
        nudge_tier=warmth.nudge_tier,
        copy=copy,
        friend_name=friend_name,
    )
