from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from pydantic import BaseModel

from app.core.database import get_db
from app.models.models import Order, OrderStatus
from app.core.security import verify_token

router = APIRouter()

class OrderCreate(BaseModel):
    product_id: int
    crypto_currency: str = "USDT"  # USDT, USDC, DAI

class OrderResponse(BaseModel):
    id: int
    product_id: int
    status: str
    amount_usd: float
    amount_crypto: float
    crypto_currency: str
    transaction_hash: str = None
    
    class Config:
        from_attributes = True

@router.get("/", response_model=List[OrderResponse])
def list_orders(db: Session = Depends(get_db)):
    """List all orders"""
    return db.query(Order).all()

@router.get("/{order_id}", response_model=OrderResponse)
def get_order(order_id: int, db: Session = Depends(get_db)):
    """Get order by ID"""
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return order

@router.post("/", response_model=OrderResponse)
def create_order(order: OrderCreate, db: Session = Depends(get_db)):
    """Create new order"""
    # Get product price
    from app.models.models import Product
    product = db.query(Product).filter(Product.id == order.product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    # Calculate crypto price (mock - would use price oracle)
    crypto_rates = {"USDT": 1.0, "USDC": 1.0, "DAI": 1.0}
    amount_crypto = product.price / crypto_rates.get(order.crypto_currency, 1.0)
    
    db_order = Order(
        product_id=order.product_id,
        amount_usd=product.price,
        amount_crypto=amount_crypto,
        crypto_currency=order.crypto_currency,
        status=OrderStatus.PENDING
    )
    db.add(db_order)
    db.commit()
    db.refresh(db_order)
    return db_order

@router.post("/{order_id}/pay")
def confirm_payment(order_id: int, transaction_hash: str, db: Session = Depends(get_db)):
    """Confirm payment with transaction hash"""
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    if order.status != OrderStatus.PENDING:
        raise HTTPException(status_code=400, detail="Order already processed")
    
    # Verify transaction (mock - would verify on-chain)
    order.transaction_hash = transaction_hash
    order.status = OrderStatus.PAID
    db.commit()
    
    return {"message": "Payment confirmed", "order_id": order_id}

@router.post("/{order_id}/cancel")
def cancel_order(order_id: int, db: Session = Depends(get_db)):
    """Cancel order"""
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    if order.status != OrderStatus.PENDING:
        raise HTTPException(status_code=400, detail="Cannot cancel this order")
    
    order.status = OrderStatus.CANCELLED
    db.commit()
    return {"message": "Order cancelled"}
