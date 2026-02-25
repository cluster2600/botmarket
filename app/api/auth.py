from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from web3 import Web3

from app.core.database import get_db
from app.core.config import settings
from app.schemas.auth import WalletAuth, TokenResponse, RegisterRequest
from app.schemas.common import MessageResponse
from app.schemas.user import UserBrief, UserResponse

router = APIRouter()
security = HTTPBearer()


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
    if not verify_wallet_signature(auth.address, auth.signature, auth.message):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid signature"
        )

    from app.models.models import User
    user = db.query(User).filter(User.wallet_address == auth.address).first()

    if not user:
        user = User(
            wallet_address=auth.address,
            username=f"User_{auth.address[:8]}"
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    from app.core.security import create_access_token
    token = create_access_token(data={"sub": user.wallet_address})

    return TokenResponse(
        access_token=token,
        user=UserBrief(id=user.id, wallet_address=user.wallet_address, role=user.role)
    )


@router.post("/register", response_model=MessageResponse)
def register(data: RegisterRequest, db: Session = Depends(get_db)):
    """Register with email (fallback)"""
    from app.models.models import User

    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")

    user = User(email=data.email, username=data.username)
    db.add(user)
    db.commit()

    return MessageResponse(message="User created")


@router.get("/me", response_model=UserResponse)
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

    return user
