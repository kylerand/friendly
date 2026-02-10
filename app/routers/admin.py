"""
Admin Router

Provides admin-only endpoints for the web portal.
"""

from fastapi import APIRouter, Depends, HTTPException

from app.db.repository import Repository
from app.dependencies import get_repository
from app.middleware.admin import require_admin_user
from app.schemas.models import (
    AdminFriendshipResponse,
    AdminMeResponse,
    AdminMetricsResponse,
    AdminProfileResponse,
    AdminUserCreate,
    AdminUserResponse,
)

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/me", response_model=AdminMeResponse)
def get_admin_me(admin=Depends(require_admin_user)):
    return admin


@router.get("/metrics", response_model=AdminMetricsResponse)
def get_admin_metrics(
    admin=Depends(require_admin_user),
    repo: Repository = Depends(get_repository),
):
    return {
        "users": repo.count_table("profiles"),
        "friendships": repo.count_table("friendships"),
        "check_ins": repo.count_table("check_ins"),
        "interactions": repo.count_table("interactions"),
        "ambient_signals": repo.count_table("ambient_signals"),
        "device_state": repo.count_table("device_state"),
    }


@router.get("/users", response_model=list[AdminProfileResponse])
def list_users(
    q: str | None = None,
    limit: int = 50,
    admin=Depends(require_admin_user),
    repo: Repository = Depends(get_repository),
):
    if limit > 200:
        raise HTTPException(status_code=400, detail="Limit too large")
    return repo.list_profiles_admin(query=q, limit=limit)


@router.get("/friendships", response_model=list[AdminFriendshipResponse])
def list_friendships(
    user_id: str | None = None,
    limit: int = 100,
    admin=Depends(require_admin_user),
    repo: Repository = Depends(get_repository),
):
    if limit > 500:
        raise HTTPException(status_code=400, detail="Limit too large")
    return repo.list_friendships_admin(user_id=user_id, limit=limit)


@router.get("/admins", response_model=list[AdminUserResponse])
def list_admins(
    admin=Depends(require_admin_user),
    repo: Repository = Depends(get_repository),
):
    rows = repo.list_admin_users()
    response: list[AdminUserResponse] = []
    for row in rows:
        profile = row.get("profiles")
        response.append(
            AdminUserResponse(
                user_id=row["user_id"],
                role=row["role"],
                created_at=row["created_at"],
                profile=AdminProfileResponse(
                    id=profile["id"],
                    display_name=profile["display_name"],
                    avatar_url=profile.get("avatar_url"),
                    phone_number=profile.get("phone_number"),
                    email=profile.get("email"),
                    created_at=profile["created_at"],
                ) if profile else None,
            )
        )
    return response


@router.post("/admins", response_model=AdminUserResponse)
def add_admin(
    body: AdminUserCreate,
    admin=Depends(require_admin_user),
    repo: Repository = Depends(get_repository),
):
    if body.role not in {"admin", "super_admin"}:
        raise HTTPException(status_code=400, detail="Invalid admin role")
    row = repo.upsert_admin_user(user_id=str(body.user_id), role=body.role)
    admin_row = repo.get_admin_user(str(body.user_id)) or row
    profile = repo.get_profile(str(body.user_id))
    return AdminUserResponse(
        user_id=admin_row["user_id"],
        role=admin_row["role"],
        created_at=admin_row["created_at"],
        profile=AdminProfileResponse(
            id=profile["id"],
            display_name=profile["display_name"],
            avatar_url=profile.get("avatar_url"),
            phone_number=profile.get("phone_number"),
            email=profile.get("email"),
            created_at=profile["created_at"],
        ) if profile else None,
    )


@router.delete("/admins/{user_id}")
def remove_admin(
    user_id: str,
    admin=Depends(require_admin_user),
    repo: Repository = Depends(get_repository),
):
    repo.delete_admin_user(user_id)
    return {"ok": True}
