"""
Friend Reminders Router

Recurring reminders that a user sets for a specific friend.
Stored server-side so they sync across devices.
Local notifications are scheduled by the mobile client.

GET    /friend-reminders/             → list all reminders for the current user
GET    /friend-reminders/{friend_id}  → get reminder for a specific friend
PUT    /friend-reminders/{friend_id}  → create or update a reminder
PATCH  /friend-reminders/{friend_id}  → partially update a reminder
DELETE /friend-reminders/{friend_id}  → delete a reminder
"""

from fastapi import APIRouter, Depends

from app.db.repository import Repository
from app.dependencies import get_current_user_id, get_repository
from app.schemas.models import (
    FriendReminderCreate,
    FriendReminderResponse,
    FriendReminderUpdate,
)

router = APIRouter(prefix="/friend-reminders", tags=["friend-reminders"])


@router.get("/", response_model=list[FriendReminderResponse])
def list_friend_reminders(
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """List all reminders for the current user."""
    return repo.list_friend_reminders(user_id)


@router.get("/{friend_id}", response_model=FriendReminderResponse | None)
def get_friend_reminder(
    friend_id: str,
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """Get the reminder for a specific friend."""
    return repo.get_friend_reminder(user_id, friend_id)


@router.put("/{friend_id}", response_model=FriendReminderResponse)
def upsert_friend_reminder(
    friend_id: str,
    body: FriendReminderCreate,
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """Create or update a reminder for a friend."""
    return repo.upsert_friend_reminder(
        user_id, friend_id, body.text, body.interval_days
    )


@router.patch("/{friend_id}", response_model=FriendReminderResponse | None)
def update_friend_reminder(
    friend_id: str,
    body: FriendReminderUpdate,
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """Partially update a reminder (text, interval_days, or both)."""
    updates = body.model_dump(exclude_none=True)
    if not updates:
        return repo.get_friend_reminder(user_id, friend_id)
    return repo.update_friend_reminder(user_id, friend_id, updates)


@router.delete("/{friend_id}")
def delete_friend_reminder(
    friend_id: str,
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """Delete a reminder for a friend."""
    repo.delete_friend_reminder(user_id, friend_id)
    return {"deleted": True}
