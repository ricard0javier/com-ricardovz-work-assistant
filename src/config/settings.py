"""Application settings and configuration."""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # MongoDB
    mongodb_uri: str = "mongodb://admin:admin@localhost:27017/?directConnection=true"
    mongodb_database: str = "demo"
    mongodb_max_pool_size: int = 100
    mongodb_min_pool_size: int = 10

    # PostgreSQL
    postgres_host: str = "localhost"
    postgres_port: int = 5432
    postgres_user: str = "postgres"
    postgres_password: str = "postgres"

    # Kafka/Redpanda
    kafka_bootstrap_servers: str = "localhost:19092"
    kafka_auto_offset_reset: str = "earliest"
    kafka_consumer_group: str = "demo-group"

    # Logging
    log_level: str = "INFO"

    # Browserless
    browserless_url: str = "http://localhost:3000"

    # Prefect
    prefect_api_url: str = "http://localhost:4200/api"


settings = Settings()

