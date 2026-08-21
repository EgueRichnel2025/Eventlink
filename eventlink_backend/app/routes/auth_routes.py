"""
routes/auth_routes.py
Rôle : endpoints liés à l'inscription et la connexion des utilisateurs.

Responsable suggéré : Dine
"""

from fastapi import APIRouter, HTTPException
from app.database import get_collection
from app.schemas.user_schema import UserCreate, UserLogin, UserOut
from app.utils.security import hasher_mot_de_passe
from app.services.auth_service import verifier_email_existe, authentifier_utilisateur

router = APIRouter()


@router.post("/register", response_model=UserOut)
async def register(user: UserCreate):
    """
    Crée un nouvel utilisateur.
    """
    if await verifier_email_existe(user.email):
        raise HTTPException(status_code=400, detail="Cet email est déjà utilisé.")

    utilisateur_a_creer = {
        "nom": user.nom,
        "email": user.email,
        "mot_de_passe_hash": hasher_mot_de_passe(user.mot_de_passe),
        "fcm_token": None,
        "groupe_id": None,
    }

    users = get_collection("users")
    resultat = await users.insert_one(utilisateur_a_creer)

    return UserOut(
        id=str(resultat.inserted_id),
        nom=user.nom,
        email=user.email,
        groupe_id=None,
    )


@router.post("/login", response_model=UserOut)
async def login(credentials: UserLogin):
    """
    Connecte un utilisateur existant.
    """
    utilisateur = await authentifier_utilisateur(credentials.email, credentials.mot_de_passe)

    if utilisateur is None:
        raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect.")

    return UserOut(
        id=str(utilisateur["_id"]),
        nom=utilisateur["nom"],
        email=utilisateur["email"],
        groupe_id=utilisateur.get("groupe_id"),
    )