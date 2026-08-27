from bson import ObjectId
from fastapi import APIRouter, Depends, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.database.mongodb import get_database
from app.schemas.auth_schemas import (
    AccessTokenResponse,
    CreerProfilRequest,
    RefreshRequest,
    TokenResponse,
    UpdateProfilRequest,
    UserPublic,
)
from app.services import auth_service
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/auth", tags=["Authentification"])


@router.post("/profil", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def creer_profil(payload: CreerProfilRequest, db: AsyncIOMotorDatabase = Depends(get_database)):
    """Première utilisation : crée le profil (prénom/nom) et renvoie les tokens de session."""
    user = await auth_service.creer_profil(db, payload.prenom, payload.nom)
    access_token, refresh_token = await auth_service.emettre_tokens(db, user["_id"])
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user=UserPublic.model_validate(user),
    )


@router.post("/refresh", response_model=AccessTokenResponse)
async def rafraichir(payload: RefreshRequest, db: AsyncIOMotorDatabase = Depends(get_database)):
    access_token = await auth_service.rafraichir_access_token(db, payload.refresh_token)
    return AccessTokenResponse(access_token=access_token)


@router.get("/moi", response_model=UserPublic)
async def mon_profil(user: dict = Depends(get_current_user)):
    return UserPublic.model_validate(user)


@router.put("/moi", response_model=UserPublic)
async def modifier_mon_profil(
    payload: UpdateProfilRequest,
    user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    updated = await auth_service.modifier_profil(db, ObjectId(user["_id"]), payload.model_dump())
    return UserPublic.model_validate(updated)
