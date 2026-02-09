"""
Auth Router

Supabase Auth is the source of truth. The backend does NOT handle signup,
login, or password management — the mobile app talks to Supabase directly.

This router provides:
- GET /auth/me — returns the authenticated user's profile
- PATCH /auth/me — updates the authenticated user's profile

The JWT is verified by the `get_current_user_id` dependency.
"""

from fastapi import APIRouter, Depends, HTTPException

from app.db.repository import Repository
from app.dependencies import get_current_user_id, get_repository
from app.schemas.models import ProfileResponse, ProfileUpdate

router = APIRouter(prefix="/auth", tags=["auth"])


@router.get("/me", response_model=ProfileResponse)
def get_me(
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """Return the authenticated user's profile."""
    profile = repo.get_profile(user_id)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    return profile


@router.patch("/me", response_model=ProfileResponse)
def update_me(
    body: ProfileUpdate,
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """Update the authenticated user's profile fields."""
    update_data = body.model_dump(exclude_none=True)
    if not update_data:
        raise HTTPException(status_code=400, detail="No fields to update")

    profile = repo.get_profile(user_id)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")

    updated = repo.upsert_profile(
        user_id=user_id,
        display_name=update_data.get("display_name", profile["display_name"]),
        **{k: v for k, v in update_data.items() if k != "display_name"},
    )
    return updated

