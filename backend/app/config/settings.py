"""
Configuration centralisée de l'application EventLink.

Toutes les valeurs sensibles ou dépendantes de l'environnement doivent être
lues ici, jamais codées en dur ailleurs dans le projet.
"""

import os
from functools import lru_cache

from dotenv import load_dotenv

load_dotenv()


class Settings:
    """Regroupe toute la configuration lue depuis les variables d'environnement."""

    # MongoDB
    MONGODB_URI: str = os.getenv(
        "MONGODB_URI",
        "mongodb://localhost:27017",
    )
    MONGODB_DB_NAME: str = os.getenv(
        "MONGODB_DB_NAME",
        "eventlink",
    )

    # JWT
    JWT_SECRET_KEY: str = os.getenv(
        "JWT_SECRET_KEY",
        "insecure-dev-secret-change-me",
    )
    JWT_ALGORITHM: str = os.getenv(
        "JWT_ALGORITHM",
        "HS256",
    )
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(
        os.getenv(
            "ACCESS_TOKEN_EXPIRE_MINUTES",
            "60",
        )
    )
    REFRESH_TOKEN_EXPIRE_DAYS: int = int(
        os.getenv(
            "REFRESH_TOKEN_EXPIRE_DAYS",
            "30",
        )
    )

    # Firebase Cloud Messaging (optionnel)
    FIREBASE_CREDENTIALS_PATH: str = os.getenv(
        "FIREBASE_CREDENTIALS_PATH",
        "",
    )

    # CORS
    CORS_ORIGINS: list[str] = (
        ["*"]
        if os.getenv("CORS_ORIGINS", "*") == "*"
        else os.getenv(
            "CORS_ORIGINS",
            "",
        ).split(",")
    )

    # App
    ENV: str = os.getenv(
        "ENV",
        "development",
    )

    # Email / SMTP Brevo
    EMAIL_HOST: str = os.getenv(
        "EMAIL_HOST",
        "smtp-relay.brevo.com",
    )
    EMAIL_PORT: int = int(
        os.getenv(
            "EMAIL_PORT",
            "587",
        )
    )
    EMAIL_USERNAME: str = os.getenv(
        "EMAIL_USERNAME",
        "",
    )
    EMAIL_PASSWORD: str = os.getenv(
        "EMAIL_PASSWORD",
        "",
    )
    EMAIL_FROM: str = os.getenv(
        "EMAIL_FROM",
        "",
    )
    EMAIL_FROM_NAME: str = os.getenv(
        "EMAIL_FROM_NAME",
        "EventLink",
    )

    # Vérification par email
    EMAIL_VERIFICATION_CODE_EXPIRE_MINUTES: int = int(
        os.getenv(
            "EMAIL_VERIFICATION_CODE_EXPIRE_MINUTES",
            "10",
        )
    )

    # Token temporaire de réinitialisation du mot de passe
    PASSWORD_RESET_TOKEN_EXPIRE_MINUTES: int = int(
        os.getenv(
            "PASSWORD_RESET_TOKEN_EXPIRE_MINUTES",
            "10",
        )
    )

    @property
    def is_production(self) -> bool:
        return self.ENV.lower() == "production"


@lru_cache
def get_settings() -> Settings:
    """Retourne une instance mise en cache des settings."""

    return Settings()


settings = get_settings()