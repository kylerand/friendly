"""
Signals Router — Care signals & support beacons.

Care signal: A quiet "thinking of you" sent to a single friend.
  - Stored as an interaction (type = 'care_signal') so it shows up
    in the recipient's awareness without exposing any content.
  - Cooldown: one per friend per 24 hours.

Support beacon: A "I could use some warmth" broadcast to all friends.
  - Stored as an ambient signal (signal_type = 'support_beacon').
  - Auto-expires after 24 hours.
  - Friends can query for active beacons.
  - Only one active beacon per user at a time.

Privacy: No message content, no location, no reason. Just a
presence signal — "someone you care about could use warmth."
"""

from datetime import datetime, timedelta, timezone
import logging

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from uuid import UUID

from app.db.repository import Repository
from app.dependencies import get_current_user_id, get_repository
from app.services.push_dispatcher import dispatch_beacon_alert

router = APIRouter(prefix="/signals", tags=["signals"])
logger = logging.getLogger("friendly.signals")

# --------------------------------------------------------------------------
# Request / response models
# --------------------------------------------------------------------------

class CareSignalRequest(BaseModel):
    friend_id: UUID


class CareSignalResponse(BaseModel):
    sent: bool
    message: str


class BeaconResponse(BaseModel):
    active: bool
    activated_at: str | None = None
    notified_count: int = 0
    reachable_friends: int = 0


class FriendBeacon(BaseModel):
    user_id: str
    display_name: str
    activated_at: str


# --------------------------------------------------------------------------
# Care signal — thinking-of-you nudge to a single friend
# --------------------------------------------------------------------------

@router.post("/care", response_model=CareSignalResponse)
def send_care_signal(
    body: CareSignalRequest,
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """
    Send a care signal to a friend.

    Enforces a 24-hour cooldown per friend — you can't spam warmth.
    Creates an interaction of type 'care_signal' that the recipient
    can see in their interactions feed.
    """
    friend_id = str(body.friend_id)

    # Verify friendship exists and is confirmed
    friendships = repo.list_friendships(user_id)
    is_friend = any(
        (f.get("user_id") == user_id and f.get("friend_id") == friend_id and f.get("status") == "confirmed")
        or (f.get("friend_id") == user_id and f.get("user_id") == friend_id and f.get("status") == "confirmed")
        for f in friendships
    )
    if not is_friend:
        raise HTTPException(status_code=403, detail="You can only send care signals to confirmed friends.")

    # Check 24h cooldown — look for recent care_signal interactions to this friend
    interactions = repo.list_interactions(user_id, limit=100)
    cutoff = datetime.now(timezone.utc) - timedelta(hours=24)
    recently_sent = any(
        i.get("target_id") == friend_id
        and i.get("type") == "care_signal"
        and _parse_ts(i.get("created_at", "")) > cutoff
        for i in interactions
    )
    if recently_sent:
        return CareSignalResponse(
            sent=False,
            message="You already sent warmth to this person today. They felt it. 💛",
        )

    # Create the care signal interaction
    repo.create_interaction(
        user_id=user_id,
        target_id=friend_id,
        interaction_type="care_signal",
        metadata={"signal": "care"},
    )

    return CareSignalResponse(sent=True, message="Sent — they'll feel it. 💛")


# --------------------------------------------------------------------------
# Support beacon — "I could use some warmth" broadcast
# --------------------------------------------------------------------------

@router.post("/beacon", response_model=BeaconResponse)
def activate_beacon(
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """
    Activate a support beacon. Friends will see a gentle indicator
    that you could use warmth. Auto-expires after 24 hours.

    Only one active beacon per user at a time.
    """
    # Check if there's already an active beacon
    signals = repo.list_ambient_signals(user_id, limit=10)
    cutoff = datetime.now(timezone.utc) - timedelta(hours=24)
    active = [
        s for s in signals
        if s.get("signal_type") == "support_beacon"
        and s.get("value", 0) == 1.0
        and _parse_ts(s.get("created_at", "")) > cutoff
    ]
    if active:
        return BeaconResponse(active=True, activated_at=active[0].get("created_at"))

    # Create the beacon
    signal = repo.create_ambient_signal(
        user_id=user_id,
        signal_type="support_beacon",
        value=1.0,
        tags=["beacon"],
    )
    delivery = _dispatch_beacon_to_friends(repo, user_id)

    return BeaconResponse(
        active=True,
        activated_at=signal.get("created_at"),
        notified_count=delivery["sent"],
        reachable_friends=delivery["reachable"],
    )


@router.delete("/beacon", response_model=BeaconResponse)
def deactivate_beacon(
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """
    Deactivate the user's support beacon by setting value to 0.

    We don't delete the record — we mark it inactive so we preserve
    the history for the user's own awareness (not shared with anyone).
    """
    signals = repo.list_ambient_signals(user_id, limit=10)
    cutoff = datetime.now(timezone.utc) - timedelta(hours=24)

    for s in signals:
        if (
            s.get("signal_type") == "support_beacon"
            and s.get("value", 0) == 1.0
            and _parse_ts(s.get("created_at", "")) > cutoff
        ):
            # Deactivate by updating the value to 0
            repo.update_ambient_signal(s["id"], value=0.0)

    return BeaconResponse(active=False, activated_at=None)


@router.get("/beacon", response_model=BeaconResponse)
def get_my_beacon(
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """Check if the authenticated user has an active beacon."""
    signals = repo.list_ambient_signals(user_id, limit=10)
    cutoff = datetime.now(timezone.utc) - timedelta(hours=24)
    active = [
        s for s in signals
        if s.get("signal_type") == "support_beacon"
        and s.get("value", 0) == 1.0
        and _parse_ts(s.get("created_at", "")) > cutoff
    ]
    if active:
        return BeaconResponse(active=True, activated_at=active[0].get("created_at"))
    return BeaconResponse(active=False, activated_at=None)


@router.get("/beacons/friends")
def get_friend_beacons(
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """
    Get active support beacons from confirmed friends.

    Returns a list of friends who have activated a beacon in the
    last 24 hours. This is the only place where one user's beacon
    state is visible to another user — and only to confirmed friends.
    """
    # Get confirmed friend IDs
    friendships = repo.list_friendships(user_id)
    friend_ids: list[str] = []
    for f in friendships:
        if f.get("status") != "confirmed":
            continue
        if f.get("user_id") == user_id:
            friend_ids.append(f["friend_id"])
        elif f.get("friend_id") == user_id:
            friend_ids.append(f["user_id"])

    if not friend_ids:
        return []

    # Check each friend for active beacons
    cutoff = datetime.now(timezone.utc) - timedelta(hours=24)
    active_beacons: list[dict] = []

    for fid in friend_ids:
        signals = repo.list_ambient_signals(fid, limit=5)
        for s in signals:
            if (
                s.get("signal_type") == "support_beacon"
                and s.get("value", 0) == 1.0
                and _parse_ts(s.get("created_at", "")) > cutoff
            ):
                # Resolve friend name
                profile = repo.get_profile(fid)
                active_beacons.append({
                    "user_id": fid,
                    "display_name": profile.get("display_name", "Friend") if profile else "Friend",
                    "activated_at": s.get("created_at"),
                })
                break  # Only one beacon per friend matters

    return active_beacons


@router.get("/care/received")
def get_received_care_signals(
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """
    Get care signals received by the authenticated user in the last 7 days.

    This lets the user see that someone was thinking of them,
    without revealing who (for now — could be configurable later).

    Note: We query interactions where target_id = current user and
    type = care_signal. This requires a custom query since the
    standard list_interactions filters by user_id (sender).
    """
    received = repo.list_received_care_signals(user_id, days=7)
    return received


# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------

def _parse_ts(ts_str: str) -> datetime:
    """Parse an ISO timestamp string into a timezone-aware datetime."""
    if not ts_str:
        return datetime.min.replace(tzinfo=timezone.utc)
    try:
        # Handle various ISO formats from Supabase
        ts_str = ts_str.replace("Z", "+00:00")
        dt = datetime.fromisoformat(ts_str)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt
    except (ValueError, TypeError):
        return datetime.min.replace(tzinfo=timezone.utc)


def _confirmed_friend_ids(repo: Repository, user_id: str) -> list[str]:
    friendships = repo.list_friendships(user_id)
    friend_ids: list[str] = []
    seen: set[str] = set()
    for f in friendships:
        if f.get("status") != "confirmed":
            continue
        friend_id = None
        if f.get("user_id") == user_id:
            friend_id = f.get("friend_id")
        elif f.get("friend_id") == user_id:
            friend_id = f.get("user_id")
        if friend_id and friend_id not in seen:
            seen.add(friend_id)
            friend_ids.append(friend_id)
    return friend_ids


def _dispatch_beacon_to_friends(repo: Repository, user_id: str) -> dict[str, int]:
    profile = repo.get_profile(user_id) or {}
    sender_name = profile.get("display_name") or "A friend"
    sent = 0
    reachable = 0

    for friend_id in _confirmed_friend_ids(repo, user_id):
        try:
            result = dispatch_beacon_alert(repo, friend_id, user_id, sender_name)
        except Exception as e:
            logger.warning(f"Beacon alert dispatch failed for friend {friend_id}: {e}")
            continue
        if result.get("reachable"):
            reachable += 1
        if result.get("sent"):
            sent += 1

    logger.info(
        "Beacon activated for %s; sent %s/%s reachable friend alerts",
        user_id,
        sent,
        reachable,
    )
    return {"sent": sent, "reachable": reachable}
