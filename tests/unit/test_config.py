"""Unit tests for application configuration."""

import os
import pytest

from src.api.app.config import Settings, get_settings


class TestSettings:
    """Test suite for Settings configuration."""

    def test_default_settings(self):
        """Test that Settings has expected defaults."""
        settings = Settings()

        assert settings.app_name == "Azure Infrastructure API"
        assert settings.app_version == "1.0.0"
        assert settings.debug is False
        assert settings.log_level == "INFO"

    def test_database_settings_defaults(self):
        """Test database settings defaults."""
        settings = Settings()

        assert settings.database_url is None
        assert settings.database_pool_size == 5
        assert settings.database_max_overflow == 10

    def test_azure_settings_defaults(self):
        """Test Azure settings defaults."""
        settings = Settings()

        assert settings.azure_storage_connection_string is None
        assert settings.azure_key_vault_url is None
        assert settings.applicationinsights_connection_string is None

    def test_security_settings_defaults(self):
        """Test security settings defaults."""
        settings = Settings()

        assert settings.cors_origins == "*"
        assert settings.api_key is None

    def test_settings_from_env(self, monkeypatch):
        """Test that settings can be loaded from environment."""
        monkeypatch.setenv("APP_NAME", "Test API")
        monkeypatch.setenv("DEBUG", "true")
        monkeypatch.setenv("LOG_LEVEL", "DEBUG")

        # Create new settings instance (bypass cache)
        settings = Settings()

        assert settings.app_name == "Test API"
        assert settings.debug is True
        assert settings.log_level == "DEBUG"

    def test_get_settings_returns_settings(self):
        """Test that get_settings returns a Settings instance."""
        # Clear the cache to get fresh settings
        get_settings.cache_clear()
        settings = get_settings()

        assert isinstance(settings, Settings)

    def test_get_settings_is_cached(self):
        """Test that get_settings returns cached instance."""
        get_settings.cache_clear()
        settings1 = get_settings()
        settings2 = get_settings()

        assert settings1 is settings2
