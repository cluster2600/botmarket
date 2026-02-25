from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field


class UserResponse(BaseModel):
    id: int
    wallet_address: Optional[str] = None
    email: Optional[EmailStr] = None
    username: Optional[str] = None
    role: str = "user"
    is_active: bool = True
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class UserBrief(BaseModel):
    """Minimal user info for embedding in other responses."""
    id: int
    wallet_address: Optional[str] = None
    role: str = "user"

    model_config = {"from_attributes": True}


class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    username: Optional[str] = Field(None, min_length=1, max_length=100)
