"""
Friendly Backend — Portal Access

Allows admin users and pilot/tester users to access the feedback portal.
"""

from fastapi import Depends, HTTPException, status

from app.db.repository import Repository
from app.dependencies import get_repository
from app.middleware.auth import get_current_user_id


def require_portal_user(
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
) -> dict:
    admin = repo.get_admin_user(user_id)
    if admin:
        return {"user_id": user_id, "role": admin.get("role", "admin"), "is_admin": True}

    role = repo.get_user_role(user_id)
    if role and role.get("role") in {"pilot", "tester"}:
        return {"user_id": user_id, "role": role["role"], "is_admin": False}

    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Portal access required",
    )
