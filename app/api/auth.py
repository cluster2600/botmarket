from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from web3 import Web3

from app.core.database import get_db
from app.core.config import settings

router = APIRouter()
security = HTTPBearer()

# Web3 Auth
class WalletAuth(BaseModel):
    address: str
    signature: str
    message: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: dict

def verify_wallet_signature(address: str, signature: str, message: str) -> bool:
    """Verify Ethereum wallet signature"""
    try:
        w3 = Web3()
        recovered = w3.eth.account.recover_message(
            Web3.keccak(text=message),
            signature=signature
        )
        return recovered.lower() == address.lower()
    except Exception:
        return False

@router.post("/web3", response_model=TokenResponse)
def auth_web3(auth: WalletAuth, db: Session = Depends(get_db)):
    """Authenticate with wallet signature"""
    # Verify signature
    if not verify_wallet_signature(auth.address, auth.signature, auth.message):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid signature"
        )
    
    # Check if user exists
    from app.models.models import User
    user = db.query(User).filter(User.wallet_address == auth.address).first()
    
    if not user:
        # Create new user
        user = User(
            wallet_address=auth.address,
            username=f"User_{auth.address[:8]}"
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    
    # Generate JWT
    from app.core.security import create_access_token
    token = create_access_token(data={"sub": user.wallet_address})
    
    return TokenResponse(
        access_token=token,
        user={"id": user.id, "address": user.wallet_address, "role": user.role}
    )

@router.post("/register")
def register(
    email: EmailStr,
    username: str,
    db: Session = Depends(get_db)
):
    """Register with email (fallback)"""
    from app.models.models import User
    
    # Check if exists
    if db.query(User).filter(User.email == email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    
    user = User(email=email, username=username)
    db.add(user)
    db.commit()
    
    return {"message": "User created", "id": user.id}

@router.get("/me")
def get_me(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Get current user"""
    from app.core.security import verify_token
    from app.models.models import User
    
    token = credentials.credentials
    payload = verify_token(token)
    if not payload:
        raise HTTPException(status_code=401, detail="Invalid token")
    
    db = next(get_db())
    user = db.query(User).filter(User.wallet_address == payload.get("sub")).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {"id": user.id, "address": user.wallet_address, "email": user.email}
