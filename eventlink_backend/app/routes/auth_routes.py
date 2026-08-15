"""
routes/auth_routes.py
Rôle : endpoints liés à l'inscription et la connexion des utilisateurs.

Responsable suggéré : Dine
"""

from fastapi import APIRouter
from app.schemas.user_schema import UserCreate, UserLogin, UserOut

router = APIRouter()


@router.post("/register")
async def register(user: UserCreate):
    """
    Crée un nouvel utilisateur.

    TODO:
    - vérifier que l'email n'existe pas déjà en base
    - hasher le mot de passe (voir app/utils/security.py)
    - enregistrer l'utilisateur dans MongoDB (collection "users")
    - retourner l'utilisateur créé (sans le mot de passe)
    """
    pass


@router.post("/login")
async def login(credentials: UserLogin):
    """
    Connecte un utilisateur existant.

    TODO:
    - chercher l'utilisateur par email en base
    - vérifier que le mot de passe correspond (voir app/utils/security.py)
    - retourner les infos de l'utilisateur si tout est bon
    - sinon retourner une erreur 401
    """
    pass
