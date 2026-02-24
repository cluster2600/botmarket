# BotMarket - GPU & Services Marketplace

## Overview
Web3 marketplace for buying/selling bots, GPU instances, and services with crypto payments.

## Features
- **Hardware**: AWS GPU instances (p4d, p5, g5), credits
- **Services**: AI bots, trading bots, automation
- **Subscriptions**: Monthly/yearly plans
- **Payments**: Stablecoins (USDT, USDC)

## Tech Stack
- Backend: FastAPI + SQLAlchemy + PostgreSQL
- Auth: Web3 (wallet signature) + JWT
- Payments: Smart contracts or crypto API
- AWS: boto3 integration

## API Endpoints
- `/api/auth/*` - Authentication
- `/api/users/*` - User management
- `/api/products/*` - Products catalog
- `/api/orders/*` - Order management
- `/api/payments/*` - Crypto payments

## Models
- User (wallet_address, email, role)
- Product (name, type, price, specs)
- Order (user_id, product_id, status, payment)
- Subscription (user_id, product_id, period)

## Web3 Flow
1. User connects wallet
2. Sign message to authenticate
3. JWT token issued
4. Pay with stablecoins
