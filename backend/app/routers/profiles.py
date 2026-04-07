"""
Profiles Router

Search and discovery endpoints for user profiles.
All operations require authentication via JWT.

Privacy: Contact info (phone_number, email) is only returned when
the requester is the profile owner or a confirmed friend.
Search results never include contact info.
"""

from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query

from app.db.repository import Repository
from app.dependencies import get_current_user_id, get_repository
from app.schemas.models import ProfilePublicResponse, ProfileResponse

router = APIRouter(prefix="/profiles", tags=["profiles"])


@router.get("/search", response_model=List[ProfilePublicResponse])
def search_profiles(
    q: str = Query(..., min_length=1, max_length=100, description="Search term"),
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """
    Search for profiles by display name.
    Excludes the requesting user from results.
    Returns at most 20 results. No contact info exposed.
    """
    results = repo.search_profiles(query=q, exclude_id=user_id, limit=20)
    return results


@router.get("/{profile_id}", response_model=ProfileResponse)
def get_profile_by_id(
    profile_id: str,
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """
    Fetch a single profile by user ID.

    Contact info (phone_number, email) is only returned if:
      - The requester IS the profile owner, or
      - The requester is a confirmed friend.
    Otherwise those fields are stripped from the response.
    """
    profile = repo.get_profile(profile_id)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")

    # Self-view: return everything
    if profile_id == user_id:
        return profile

    # Check if requester is a confirmed friend
    friendships = repo.list_friendships(user_id)
    is_confirmed_friend = any(
        f["status"] == "confirmed"
        and (
            (f["user_id"] == user_id and f["friend_id"] == profile_id)
            or (f["friend_id"] == user_id and f["user_id"] == profile_id)
        )
        for f in friendships
    )

    if not is_confirmed_friend:
        # Redact contact info — return safe fields only
        profile = {**profile, "phone_number": None, "email": None}

    return profile
