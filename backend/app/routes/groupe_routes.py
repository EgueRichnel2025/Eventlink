from bson import ObjectId
from fastapi import APIRouter, Body, Depends, HTTPException, status
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
from app.utils.dependencies import (
    get_current_user_id,
    require_group_admin,
    require_group_member,
    require_group_owner,
)

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
    groupe = await group_service.rejoindre_groupe(
        db,
        ObjectId(user_id),
        payload.code_invitation,
    )
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
    groupe = await group_service.obtenir_groupe(
        db,
        ObjectId(group_id),
        ObjectId(user_id),
    )
    return GroupePublic.model_validate(groupe)


@router.get("/{group_id}/membres", response_model=list[MembreGroupePublic])
async def membres_groupe(
    group_id: str,
    q: str | None = None,
    _membership: dict = Depends(require_group_member),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    membres = await group_service.lister_membres(
        db,
        ObjectId(group_id),
        recherche=q,
    )
    return [MembreGroupePublic.model_validate(m) for m in membres]


@router.get("/{group_id}/code-invitation", response_model=dict)
async def obtenir_code_invitation(
    group_id: str,
    _membership: dict = Depends(require_group_admin),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Obtenir le code d'invitation actuel du groupe (propriétaire uniquement)."""
    groupe = await db.groups.find_one({"_id": ObjectId(group_id)})

    if groupe is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Groupe introuvable",
        )

    return {"code_invitation": groupe.get("code_invitation")}


@router.post("/{group_id}/regenerer-code", response_model=dict)
async def regenerer_code_invitation(
    group_id: str,
    _membership: dict = Depends(require_group_admin),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Régénérer le code d'invitation du groupe (propriétaire uniquement)."""
    from app.utils.security import generate_invite_code

    # Garantir un code unique même en cas de collision improbable.
    code = generate_invite_code()

    while await db.groups.find_one({"code_invitation": code}):
        code = generate_invite_code()

    await db.groups.update_one(
        {"_id": ObjectId(group_id)},
        {"$set": {"code_invitation": code}},
    )

    # Retourner le groupe mis à jour.
    groupe = await group_service.obtenir_groupe(
        db,
        ObjectId(group_id),
        ObjectId(_membership["user_id"]),
    )

    return GroupePublic.model_validate(groupe).model_dump()


@router.put("/{group_id}", response_model=dict)
async def modifier_groupe(
    group_id: str,
    payload: ModifierGroupeRequest,
    _membership: dict = Depends(require_group_admin),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    await group_service.modifier_groupe(
        db,
        ObjectId(group_id),
        payload.model_dump(),
    )
    return {"success": True}


@router.delete("/{group_id}/membres/{target_user_id}", response_model=dict)
async def retirer_membre(
    group_id: str,
    target_user_id: str,
    _membership: dict = Depends(require_group_admin),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    await group_service.retirer_membre(
        db,
        ObjectId(group_id),
        ObjectId(target_user_id),
        ObjectId(_membership["user_id"]),
    )
    return {"success": True}


@router.post("/{group_id}/transfer-ownership", response_model=dict)
async def transferer_propriete(
    group_id: str,
    new_owner_id: str = Body(..., embed=True),
    _membership: dict = Depends(require_group_owner),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Transférer la propriété du groupe à un autre membre."""
    await group_service.transferer_propriete(
        db,
        ObjectId(group_id),
        ObjectId(_membership["user_id"]),
        ObjectId(new_owner_id),
    )

    # Retourner le groupe mis à jour.
    groupe = await group_service.obtenir_groupe(
        db,
        ObjectId(group_id),
        ObjectId(_membership["user_id"]),
    )

    return GroupePublic.model_validate(groupe).model_dump()


@router.post("/{group_id}/promote-admin", response_model=dict)
async def promover_admin(
    group_id: str,
    admin_id: str = Body(..., embed=True),
    _membership: dict = Depends(require_group_owner),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Promouvoir un membre en administrateur."""
    await group_service.promover_admin(
        db,
        ObjectId(group_id),
        ObjectId(admin_id),
        ObjectId(_membership["user_id"]),
    )

    return {"success": True}


@router.post("/{group_id}/demote-admin", response_model=dict)
async def retroceder_admin(
    group_id: str,
    admin_id: str = Body(..., embed=True),
    _membership: dict = Depends(require_group_owner),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Rétrograder un administrateur en membre."""
    await group_service.retroceder_admin(
        db,
        ObjectId(group_id),
        ObjectId(admin_id),
        ObjectId(_membership["user_id"]),
    )

    return {"success": True}