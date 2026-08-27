"""
Service d'authentification : création de profil et gestion des tokens.

Pour le MVP, l'authentification ne repose pas sur un mot de passe : un
profil (prénom/nom) est créé et identifié par un JWT. L'architecture est
prête pour ajouter un mot de passe/email plus tard (cf. hash_secret dans
security.py) sans tout casser.
"""

from datetime import datetime, timezone

from bson import ObjectId
from fastapi import HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.utils.security import create_access_token, create_refresh_token, hash_token, decode_token, JWTError


async def creer_profil(db: AsyncIOMotorDatabase, prenom: str, nom: str) -> dict:
    now = datetime.now(timezone.utc)
    result = await db.users.insert_one(
        {
            "prenom": prenom.strip(),
            "nom": nom.strip(),
            "photo_url": None,
            "fcm_token": None,
            "created_at": now,
        }
    )
    user = await db.users.find_one({"_id": result.inserted_id})
    return user


async def emettre_tokens(db: AsyncIOMotorDatabase, user_id: ObjectId) -> tuple[str, str]:
    access_token = create_access_token(str(user_id))
    refresh_token, expires_at = create_refresh_token(str(user_id))

    await db.refresh_tokens.insert_one(
        {
            "user_id": user_id,
            "token_hash": hash_token(refresh_token),
            "expires_at": expires_at,
            "revoked": False,
        }
    )
    return access_token, refresh_token


async def rafraichir_access_token(db: AsyncIOMotorDatabase, refresh_token: str) -> str:
    try:
        payload = decode_token(refresh_token)
    except JWTError:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Refresh token invalide ou expiré")

    if payload.get("type") != "refresh":
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Type de token invalide")

    user_id = payload.get("sub")
    user = await db.users.find_one({"_id": ObjectId(user_id)})
    if user is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Utilisateur introuvable")

    return create_access_token(user_id)


async def modifier_profil(db: AsyncIOMotorDatabase, user_id: ObjectId, updates: dict) -> dict:
    updates = {k: v for k, v in updates.items() if v is not None}
    if updates:
        await db.users.update_one({"_id": user_id}, {"$set": updates})
    return await db.users.find_one({"_id": user_id})
