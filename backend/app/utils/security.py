"""
Utilitaires de sécurité : hashage des secrets, JWT, génération de codes.
"""

import random
import secrets
import string
from datetime import datetime, timedelta, timezone

import bcrypt
from jose import JWTError, jwt

from app.config.settings import settings


# ---------------------------------------------------------------------------
# Hashage (utilisé si un mot de passe est ajouté plus tard au profil)
# ---------------------------------------------------------------------------

def hash_secret(raw: str) -> str:
    return bcrypt.hashpw(raw.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_secret(raw: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(raw.encode("utf-8"), hashed.encode("utf-8"))
    except ValueError:
        return False


# ---------------------------------------------------------------------------
# JWT (access + refresh)
# ---------------------------------------------------------------------------

def create_access_token(user_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    payload = {"sub": user_id, "type": "access", "exp": expire}
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def create_refresh_token(user_id: str) -> tuple[str, datetime]:
    expire = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    payload = {"sub": user_id, "type": "refresh", "exp": expire}
    token = jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return token, expire


def decode_token(token: str) -> dict:
    """Lève JWTError si le token est invalide ou expiré."""
    return jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])


def hash_token(token: str) -> str:
    """Hash stocké en base pour les refresh tokens (ne jamais stocker le token brut)."""
    return hash_secret(token)


# ---------------------------------------------------------------------------
# Codes d'invitation de groupe
# ---------------------------------------------------------------------------

_ALPHABET = string.ascii_uppercase + string.digits


def generate_invite_code(length: int = 6) -> str:
    return "".join(random.SystemRandom().choice(_ALPHABET) for _ in range(length))


def generate_opaque_id() -> str:
    return secrets.token_urlsafe(16)


__all__ = [
    "hash_secret",
    "verify_secret",
    "create_access_token",
    "create_refresh_token",
    "decode_token",
    "hash_token",
    "generate_invite_code",
    "generate_opaque_id",
    "JWTError",
]
