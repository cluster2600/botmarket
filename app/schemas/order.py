from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class CryptoCurrency(str, Enum):
    USDT = "USDT"
    USDC = "USDC"
    DAI = "DAI"


class OrderStatusEnum(str, Enum):
    PENDING = "pending"
    PAID = "paid"
    PROCESSING = "processing"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    REFUNDED = "refunded"


class OrderCreate(BaseModel):
    product_id: int
    crypto_currency: CryptoCurrency = CryptoCurrency.USDT


class PaymentConfirm(BaseModel):
    transaction_hash: str = Field(..., min_length=1, max_length=100)


class OrderResponse(BaseModel):
    id: int
    user_id: Optional[int] = None
    product_id: int
    status: OrderStatusEnum
    amount_usd: float
    amount_crypto: Optional[float] = None
    crypto_currency: Optional[str] = None
    transaction_hash: Optional[str] = None
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": True}
