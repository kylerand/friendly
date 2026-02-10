"""
Friend Notes Router

Private CRM-style notes that a user writes about a friend.
These are personal — only visible to the note author, never
to the friend being described.

GET  /friend-notes/{friend_id}  → get the note for a friend
PUT  /friend-notes/{friend_id}  → create or update the note
DELETE /friend-notes/{friend_id} → delete the note
"""

from fastapi import APIRouter, Depends, HTTPException

from app.db.repository import Repository
from app.dependencies import get_current_user_id, get_repository
from app.schemas.models import FriendNoteResponse, FriendNoteUpsert

router = APIRouter(prefix="/friend-notes", tags=["friend-notes"])


@router.get("/{friend_id}", response_model=FriendNoteResponse | None)
def get_friend_note(
    friend_id: str,
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """Get the current user's private note about a friend."""
    note = repo.get_friend_note(user_id, friend_id)
    return note


@router.put("/{friend_id}", response_model=FriendNoteResponse)
def upsert_friend_note(
    friend_id: str,
    body: FriendNoteUpsert,
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """Create or update a private note about a friend."""
    result = repo.upsert_friend_note(user_id, friend_id, body.content)
    return result


@router.delete("/{friend_id}")
def delete_friend_note(
    friend_id: str,
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    """Delete a private note about a friend."""
    repo.delete_friend_note(user_id, friend_id)
    return {"deleted": True}
