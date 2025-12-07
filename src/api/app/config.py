"""Application configuration using Pydantic Settings."""

from functools import lru_cache
from typing import Optional

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Application
    app_name: str = "Azure Infrastructure API"
    app_version: str = "1.0.0"
    debug: bool = False
    log_level: str = "INFO"

    # Database
    database_url: Optional[str] = None
    database_pool_size: int = 5
    database_max_overflow: int = 10

    # Azure
    azure_storage_connection_string: Optional[str] = None
    azure_key_vault_url: Optional[str] = None
    applicationinsights_connection_string: Optional[str] = None

    # Security
    cors_origins: str = "*"
    api_key: Optional[str] = None

    class Config:
        """Pydantic configuration."""

        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False


@lru_cache
def get_settings() -> Settings:
    """Get cached application settings."""
    return Settings()
