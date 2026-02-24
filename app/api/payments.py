from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional

router = APIRouter()

class PaymentRequest(BaseModel):
    order_id: int
    currency: str = "USDT"  # USDT, USDC, DAI
    network: str = "ethereum"  # ethereum, polygon, arbitrum

class PaymentResponse(BaseModel):
    order_id: int
    payment_address: str  # Contract or wallet to pay to
    amount: float
    currency: str
    network: str
    tx_hash: Optional[str] = None
    status: str

@router.post("/create", response_model=PaymentResponse)
def create_payment(request: PaymentRequest):
    """Create payment request"""
    # Mock - would integrate with payment contract or API
    payment_address = "0x742d35Cc6634C0532925a3b844Bc9e7595f0fEb1"
    
    return PaymentResponse(
        order_id=request.order_id,
        payment_address=payment_address,
        amount=99.0,  # Would get from order
        currency=request.currency,
        network=request.network,
        status="pending"
    )

@router.get("/currencies")
def get_currencies():
    """Get supported currencies"""
    return {
        "currencies": [
            {"symbol": "USDT", "name": "Tether", "networks": ["ethereum", "polygon", "arbitrum"]},
            {"symbol": "USDC", "name": "USD Coin", "networks": ["ethereum", "polygon", "arbitrum"]},
            {"symbol": "DAI", "name": "Dai", "networks": ["ethereum"]},
        ]
    }

@router.get("/rates")
def get_rates():
    """Get crypto exchange rates (mock)"""
    return {
        "USDT": {"USD": 1.0},
        "USDC": {"USD": 1.0},
        "DAI": {"USD": 1.0},
        "ETH": {"USD": 3200.0},
    }
