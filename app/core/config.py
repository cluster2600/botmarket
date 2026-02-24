from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # Database
    DATABASE_URL: str = "postgresql://user:pass@localhost:5432/botmarket"
    
    # JWT
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # Web3
    WEB3_INFURA_PROJECT_ID: Optional[str] = None
    WEB3_CHAIN_ID: int = 1  # Ethereum mainnet
    
    # AWS
    AWS_ACCESS_KEY_ID: Optional[str] = None
    AWS_SECRET_ACCESS_KEY: Optional[str] = None
    AWS_REGION: str = "us-east-1"
    
    # Crypto Payments
    PAYMENT_CONTRACT_ADDRESS: Optional[str] = None
    
    class Config:
        env_file = ".env"

settings = Settings()
