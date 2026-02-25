from fastapi import APIRouter

from app.schemas.payment import (
    CurrencyInfo,
    CurrencyListResponse,
    ExchangeRates,
    PaymentRequest,
    PaymentResponse,
)

router = APIRouter()


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


@router.get("/currencies", response_model=CurrencyListResponse)
def get_currencies():
    """Get supported currencies"""
    return CurrencyListResponse(
        currencies=[
            CurrencyInfo(symbol="USDT", name="Tether", networks=["ethereum", "polygon", "arbitrum"]),
            CurrencyInfo(symbol="USDC", name="USD Coin", networks=["ethereum", "polygon", "arbitrum"]),
            CurrencyInfo(symbol="DAI", name="Dai", networks=["ethereum"]),
        ]
    )


@router.get("/rates", response_model=ExchangeRates)
def get_rates():
    """Get crypto exchange rates (mock)"""
    return ExchangeRates(
        USDT={"USD": 1.0},
        USDC={"USD": 1.0},
        DAI={"USD": 1.0},
        ETH={"USD": 3200.0},
    )
