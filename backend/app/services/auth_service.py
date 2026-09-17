"""
Service d'authentification EventLink.

L'authentification normale utilise le mot de passe.
L'adresse email est utilisée uniquement pour la récupération
du mot de passe.

Les mots de passe ne sont jamais stockés en clair.
"""

import hashlib
import secrets
from datetime import datetime, timedelta, timezone

from bson import ObjectId
from fastapi import HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.config.settings import settings
from app.services.email_service import envoyer_code_verification
from app.utils.security import (
    JWTError,
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_secret,
    hash_token,
    verify_secret,
)


def generer_code_compte() -> str:
    """Génère un code unique au format EL-XXXXXX."""

    caracteres = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

    return "EL-" + "".join(
        secrets.choice(caracteres)
        for _ in range(6)
    )


async def creer_code_compte_unique(
    db: AsyncIOMotorDatabase,
) -> str:
    """Génère un code qui n'existe pas encore dans la collection users."""

    while True:
        code = generer_code_compte()

        existe = await db.users.find_one(
            {"account_code": code}
        )

        if existe is None:
            return code


def normaliser_email(email: str) -> str:
    """Normalise une adresse email pour éviter les doublons liés à la casse."""

    return email.strip().lower()


def valider_mot_de_passe(password: str) -> None:
    """
    Vérifie les règles minimales du mot de passe.

    La longueur minimale est également contrôlée par Pydantic.
    """

    if len(password) < 8:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Le mot de passe doit contenir au moins 8 caractères.",
        )


async def creer_profil(
    db: AsyncIOMotorDatabase,
    prenom: str,
    nom: str,
    email: str,
    password: str,
    avatar_id: str = "avatar_01",
) -> dict:
    """Crée un nouveau compte EventLink."""

    email_normalise = normaliser_email(email)

    valider_mot_de_passe(password)

    email_existant = await db.users.find_one(
        {"email": email_normalise}
    )

    if email_existant is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Cette adresse email est déjà associée à un compte EventLink.",
        )

    now = datetime.now(timezone.utc)

    account_code = await creer_code_compte_unique(db)

    result = await db.users.insert_one(
        {
            "prenom": prenom.strip(),
            "nom": nom.strip(),
            "email": email_normalise,
            "email_verified": False,
            "password_hash": hash_secret(password),
            "photo_url": None,
            "avatar_id": avatar_id,
            "account_code": account_code,
            "fcm_token": None,
            "created_at": now,
        }
    )

    user = await db.users.find_one(
        {"_id": result.inserted_id}
    )

    return user


async def emettre_tokens(
    db: AsyncIOMotorDatabase,
    user_id: ObjectId,
) -> tuple[str, str]:
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


async def connecter_avec_mot_de_passe(
    db: AsyncIOMotorDatabase,
    user_id: ObjectId,
    password: str,
) -> tuple[dict, str, str]:
    """Authentifie un compte existant avec son mot de passe."""

    user = await db.users.find_one(
        {"_id": user_id}
    )

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Utilisateur introuvable.",
        )

    password_hash = user.get("password_hash")

    if not password_hash:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Ce compte doit être sécurisé avec un nouveau mot de passe.",
        )

    if not verify_secret(password, password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Mot de passe incorrect.",
        )

    access_token, refresh_token = await emettre_tokens(
        db,
        user["_id"],
    )

    return user, access_token, refresh_token



async def connecter_avec_email_et_mot_de_passe(
    db: AsyncIOMotorDatabase,
    email: str,
    password: str,
) -> tuple[dict, str, str]:
    """Authentifie un compte existant avec son adresse email et son mot de passe."""

    email_normalise = normaliser_email(email)

    user = await db.users.find_one(
        {"email": email_normalise}
    )

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Adresse email ou mot de passe incorrect.",
        )

    password_hash = user.get("password_hash")

    if not password_hash:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Ce compte doit être sécurisé avec un nouveau mot de passe.",
        )

    if not verify_secret(password, password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Adresse email ou mot de passe incorrect.",
        )

    access_token, refresh_token = await emettre_tokens(
        db,
        user["_id"],
    )

    return user, access_token, refresh_token

async def trouver_compte_avec_code(
    db: AsyncIOMotorDatabase,
    account_code: str,
) -> dict:
    """
    Recherche un compte avec son code EventLink.

    Important :
    cette fonction n'émet aucun JWT.
    Le mot de passe doit ensuite être vérifié.
    """

    code = account_code.strip().upper()

    user = await db.users.find_one(
        {"account_code": code}
    )

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Code de compte invalide.",
        )

    return user


async def rafraichir_access_token(
    db: AsyncIOMotorDatabase,
    refresh_token: str,
) -> str:
    try:
        payload = decode_token(refresh_token)
    except JWTError:
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            "Refresh token invalide ou expiré",
        )

    if payload.get("type") != "refresh":
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            "Type de token invalide",
        )

    user_id = payload.get("sub")

    try:
        object_id = ObjectId(user_id)
    except Exception:
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            "Utilisateur invalide",
        )

    user = await db.users.find_one(
        {"_id": object_id}
    )

    if user is None:
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            "Utilisateur introuvable",
        )

    return create_access_token(user_id)


async def modifier_profil(
    db: AsyncIOMotorDatabase,
    user_id: ObjectId,
    updates: dict,
) -> dict:
    updates = {
        k: v
        for k, v in updates.items()
        if v is not None
    }

    if updates:
        await db.users.update_one(
            {"_id": user_id},
            {"$set": updates},
        )

    return await db.users.find_one(
        {"_id": user_id}
    )


# ============================================================
# Récupération du mot de passe
# ============================================================


def generer_code_verification() -> str:
    """Génère un code de vérification numérique à 6 chiffres."""

    return f"{secrets.randbelow(1_000_000):06d}"


def hasher_code_verification(code: str) -> str:
    """Hash SHA-256 du code de vérification."""

    return hashlib.sha256(
        code.encode("utf-8")
    ).hexdigest()


def generer_reset_token() -> str:
    """Génère un token de récupération suffisamment aléatoire."""

    return secrets.token_urlsafe(48)


def hasher_reset_token(token: str) -> str:
    """Hash SHA-256 du token de récupération."""

    return hashlib.sha256(
        token.encode("utf-8")
    ).hexdigest()


async def demander_code_email(
    db: AsyncIOMotorDatabase,
    email: str,
) -> None:
    """
    Génère et envoie un code de récupération.

    Le code brut n'est jamais enregistré dans MongoDB.
    """

    email_normalise = normaliser_email(email)

    user = await db.users.find_one(
        {"email": email_normalise}
    )

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Aucun compte EventLink associé à cette adresse email.",
        )

    code = generer_code_verification()
    code_hash = hasher_code_verification(code)

    now = datetime.now(timezone.utc)

    expires_at = now + timedelta(
        minutes=settings.EMAIL_VERIFICATION_CODE_EXPIRE_MINUTES
    )

    await db.email_verifications.delete_many(
        {
            "email": email_normalise,
        }
    )

    await db.email_verifications.insert_one(
        {
            "email": email_normalise,
            "user_id": user["_id"],
            "code_hash": code_hash,
            "created_at": now,
            "expires_at": expires_at,
        }
    )

    try:
        envoyer_code_verification(
            email_normalise,
            code,
        )
    except Exception as exc:
        await db.email_verifications.delete_many(
            {
                "email": email_normalise,
                "code_hash": code_hash,
            }
        )

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Impossible d'envoyer le code de récupération.",
        ) from exc


async def verifier_code_email(
    db: AsyncIOMotorDatabase,
    email: str,
    code: str,
) -> str:
    """
    Vérifie le code envoyé par email.

    Retourne un token temporaire permettant de définir
    un nouveau mot de passe.

    Aucun JWT de connexion n'est émis à cette étape.
    """

    email_normalise = normaliser_email(email)
    code_normalise = code.strip()

    verification = await db.email_verifications.find_one(
        {
            "email": email_normalise,
        }
    )

    if verification is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Aucun code de vérification actif.",
        )

    now = datetime.now(timezone.utc)

    expires_at = verification["expires_at"]

    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(
            tzinfo=timezone.utc
        )

    if now > expires_at:
        await db.email_verifications.delete_one(
            {"_id": verification["_id"]}
        )

        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Le code de vérification a expiré.",
        )

    code_hash = hasher_code_verification(
        code_normalise
    )

    if not secrets.compare_digest(
        code_hash,
        verification["code_hash"],
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Code de vérification incorrect.",
        )

    reset_token = generer_reset_token()
    reset_token_hash = hasher_reset_token(reset_token)

    reset_expires_at = now + timedelta(
        minutes=settings.PASSWORD_RESET_TOKEN_EXPIRE_MINUTES
    )

    await db.password_resets.delete_many(
        {
            "user_id": verification["user_id"],
        }
    )

    await db.password_resets.insert_one(
        {
            "user_id": verification["user_id"],
            "token_hash": reset_token_hash,
            "created_at": now,
            "expires_at": reset_expires_at,
        }
    )

    await db.email_verifications.delete_one(
        {"_id": verification["_id"]}
    )

    return reset_token


async def reinitialiser_mot_de_passe(
    db: AsyncIOMotorDatabase,
    reset_token: str,
    new_password: str,
) -> tuple[dict, str, str]:
    """
    Définit un nouveau mot de passe après vérification de l'email.
    """

    valider_mot_de_passe(new_password)

    token_hash = hasher_reset_token(
        reset_token.strip()
    )

    reset = await db.password_resets.find_one(
        {
            "token_hash": token_hash,
        }
    )

    if reset is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Le lien de récupération est invalide.",
        )

    now = datetime.now(timezone.utc)

    expires_at = reset["expires_at"]

    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(
            tzinfo=timezone.utc
        )

    if now > expires_at:
        await db.password_resets.delete_one(
            {"_id": reset["_id"]}
        )

        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La récupération du mot de passe a expiré.",
        )

    user = await db.users.find_one(
        {"_id": reset["user_id"]}
    )

    if user is None:
        await db.password_resets.delete_one(
            {"_id": reset["_id"]}
        )

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Utilisateur introuvable.",
        )

    await db.users.update_one(
        {"_id": user["_id"]},
        {
            "$set": {
                "password_hash": hash_secret(new_password),
            }
        },
    )

    await db.password_resets.delete_one(
        {"_id": reset["_id"]}
    )

    # Invalide les anciennes sessions de l'utilisateur.
    await db.refresh_tokens.update_many(
        {
            "user_id": user["_id"],
            "revoked": False,
        },
        {
            "$set": {
                "revoked": True,
            }
        },
    )

    user["password_hash"] = None

    access_token, refresh_token = await emettre_tokens(
        db,
        user["_id"],
    )

    return user, access_token, refresh_token
