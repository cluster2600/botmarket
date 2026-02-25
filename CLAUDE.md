# CLAUDE.md — BotMarket

## Project Overview

BotMarket is a Web3-enabled GPU & Services Marketplace with crypto payments. It combines a FastAPI backend with Solidity smart contracts, allowing users to buy/sell bots, GPU instances, and services using stablecoins (USDT, USDC, DAI).

## Repository Structure

```
botmarket/
├── app/                        # FastAPI backend (Python)
│   ├── main.py                 # Application entry point, route registration, CORS
│   ├── api/                    # API route handlers
│   │   ├── auth.py             # Web3 wallet authentication endpoints
│   │   ├── users.py            # User profile CRUD
│   │   ├── products.py         # Product catalog (list, create, update, delete)
│   │   ├── orders.py           # Order management and payment confirmation
│   │   └── payments.py         # Payment creation, supported currencies, rates
│   ├── core/                   # Core configuration and utilities
│   │   ├── config.py           # Pydantic Settings (env vars, defaults)
│   │   ├── database.py         # SQLAlchemy engine, session, Base
│   │   └── security.py         # JWT token creation and verification
│   ├── models/
│   │   └── models.py           # SQLAlchemy ORM models (User, Product, Order, Subscription)
│   ├── schemas/                # Pydantic request/response schemas (placeholder)
│   └── services/               # Business logic layer (placeholder)
├── contracts/                  # Solidity smart contracts (Hardhat project)
│   ├── BotMarketPlace.sol      # Full marketplace: products, orders, auctions, subscriptions
│   ├── BotMarketPayment.sol    # Payment processing: orders, refunds, withdrawals
│   ├── hardhat.config.js       # Hardhat config (Solidity 0.8.20, optimizer, networks)
│   ├── package.json            # Node dependencies and npm scripts
│   ├── scripts/
│   │   └── deploy.js           # Contract deployment script
│   └── test/
│       └── BotMarketPayment.test.js  # Payment contract test suite
├── requirements.txt            # Python dependencies
├── SPEC.md                     # Full project specification and feature list
└── README.md                   # Basic setup instructions
```

## Tech Stack

### Backend (Python)
- **Framework:** FastAPI 0.115.0
- **Server:** Uvicorn 0.34.0
- **Database:** PostgreSQL via SQLAlchemy 2.0.36 (synchronous engine with `psycopg2-binary`)
- **Migrations:** Alembic 1.14.0
- **Validation:** Pydantic 2.10.3, pydantic-settings 2.7.1
- **Auth:** JWT via python-jose 3.3.0, password hashing via passlib 1.7.4 (bcrypt)
- **Web3:** web3 6.20.0, eth-account 0.13.1 (Ethereum signature verification)
- **AWS:** boto3 1.36.0
- **HTTP Client:** httpx 0.28.1

### Smart Contracts (Solidity)
- **Language:** Solidity ^0.8.20
- **Framework:** Hardhat 2.20.0
- **Libraries:** OpenZeppelin 4.9.6 (Ownable, ReentrancyGuard, IERC20)
- **Testing:** Hardhat test framework with Chai assertions
- **Networks:** Hardhat local, Sepolia testnet, Ethereum mainnet, Polygon

## Development Commands

### Backend

```bash
# Install dependencies
pip install -r requirements.txt

# Copy environment file
cp .env.example .env

# Run the API server (localhost:8000)
python -m app.main

# API documentation
# Swagger UI: http://localhost:8000/docs
# ReDoc:      http://localhost:8000/redoc
```

### Smart Contracts

```bash
cd contracts/

# Install Node dependencies
npm install

# Compile contracts
npm run compile

# Run tests
npm run test

# Deploy to local Hardhat network
npm run deploy

# Deploy to Sepolia testnet
npm run deploy:sepolia

# Deploy to Ethereum mainnet
npm run deploy:mainnet
```

## Architecture

### Backend Pattern
The backend follows a layered architecture:

1. **Routes** (`app/api/`) — FastAPI routers handle HTTP requests, validate input, return responses
2. **Models** (`app/models/models.py`) — SQLAlchemy ORM models define database schema
3. **Core** (`app/core/`) — Shared infrastructure: config, database session, security utilities
4. **Services** (`app/services/`) — Business logic layer (placeholder, not yet populated)
5. **Schemas** (`app/schemas/`) — Pydantic validation schemas (placeholder, not yet populated)

Database sessions are injected via FastAPI's `Depends(get_db)` pattern.

### API Route Prefixes

| Prefix             | Module          | Purpose                       |
|--------------------|-----------------|-------------------------------|
| `/api/auth`        | `api/auth.py`   | Web3 wallet auth, registration, current user |
| `/api/users`       | `api/users.py`  | User profile read/update      |
| `/api/products`    | `api/products.py` | Product CRUD with filters   |
| `/api/orders`      | `api/orders.py` | Order lifecycle management    |
| `/api/payments`    | `api/payments.py` | Payment creation, currencies, rates |

### Authentication Flow
1. User signs a message with their Ethereum wallet
2. `POST /api/auth/web3` verifies the signature and creates/retrieves the user
3. A JWT token (HS256, 7-day expiry) is returned
4. Protected endpoints use `HTTPBearer` scheme to validate the token

### Database Models
- **User** — `wallet_address` (unique, indexed), `email`, `username`, `role` (user/seller/admin)
- **Product** — `name`, `product_type` (hardware/service/subscription), `price`, `specs` (JSON text), `seller_id`
- **Order** — `user_id`, `product_id`, `status` (pending/paid/processing/completed/cancelled/refunded), `transaction_hash`, `crypto_currency`
- **Subscription** — `user_id`, `product_id`, `period_months`, `starts_at`, `expires_at`

### Smart Contract Architecture
- **BotMarketPlace.sol** — Full marketplace with product management, order processing, auctions with bidding, subscriptions with renewal, multi-token support, 2.5% platform fee (configurable up to 10%), ReentrancyGuard protection
- **BotMarketPayment.sol** — Payment processing with order creation/payment/completion/cancellation, refund handling, fund withdrawals, 2.5% platform fee

Both contracts use OpenZeppelin's `Ownable` for admin access and emit events for all state changes.

## Environment Variables

Configured via `.env` file (loaded by pydantic-settings):

| Variable                   | Default                                        | Description                     |
|----------------------------|------------------------------------------------|---------------------------------|
| `DATABASE_URL`             | `postgresql://user:pass@localhost:5432/botmarket` | PostgreSQL connection string |
| `SECRET_KEY`               | `your-secret-key-change-in-production`         | JWT signing secret              |
| `ALGORITHM`                | `HS256`                                        | JWT algorithm                   |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `10080` (7 days)                            | JWT token expiry                |
| `WEB3_INFURA_PROJECT_ID`  | `None`                                         | Infura project ID               |
| `WEB3_CHAIN_ID`           | `1`                                            | Ethereum chain ID               |
| `AWS_ACCESS_KEY_ID`       | `None`                                         | AWS credentials                 |
| `AWS_SECRET_ACCESS_KEY`   | `None`                                         | AWS credentials                 |
| `AWS_REGION`              | `us-east-1`                                    | AWS region                      |
| `PAYMENT_CONTRACT_ADDRESS`| `None`                                         | Deployed payment contract address |

For smart contract deployment (in shell or `.env`):
- `SEPOLIA_URL`, `MAINNET_URL`, `POLYGON_URL` — RPC endpoints
- `PRIVATE_KEY` — Deployer wallet private key
- `ETHERSCAN_API_KEY`, `POLYGONSCAN_API_KEY` — Block explorer API keys

## Testing

### Smart Contract Tests
```bash
cd contracts && npm run test
```
Tests cover: token management, fee updates, order creation, payment flow, fund distribution.

### Backend Tests
No backend test suite exists yet. When adding tests:
- Use `pytest` with `httpx.AsyncClient` for FastAPI endpoint testing
- Place tests in a `tests/` directory at the project root
- Use fixtures for database session setup/teardown

## Key Conventions

### Python / Backend
- **Import style:** Absolute imports from `app.*` (e.g., `from app.core.config import settings`)
- **Route handlers:** Defined as plain functions (not async) since the database layer uses synchronous SQLAlchemy
- **Database sessions:** Obtained via `Depends(get_db)` — always use this pattern, never create sessions manually in routes
- **Enums:** Defined as `(str, enum.Enum)` subclasses in `models.py` for serialization compatibility
- **Soft deletes:** Products use `is_active = False` rather than actual deletion
- **Timestamps:** Use `server_default=func.now()` for `created_at`, `onupdate=func.now()` for `updated_at`
- **Settings:** Access via the singleton `settings` object from `app.core.config`

### Solidity / Contracts
- **Solidity version:** `^0.8.20`
- **OpenZeppelin:** Use v4.9.6 contracts (Ownable, ReentrancyGuard, IERC20)
- **Optimizer:** Enabled with 200 runs
- **Events:** Emit events for every state-changing operation
- **Access control:** Use `onlyOwner` modifier for admin functions
- **Security:** Apply `nonReentrant` modifier to functions that transfer tokens
- **Platform fee:** Stored as basis points-like percentage, configurable by owner

### General
- **No linter/formatter configured** — When adding, use `ruff` for Python linting/formatting and `solhint` for Solidity
- **No CI/CD configured** — When adding, set up GitHub Actions for Python tests + contract compilation/tests
- **CORS:** Currently allows all origins (`"*"`) — must be restricted before production deployment
- **Secret management:** Never commit `.env` files or private keys; the `SECRET_KEY` default must be changed in production

## Common Tasks for AI Assistants

### Adding a new API endpoint
1. Add the route handler function in the appropriate `app/api/*.py` module
2. Use `Depends(get_db)` for database access
3. Use `Depends(get_current_user)` from `app/core/security.py` for authenticated endpoints
4. Follow existing patterns: return dicts directly, raise `HTTPException` for errors

### Adding a new database model
1. Define the model class in `app/models/models.py` inheriting from `Base`
2. Use `Column` types consistent with existing models
3. Add relationships as needed with `relationship()`
4. Run Alembic migration: `alembic revision --autogenerate -m "description"` then `alembic upgrade head`

### Modifying smart contracts
1. Edit `.sol` files in `contracts/`
2. Compile: `cd contracts && npm run compile`
3. Add/update tests in `contracts/test/`
4. Run tests: `npm run test`
5. Deployment info is saved to `contracts/deployment.json`

### Areas not yet implemented
- `app/schemas/` — Pydantic request/response models (currently inline or implicit)
- `app/services/` — Business logic layer (currently lives in route handlers)
- Backend test suite
- Alembic migration files
- Frontend application
- Real on-chain payment verification (currently mock)
- Real price oracle (currently hardcoded rates)
- Rate limiting and API versioning
