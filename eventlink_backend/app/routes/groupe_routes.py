"""
routes/groupe_routes.py
Rôle : endpoints liés à la création et à la gestion des groupes.

Responsable suggéré : Dine
"""

from fastapi import APIRouter
from app.schemas.groupe_schema import GroupeCreate, GroupeJoin, GroupeOut

router = APIRouter()


@router.post("/creer")
async def creer_groupe(groupe: GroupeCreate):
    """
    Crée un nouveau groupe.

    TODO:
    - générer un code_invitation unique (voir app/utils/security.py)
    - enregistrer le groupe en base (collection "groupes")
    - retourner le groupe créé avec son code
    """
    pass


@router.post("/rejoindre")
async def rejoindre_groupe(data: GroupeJoin):
    """
    Permet à un utilisateur de rejoindre un groupe via un code d'invitation.

    TODO:
    - chercher le groupe correspondant au code_invitation
    - si non trouvé, retourner une erreur claire
    - ajouter l'utilisateur à la liste des membres du groupe
    - retourner le groupe rejoint
    """
    pass


@router.get("/{groupe_id}")
async def get_groupe(groupe_id: str):
    """
    Récupère les infos d'un groupe par son id.

    TODO:
    - chercher le groupe en base par son _id
    - retourner ses infos (nom, membres, etc.)
    """
    pass
