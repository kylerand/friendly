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


def _compute_effective_nudge_tier(
    days_since_activity: int,
    suggested_friend: Optional[FriendSuggestion],
) -> Optional[str]:
    """
    Reminder nudges are friend-drift nudges first.

    A user can be generally active while one friendship has gone quiet. In that
    case, use the suggested friend's gap instead of suppressing the nudge just
    because the user recently checked in or contacted someone else.
    """
    if suggested_friend is not None:
        friend_tier = _compute_nudge_tier(suggested_friend.days_since_contact)
        if friend_tier is not None:
            return friend_tier
    return _compute_nudge_tier(days_since_activity)


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
    nudge_tier = _compute_effective_nudge_tier(days_since, suggested)

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
    if warmth.suggested_friend:
        reason = (
            f"{warmth.suggested_friend.friend_name} has drifted for "
            f"{warmth.suggested_friend.days_since_contact} days — "
            f"{warmth.nudge_tier} tier"
        )
    else:
        reason = (
            f"User absent for {warmth.days_since_outreach} days — "
            f"{warmth.nudge_tier} tier"
        )

    return NudgeEligibility(
        eligible=True,
        reason=reason,
        nudge_tier=warmth.nudge_tier,
        copy=copy,
        friend_name=friend_name,
    )


# --------------------------------------------------------------------------
# Push token & preferences
# --------------------------------------------------------------------------

class PushTokenRequest(BaseModel):
    token: str


class NudgePreferencesRequest(BaseModel):
    push_opt_in: Optional[bool] = None
    preferred_nudge_time: Optional[str] = None  # "HH:MM"


class NudgePreferencesResponse(BaseModel):
    push_opt_in: bool
    preferred_nudge_time: str
    last_nudge_sent_at: Optional[str] = None
    nudge_cycle_count: int


@router.post("/register-push-token")
def register_push_token(
    body: PushTokenRequest,
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    repo.update_push_token(user_id, body.token)
    return {"ok": True}


@router.get("/preferences", response_model=NudgePreferencesResponse)
def get_nudge_preferences(
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    prefs = repo.get_nudge_preferences(user_id)
    return NudgePreferencesResponse(
        push_opt_in=prefs.get("push_opt_in", False),
        preferred_nudge_time=prefs.get("preferred_nudge_time", "18:00"),
        last_nudge_sent_at=prefs.get("last_nudge_sent_at"),
        nudge_cycle_count=prefs.get("nudge_cycle_count", 0),
    )


@router.put("/preferences", response_model=NudgePreferencesResponse)
def update_nudge_preferences(
    body: NudgePreferencesRequest,
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    repo.update_nudge_preferences(
        user_id,
        push_opt_in=body.push_opt_in,
        preferred_nudge_time=body.preferred_nudge_time,
    )
    return get_nudge_preferences(user_id=user_id, repo=repo)


# --------------------------------------------------------------------------
# Milestones
# --------------------------------------------------------------------------

MILESTONE_DEFS = {
    "first_outreach": {"min_interactions": 1},
    "3_day_rhythm": {"min_week_streak": 0, "min_days_active": 3},
    "7_day_rhythm": {"min_week_streak": 1},
    "1_month_rhythm": {"min_week_streak": 4},
    "3_month_rhythm": {"min_week_streak": 12},
}

MILESTONE_COPY = {
    "first_outreach": {"emoji": "🌱", "copy": "You showed up for someone today."},
    "3_day_rhythm": {"emoji": "💚", "copy": "Three days of caring. That's something special."},
    "7_day_rhythm": {"emoji": "🌤️", "copy": "A week of warmth. Your people feel it."},
    "1_month_rhythm": {"emoji": "🔥", "copy": "A month of gentle attention. You're building something real."},
    "3_month_rhythm": {"emoji": "💛", "copy": "Three months of showing up. That's a rare and beautiful thing."},
}


class MilestoneResponse(BaseModel):
    milestone_key: str
    achieved_at: str
    emoji: str
    copy: str


class MilestoneCheckResponse(BaseModel):
    new_milestones: List[MilestoneResponse]
    all_milestones: List[MilestoneResponse]


@router.get("/milestones")
def list_milestones(
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    rows = repo.list_milestones(user_id)
    return [
        MilestoneResponse(
            milestone_key=r["milestone_key"],
            achieved_at=str(r["achieved_at"]),
            emoji=MILESTONE_COPY.get(r["milestone_key"], {}).get("emoji", "✨"),
            copy=MILESTONE_COPY.get(r["milestone_key"], {}).get("copy", ""),
        )
        for r in rows
    ]


@router.post("/milestones/check", response_model=MilestoneCheckResponse)
def check_milestones(
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """Compute & persist any newly achieved milestones."""
    warmth = get_warmth(user_id=user_id, repo=repo)
    interactions = repo.list_interactions(user_id, limit=200)

    new_milestones: List[MilestoneResponse] = []

    # first_outreach
    if len(interactions) >= 1 and not repo.has_milestone(user_id, "first_outreach"):
        m = repo.create_milestone(user_id, "first_outreach")
        if m:
            info = MILESTONE_COPY["first_outreach"]
            new_milestones.append(MilestoneResponse(
                milestone_key="first_outreach",
                achieved_at=str(m["achieved_at"]),
                emoji=info["emoji"], copy=info["copy"],
            ))

    # Week-streak based milestones
    streak_milestones = [
        ("7_day_rhythm", 1),
        ("1_month_rhythm", 4),
        ("3_month_rhythm", 12),
    ]
    for key, min_streak in streak_milestones:
        if warmth.week_streak >= min_streak and not repo.has_milestone(user_id, key):
            m = repo.create_milestone(user_id, key)
            if m:
                info = MILESTONE_COPY[key]
                new_milestones.append(MilestoneResponse(
                    milestone_key=key,
                    achieved_at=str(m["achieved_at"]),
                    emoji=info["emoji"], copy=info["copy"],
                ))

    # 3-day rhythm: check if user has interactions on 3 distinct days in last 7 days
    now = datetime.now(timezone.utc)
    recent_dates = set()
    for i in interactions:
        ts = i.get("created_at")
        if isinstance(ts, str):
            ts = datetime.fromisoformat(ts)
        if ts:
            if ts.tzinfo is None:
                ts = ts.replace(tzinfo=timezone.utc)
            if (now - ts).days <= 7:
                recent_dates.add(ts.date())
    if len(recent_dates) >= 3 and not repo.has_milestone(user_id, "3_day_rhythm"):
        m = repo.create_milestone(user_id, "3_day_rhythm")
        if m:
            info = MILESTONE_COPY["3_day_rhythm"]
            new_milestones.append(MilestoneResponse(
                milestone_key="3_day_rhythm",
                achieved_at=str(m["achieved_at"]),
                emoji=info["emoji"], copy=info["copy"],
            ))

    all_rows = repo.list_milestones(user_id)
    all_milestones = [
        MilestoneResponse(
            milestone_key=r["milestone_key"],
            achieved_at=str(r["achieved_at"]),
            emoji=MILESTONE_COPY.get(r["milestone_key"], {}).get("emoji", "✨"),
            copy=MILESTONE_COPY.get(r["milestone_key"], {}).get("copy", ""),
        )
        for r in all_rows
    ]

    return MilestoneCheckResponse(
        new_milestones=new_milestones,
        all_milestones=all_milestones,
    )


# --------------------------------------------------------------------------
# Warmth snapshot (cache for widgets)
# --------------------------------------------------------------------------

@router.post("/warmth/snapshot")
def save_warmth_snapshot(
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """Compute warmth and cache it for widget consumption."""
    warmth = get_warmth(user_id=user_id, repo=repo)
    data = {
        "warmth_tier": warmth.warmth_tier,
        "week_streak": warmth.week_streak,
        "last_outreach_at": None,
        "suggested_friend_id": warmth.suggested_friend.friend_id if warmth.suggested_friend else None,
        "suggested_friend_name": warmth.suggested_friend.friend_name if warmth.suggested_friend else None,
    }
    return repo.upsert_warmth_snapshot(user_id, data)


@router.get("/warmth/snapshot")
def get_warmth_snapshot(
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    snapshot = repo.get_warmth_snapshot(user_id)
    if not snapshot:
        return save_warmth_snapshot(user_id=user_id, repo=repo)
    return snapshot


# --------------------------------------------------------------------------
# Rest days
# --------------------------------------------------------------------------

class RestDayResponse(BaseModel):
    is_rest_day: bool
    rest_days_used_this_week: int
    rest_days_remaining: int  # out of 2 per week


@router.post("/rest-day", response_model=RestDayResponse)
def take_rest_day(
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    used = repo.count_rest_days_this_week(user_id)
    if used >= 2:
        return RestDayResponse(
            is_rest_day=repo.is_rest_day(user_id),
            rest_days_used_this_week=used,
            rest_days_remaining=0,
        )
    repo.add_rest_day(user_id)
    used = repo.count_rest_days_this_week(user_id)
    return RestDayResponse(
        is_rest_day=True,
        rest_days_used_this_week=used,
        rest_days_remaining=max(0, 2 - used),
    )


@router.get("/rest-day", response_model=RestDayResponse)
def get_rest_day_status(
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    used = repo.count_rest_days_this_week(user_id)
    return RestDayResponse(
        is_rest_day=repo.is_rest_day(user_id),
        rest_days_used_this_week=used,
        rest_days_remaining=max(0, 2 - used),
    )
