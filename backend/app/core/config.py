import os
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parents[2]
PROJECT_ROOT = BASE_DIR.parent

load_dotenv(BASE_DIR / ".env", override=False)


def _bool(name: str, default: str) -> bool:
    return os.getenv(name, default).lower() == "true"


class Settings:
    APP_NAME: str = os.getenv("APP_NAME", "SmartCity AI Platform")
    APP_ENV: str = os.getenv("APP_ENV", "development")
    DEBUG: bool = _bool("DEBUG", "true")
    API_V1_PREFIX: str = os.getenv("API_V1_PREFIX", "/api/v1")

    DATABASE_URL: str = os.getenv("DATABASE_URL", "")

    SECRET_KEY: str = os.getenv(
        "SECRET_KEY",
        "development-only-change-this-secret",
    )
    JWT_ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")

    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")

    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(
        os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30")
    )

    REFRESH_TOKEN_EXPIRE_DAYS: int = int(
        os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "7")
    )

    # --- Member 1: authentication / email ---------------------------------
    # Lifetime of email-verification and password-reset codes.
    EMAIL_CODE_EXPIRE_MINUTES: int = int(
        os.getenv("EMAIL_CODE_EXPIRE_MINUTES", "15")
    )
    # Set to false while developing without a mail server.
    REQUIRE_EMAIL_VERIFICATION: bool = _bool("REQUIRE_EMAIL_VERIFICATION", "true")

    # If SMTP_HOST is empty, emails are printed to the server console instead.
    SMTP_HOST: str = os.getenv("SMTP_HOST", "")
    SMTP_PORT: int = int(os.getenv("SMTP_PORT", "587"))
    SMTP_USER: str = os.getenv("SMTP_USER", "")
    SMTP_PASSWORD: str = os.getenv("SMTP_PASSWORD", "")
    EMAIL_FROM: str = os.getenv("EMAIL_FROM", "no-reply@smartcity.local")


settings = Settings()