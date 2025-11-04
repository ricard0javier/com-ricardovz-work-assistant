"""Tests for configuration."""

from src.config.settings import settings


def test_settings_loaded():
    """Test that settings can be loaded."""
    assert settings.mongodb_uri is not None
    assert settings.mongodb_database == "demo"

