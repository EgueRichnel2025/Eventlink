from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.database.mongodb import get_database
from app.schemas.group_schemas import (
    CreerGroupeRequest,
    GroupePublic,
    MembreGroupePublic,
    ModifierGroupeRequest,
    RejoindreGroupeRequest,
)
from app.services import group_service
from app.utils.dependencies import get_current_user_id, require_group_member

router = APIRouter(prefix="/groupes", tags=["Groupes"])


@router.post("/creer", response_model=GroupePublic, status_code=status.HTTP_201_CREATED)
async def creer_groupe(
    payload: CreerGroupeRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    groupe = await group_service.creer_groupe(db, ObjectId(user_id), payload.nom)
    return GroupePublic.model_validate(groupe)


@router.post("/rejoindre", response_model=GroupePublic)
async def rejoindre_groupe(
    payload: RejoindreGroupeRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    groupe = await group_service.rejoindre_groupe(db, ObjectId(user_id), payload.code_invitation)
    return GroupePublic.model_validate(groupe)


@router.get("/mes-groupes", response_model=list[GroupePublic])
async def mes_groupes(
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Retourne TOUS les groupes de l'utilisateur — jamais un seul groupe actif."""
    groupes = await group_service.lister_mes_groupes(db, ObjectId(user_id))
    return [GroupePublic.model_validate(g) for g in groupes]


@router.get("/{group_id}", response_model=GroupePublic)
async def obtenir_groupe(
    group_id: str,
    user_id: str = Depends(get_current_user_id),
    _membership: dict = Depends(require_group_member),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    groupe = await group_service.obtenir_groupe(db, ObjectId(group_id), ObjectId(user_id))
    return GroupePublic.model_validate(groupe)


@router.get("/{group_id}/membres", response_model=list[MembreGroupePublic])
async def membres_groupe(
    group_id: str,
    _membership: dict = Depends(require_group_member),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    membres = await group_service.lister_membres(db, ObjectId(group_id))
    return [MembreGroupePublic.model_validate(m) for m in membres]


@router.put("/{group_id}", response_model=dict)
async def modifier_groupe(
    group_id: str,
    payload: ModifierGroupeRequest,
    membership: dict = Depends(require_group_member),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    if membership["role"] not in ("owner", "admin"):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Seuls le propriétaire ou un administrateur peuvent modifier le groupe")
    await group_service.modifier_groupe(db, ObjectId(group_id), payload.model_dump())
    return {"success": True}


@router.delete("/{group_id}/membres/{target_user_id}", response_model=dict)
async def retirer_membre(
    group_id: str,
    target_user_id: str,
    membership: dict = Depends(require_group_member),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    if membership["role"] not in ("owner", "admin"):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Seuls le propriétaire ou un administrateur peuvent retirer un membre")
    await group_service.retirer_membre(db, ObjectId(group_id), ObjectId(target_user_id))
    return {"success": True}
