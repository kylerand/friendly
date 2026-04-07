"""
Check-ins Router

Gentle self-assessment records. Strictly private — only the owning
user can create or view their check-ins.
"""

from typing import List

from fastapi import APIRouter, Depends

from app.db.repository import Repository
from app.dependencies import get_current_user_id, get_repository
from app.schemas.models import CheckInCreate, CheckInResponse

router = APIRouter(prefix="/check-ins", tags=["check-ins"])


@router.post("/", response_model=CheckInResponse)
def create_check_in(
    body: CheckInCreate,
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """Create a new self check-in."""
    check_in = repo.create_check_in(
        user_id=user_id,
        comfort=body.comfort,
        connection=body.connection,
        energy=body.energy,
        notes=body.notes or "",
    )
    return check_in


@router.get("/", response_model=List[CheckInResponse])
def list_check_ins(
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """List the authenticated user's check-ins (most recent first)."""
    return repo.list_check_ins(user_id)
