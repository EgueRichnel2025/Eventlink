from bson import ObjectId

from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.database.mongodb import get_database

from app.schemas.auth_schemas import (
    AccessTokenResponse,
    ConnexionCodeRequest,
    ConnexionEmailRequest,
    ConnexionRequest,
    CreerProfilRequest,
    DemanderCodeEmailRequest,
    RefreshRequest,
    ReinitialiserMotDePasseRequest,
    ResetTokenResponse,
    TokenResponse,
    UserPublic,
    UpdateProfilRequest,
    VerifierCodeEmailRequest,
)

from app.services import auth_service

from app.utils.dependencies import get_current_user


router = APIRouter(
    prefix="/auth",
    tags=["Authentification"],
)


@router.post(
    "/profil",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
)
async def creer_profil(
    payload: CreerProfilRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Première utilisation : crée le profil et renvoie les tokens."""

    user = await auth_service.creer_profil(
        db,
        payload.prenom,
        payload.nom,
        payload.email,
        payload.password,
        avatar_id=payload.avatar_id,
    )

    access_token, refresh_token = await auth_service.emettre_tokens(
        db,
        user["_id"],
    )

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user=UserPublic.model_validate(user),
    )


@router.post(
    "/connexion-email",
    response_model=TokenResponse,
)
async def connecter_avec_email(
    payload: ConnexionEmailRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Connecte un compte avec son adresse email et son mot de passe."""

    user, access_token, refresh_token = (
        await auth_service.connecter_avec_email_et_mot_de_passe(
            db,
            payload.email,
            payload.password,
        )
    )

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user=UserPublic.model_validate(user),
    )


@router.post(
    "/connexion",
    response_model=TokenResponse,
)
async def connecter_compte(
    payload: ConnexionRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Connecte un compte avec son mot de passe."""

    user, access_token, refresh_token = (
        await auth_service.connecter_avec_mot_de_passe(
            db,
            ObjectId(payload.user_id),
            payload.password,
        )
    )

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user=UserPublic.model_validate(user),
    )


@router.post(
    "/connexion-code",
    response_model=UserPublic,
)
async def trouver_compte_avec_code(
    payload: ConnexionCodeRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """
    Recherche un compte avec son code EventLink.

    Ce endpoint n'ouvre pas de session.
    Le mot de passe est ensuite demandé.
    """

    user = await auth_service.trouver_compte_avec_code(
        db,
        payload.account_code,
    )

    return UserPublic.model_validate(user)


@router.post(
    "/email/demander-code",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def demander_code_email(
    payload: DemanderCodeEmailRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Envoie un code de récupération à l'adresse email du compte."""

    await auth_service.demander_code_email(
        db,
        payload.email,
    )


@router.post(
    "/email/verifier-code",
    response_model=ResetTokenResponse,
)
async def verifier_code_email(
    payload: VerifierCodeEmailRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """
    Vérifie le code reçu par email.

    Aucun JWT de connexion n'est créé ici.
    """

    reset_token = await auth_service.verifier_code_email(
        db,
        payload.email,
        payload.code,
    )

    return ResetTokenResponse(
        reset_token=reset_token,
    )


@router.post(
    "/mot-de-passe/reinitialiser",
    response_model=TokenResponse,
)
async def reinitialiser_mot_de_passe(
    payload: ReinitialiserMotDePasseRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """
    Définit un nouveau mot de passe après vérification du code email.
    """

    user, access_token, refresh_token = (
        await auth_service.reinitialiser_mot_de_passe(
            db,
            payload.reset_token,
            payload.new_password,
        )
    )

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user=UserPublic.model_validate(user),
    )


@router.post(
    "/refresh",
    response_model=AccessTokenResponse,
)
async def rafraichir(
    payload: RefreshRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    access_token = await auth_service.rafraichir_access_token(
        db,
        payload.refresh_token,
    )

    return AccessTokenResponse(
        access_token=access_token,
    )


@router.get(
    "/moi",
    response_model=UserPublic,
)
async def mon_profil(
    user: dict = Depends(get_current_user),
):
    return UserPublic.model_validate(user)


@router.put(
    "/moi",
    response_model=UserPublic,
)
async def modifier_mon_profil(
    payload: UpdateProfilRequest,
    user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    updated = await auth_service.modifier_profil(
        db,
        ObjectId(user["_id"]),
        payload.model_dump(),
    )

    return UserPublic.model_validate(updated)
