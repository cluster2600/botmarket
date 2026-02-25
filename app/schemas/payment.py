from typing import Optional

from pydantic import BaseModel, Field


class PaymentRequest(BaseModel):
    order_id: int
    currency: str = Field("USDT", description="Payment currency: USDT, USDC, or DAI")
    network: str = Field("ethereum", description="Blockchain network: ethereum, polygon, arbitrum")


class PaymentResponse(BaseModel):
    order_id: int
    payment_address: str
    amount: float
    currency: str
    network: str
    tx_hash: Optional[str] = None
    status: str


class CurrencyInfo(BaseModel):
    symbol: str
    name: str
    networks: list[str]


class CurrencyListResponse(BaseModel):
    currencies: list[CurrencyInfo]


class ExchangeRates(BaseModel):
    USDT: dict[str, float]
    USDC: dict[str, float]
    DAI: dict[str, float]
    ETH: dict[str, float]
