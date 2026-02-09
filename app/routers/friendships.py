"""
Friendships Router

Manages directional friendship records with explicit status transitions.
Mutual confirmation = both sides have status 'confirmed'.

All operations are scoped to the authenticated user via JWT.
"""

from typing import List

from fastapi import APIRouter, Depends, HTTPException

from app.db.repository import Repository
from app.dependencies import get_current_user_id, get_repository
from app.schemas.models import (
    FriendshipCreate,
    FriendshipResponse,
    FriendshipStatusUpdate,
)

router = APIRouter(prefix="/friendships", tags=["friendships"])


@router.post("/", response_model=dict)
def add_friendship(
    body: FriendshipCreate,
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """Send a friendship request. Creates a directional row with status=pending."""
    if str(body.friend_id) == user_id:
        raise HTTPException(status_code=400, detail="Cannot friend yourself")

    # Prevent duplicate directional friendships: check if a row already exists
    existing = [f for f in repo.list_friendships(user_id) if f.get('user_id') == user_id and f.get('friend_id') == str(body.friend_id)]
    if existing:
        # Return a controlled 409 Conflict with a helpful message
        raise HTTPException(status_code=409, detail="Friendship already exists")

    friendship = repo.create_friendship(user_id, str(body.friend_id))
    return friendship


@router.get("/", response_model=List[FriendshipResponse])
def list_friendships(
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """List all friendships where the authenticated user is a participant."""
    friendships = repo.list_friendships(user_id)

    results = []
    for f in friendships:
        # Compute connection drift and nudge eligibility from interactions
        interactions = repo.list_interactions(f["user_id"])

        # Import inline to avoid circular — these are pure functions
        from app.services.connection import connection_drift, eligible_for_nudge

        drift = connection_drift_from_dicts(interactions)
        nudge = nudge_eligible_from_dicts(interactions)

        # Compute mutual signals
        signals_a = repo.list_ambient_signals(f["user_id"])
        signals_b = repo.list_ambient_signals(f["friend_id"])
        mutual = mutual_from_dicts(signals_a, signals_b)

        results.append(
            FriendshipResponse(
                id=f["id"],
                user_id=f["user_id"],
                friend_id=f["friend_id"],
                status=f["status"],
                created_at=f["created_at"],
                updated_at=f["updated_at"],
                connection_drift=drift,
                nudge_eligible=nudge,
                mutual_signals_confirmed=mutual,
            )
        )
    return results


@router.patch("/{friendship_id}", response_model=dict)
def update_friendship(
    friendship_id: str,
    body: FriendshipStatusUpdate,
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """Update a friendship's status (accept, pause, archive)."""
    friendship = repo.get_friendship(friendship_id)
    if not friendship:
        raise HTTPException(status_code=404, detail="Friendship not found")

    # Only participants can update
    if user_id not in (friendship["user_id"], friendship["friend_id"]):
        raise HTTPException(status_code=403, detail="Not a participant")

    updated = repo.update_friendship_status(friendship_id, body.status.value)
    return updated


# --------------------------------------------------------------------------
# Helpers — adapt dict-based DB rows to the pure-function service layer
# --------------------------------------------------------------------------

def connection_drift_from_dicts(interactions: list[dict]) -> float:
    """Adapter: convert DB rows to the drift computation."""
    from datetime import datetime

    if len(interactions) < 2:
        return 0.0

    sorted_ints = sorted(interactions, key=lambda i: i["created_at"])
    deltas = []
    for i in range(1, len(sorted_ints)):
        t1 = sorted_ints[i - 1]["created_at"]
        t2 = sorted_ints[i]["created_at"]
        if isinstance(t1, str):
            t1 = datetime.fromisoformat(t1)
            t2 = datetime.fromisoformat(t2)
        deltas.append((t2 - t1).total_seconds())

    if not deltas:
        return 0.0
    recent = deltas[-3:]
    window = len(recent)
    return max(0.0, min(1.0, sum(recent) / (window * 60 * 60 * 24)))


def nudge_eligible_from_dicts(interactions: list[dict]) -> bool:
    drift = connection_drift_from_dicts(interactions)
    return drift > 0.5


def mutual_from_dicts(signals_a: list[dict], signals_b: list[dict]) -> bool:
    tags_a = {tag for s in signals_a for tag in (s.get("tags") or [])}
    tags_b = {tag for s in signals_b for tag in (s.get("tags") or [])}
    shared = tags_a & tags_b
    if not shared or not signals_a or not signals_b:
        return False
    strength = sum(
        min(
            sum(tag in (s.get("tags") or []) for s in signals_a),
            sum(tag in (s.get("tags") or []) for s in signals_b),
        )
        for tag in shared
    )
    return (strength / len(shared)) >= 1.0

