from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class ProductTypeEnum(str, Enum):
    HARDWARE = "hardware"
    SERVICE = "service"
    SUBSCRIPTION = "subscription"


class ProductBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    product_type: ProductTypeEnum
    price: float = Field(..., gt=0, description="Price in USD")
    price_crypto: Optional[str] = None
    image_url: Optional[str] = Field(None, max_length=500)
    specs: Optional[str] = None


class ProductCreate(ProductBase):
    pass


class ProductUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = None
    product_type: Optional[ProductTypeEnum] = None
    price: Optional[float] = Field(None, gt=0)
    price_crypto: Optional[str] = None
    image_url: Optional[str] = Field(None, max_length=500)
    specs: Optional[str] = None


class ProductResponse(ProductBase):
    id: int
    seller_id: Optional[int] = None
    is_active: bool = True
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": True}
