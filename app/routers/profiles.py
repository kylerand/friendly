"""
Profiles Router

Search and discovery endpoints for user profiles.
All operations require authentication via JWT.
"""

from typing import List

from fastapi import APIRouter, Depends, Query

from app.db.repository import Repository
from app.dependencies import get_current_user_id, get_repository
from app.schemas.models import ProfileResponse

router = APIRouter(prefix="/profiles", tags=["profiles"])


@router.get("/search", response_model=List[ProfileResponse])
def search_profiles(
    q: str = Query(..., min_length=1, max_length=100, description="Search term"),
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """
    Search for profiles by display name.
    Excludes the requesting user from results.
    Returns at most 20 results.
    """
    results = repo.search_profiles(query=q, exclude_id=user_id, limit=20)
    return results
