from pydantic import BaseModel, EmailStr, Field

from app.schemas.user import UserBrief


class WalletAuth(BaseModel):
    address: str = Field(..., min_length=42, max_length=42, description="Ethereum wallet address")
    signature: str = Field(..., description="Signed message from wallet")
    message: str = Field(..., description="Original message that was signed")


class RegisterRequest(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=1, max_length=100)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserBrief
