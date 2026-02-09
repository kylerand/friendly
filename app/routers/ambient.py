"""
Ambient Signals Router

Records opt-in ambient signals and provides summaries.
All operations are scoped to the authenticated user via JWT.
"""

from typing import List

from fastapi import APIRouter, Depends

from app.db.repository import Repository
from app.dependencies import get_current_user_id, get_repository
from app.schemas.models import AmbientSignalCreate, AmbientSignalResponse

router = APIRouter(prefix="/ambient", tags=["ambient"])


@router.post("/signals")
def create_signal(
    body: AmbientSignalCreate,
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """Record an ambient signal and return a summary."""
    signal = repo.create_ambient_signal(
        user_id=user_id,
        signal_type=body.signal_type,
        value=body.value,
        tags=body.tags,
    )

    # Compute summary from all user signals
    all_signals = repo.list_ambient_signals(user_id)
    values = [s["value"] for s in all_signals]
    tags = {tag for s in all_signals for tag in (s.get("tags") or [])}

    return {
        "signal": signal,
        "summary": {
            "average": sum(values) / len(values) if values else 0.0,
            "tags": list(tags),
            "count": len(all_signals),
        },
    }


@router.get("/signals", response_model=List[AmbientSignalResponse])
def list_signals(
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """List the authenticated user's ambient signals."""
    return repo.list_ambient_signals(user_id)

