"""
Friendly Backend — Pydantic Schemas

Request/response models for the API. These are NOT database models —
they define the contract between the mobile app and the backend.

Design decision: UUIDs everywhere to match Supabase auth.users(id).
All timestamps use datetime with timezone awareness.
"""

from datetime import datetime
from enum import Enum
from typing import Dict, List, Optional
from uuid import UUID

from pydantic import BaseModel, Field


# --------------------------------------------------------------------------
# Auth
# --------------------------------------------------------------------------

class ProfileResponse(BaseModel):
    id: UUID
    display_name: str
    avatar_url: Optional[str] = None
    phone_number: Optional[str] = None
    email: Optional[str] = None
    metadata: Dict[str, str] = Field(default_factory=dict)
    created_at: datetime


class ProfilePublicResponse(BaseModel):
    """Returned by search — no contact info exposed."""
    id: UUID
    display_name: str
    avatar_url: Optional[str] = None
    created_at: datetime


class ProfileUpdate(BaseModel):
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    phone_number: Optional[str] = None
    email: Optional[str] = None
    metadata: Optional[Dict[str, str]] = None


# --------------------------------------------------------------------------
# Friendships
# --------------------------------------------------------------------------

class FriendshipStatus(str, Enum):
    pending = "pending"
    confirmed = "confirmed"
    paused = "paused"
    archived = "archived"


class FriendshipCreate(BaseModel):
    friend_id: UUID


class FriendshipStatusUpdate(BaseModel):
    status: FriendshipStatus


class FriendshipResponse(BaseModel):
    id: UUID
    user_id: UUID
    friend_id: UUID
    status: FriendshipStatus
    created_at: datetime
    updated_at: datetime
    connection_drift: float = 0.0
    nudge_eligible: bool = False
    mutual_signals_confirmed: bool = False


# --------------------------------------------------------------------------
# Check-ins
# --------------------------------------------------------------------------

class CheckInCreate(BaseModel):
    comfort: int = Field(ge=1, le=5, default=3)
    connection: int = Field(ge=1, le=5, default=3)
    energy: int = Field(ge=1, le=5, default=3)
    notes: Optional[str] = None


class CheckInResponse(BaseModel):
    id: UUID
    user_id: UUID
    comfort: int
    connection: int
    energy: int
    notes: Optional[str] = None
    created_at: datetime


# --------------------------------------------------------------------------
# Interactions
# --------------------------------------------------------------------------

class InteractionCreate(BaseModel):
    target_id: UUID
    type: str = "message"
    metadata: Dict[str, str] = Field(default_factory=dict)


class InteractionResponse(BaseModel):
    id: UUID
    user_id: UUID
    target_id: UUID
    type: str
    metadata: Dict[str, str] = Field(default_factory=dict)
    created_at: datetime


# --------------------------------------------------------------------------
# Ambient signals
# --------------------------------------------------------------------------

class AmbientSignalCreate(BaseModel):
    signal_type: str
    value: float = 0.0
    tags: List[str] = Field(default_factory=list)


class AmbientSignalResponse(BaseModel):
    id: UUID
    user_id: UUID
    signal_type: str
    value: float
    tags: List[str] = Field(default_factory=list)
    created_at: datetime


# --------------------------------------------------------------------------
# Health
# --------------------------------------------------------------------------

class HealthResponse(BaseModel):
    status: str
    environment: str
    database: str

