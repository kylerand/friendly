"""
Interactions Router

Logs interactions between users and computes derived signals
(connection drift, nudge eligibility).

All operations are scoped to the authenticated user via JWT.
"""

from typing import List

from fastapi import APIRouter, Depends

from app.db.repository import Repository
from app.dependencies import get_current_user_id, get_repository
from app.schemas.models import InteractionCreate, InteractionResponse

router = APIRouter(prefix="/interactions", tags=["interactions"])


@router.post("/")
def log_interaction(
    body: InteractionCreate,
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """Log an interaction and return derived connection signals."""
    interaction = repo.create_interaction(
        user_id=user_id,
        target_id=str(body.target_id),
        interaction_type=body.type,
        metadata=body.metadata,
    )

    # Compute drift from all user interactions
    from app.routers.friendships import connection_drift_from_dicts, nudge_eligible_from_dicts

    all_interactions = repo.list_interactions(user_id)
    drift = connection_drift_from_dicts(all_interactions)
    nudge = nudge_eligible_from_dicts(all_interactions)
    friendships = repo.list_friendships(user_id)

    return {
        "interaction": interaction,
        "nudge_eligible": nudge,
        "connection_drift": drift,
        "active_friendships": len(friendships),
    }


@router.get("/", response_model=List[InteractionResponse])
def list_interactions(
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """List the authenticated user's interactions (most recent first)."""
    return repo.list_interactions(user_id)

