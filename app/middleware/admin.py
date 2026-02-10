"""
Friendly Backend — Admin Authorization

Ensures the current user is an admin by checking the admin_users table.
"""

from fastapi import Depends, HTTPException, status

from app.db.repository import Repository
from app.dependencies import get_repository
from app.middleware.auth import get_current_user_id


def require_admin_user(
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
) -> dict:
    admin = repo.get_admin_user(user_id)
    if not admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )
    return {"user_id": user_id, "role": admin.get("role", "admin")}
