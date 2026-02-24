from sqlalchemy import Column, Integer, String, Float, DateTime, Enum, ForeignKey, Text, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum

from app.core.database import Base

class ProductType(str, enum.Enum):
    HARDWARE = "hardware"      # AWS instances, GPU
    SERVICE = "service"        # AI bots, trading bots
    SUBSCRIPTION = "subscription"  # Monthly plans

class OrderStatus(str, enum.Enum):
    PENDING = "pending"
    PAID = "paid"
    PROCESSING = "processing"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    REFUNDED = "refunded"

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    wallet_address = Column(String(42), unique=True, index=True)
    email = Column(String(255), unique=True, index=True)
    username = Column(String(100))
    role = Column(String(20), default="user")  # user, seller, admin
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    orders = relationship("Order", back_populates="user")
    subscriptions = relationship("Subscription", back_populates="user")

class Product(Base):
    __tablename__ = "products"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    description = Column(Text)
    product_type = Column(String(20), nullable=False)  # hardware, service, subscription
    price = Column(Float, nullable=False)  # in USD
    price_crypto = Column(String(50))  # USDT address or amount
    image_url = Column(String(500))
    specs = Column(Text)  # JSON: {gpu: "A100", vram: "40GB", etc.}
    seller_id = Column(Integer, ForeignKey("users.id"))
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    seller = relationship("User")
    orders = relationship("Order", back_populates="product")

class Order(Base):
    __tablename__ = "orders"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    status = Column(String(20), default="pending")
    amount_usd = Column(Float, nullable=False)
    amount_crypto = Column(Float)
    crypto_currency = Column(String(10))  # USDT, USDC, DAI
    transaction_hash = Column(String(100))
    payment_proof = Column(String(500))  # screenshot or tx
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    user = relationship("User", back_populates="orders")
    product = relationship("Product", back_populates="orders")

class Subscription(Base):
    __tablename__ = "subscriptions"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    period_months = Column(Integer, default=1)
    starts_at = Column(DateTime(timezone=True), server_default=func.now())
    expires_at = Column(DateTime(timezone=True))
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    user = relationship("User", back_populates="subscriptions")
    product = relationship("Product")
