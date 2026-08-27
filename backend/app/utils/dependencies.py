"""
Dépendances FastAPI réutilisées par les routes protégées.
"""

from bson import ObjectId
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.database.mongodb import get_database
from app.utils.security import JWTError, decode_token

bearer_scheme = HTTPBearer(auto_error=False)


async def get_current_user_id(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> str:
    """Décode le JWT d'accès et renvoie l'id utilisateur (string)."""
    if credentials is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Authentification requise")

    try:
        payload = decode_token(credentials.credentials)
    except JWTError:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Token invalide ou expiré")

    if payload.get("type") != "access":
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Type de token invalide")

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Token invalide")

    return user_id


async def get_current_user(
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> dict:
    """Charge le document utilisateur complet, vérifie qu'il existe toujours."""
    user = await db.users.find_one({"_id": ObjectId(user_id)})
    if user is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Utilisateur introuvable")
    return user


async def require_group_member(
    group_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> dict:
    """Vérifie que l'utilisateur courant appartient bien au groupe donné.

    Le backend ne fait jamais confiance au frontend pour l'appartenance à un
    groupe : cette vérification est systématique sur toutes les routes
    liées à un group_id (events, membres, settings...).
    """
    if not ObjectId.is_valid(group_id):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Identifiant de groupe invalide")

    membership = await db.group_members.find_one(
        {"group_id": ObjectId(group_id), "user_id": ObjectId(user_id)}
    )
    if membership is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Vous n'êtes pas membre de ce groupe")

    return membership
