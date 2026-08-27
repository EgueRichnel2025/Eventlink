"""
Service métier pour les groupes.

Point clé : la relation utilisateur <-> groupe est portée par la collection
`group_members` (many-to-many), jamais par un champ unique sur `users`.
Un utilisateur peut donc appartenir à un nombre illimité de groupes.
"""

from datetime import datetime, timezone

from bson import ObjectId
from fastapi import HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.utils.security import generate_invite_code


async def creer_groupe(db: AsyncIOMotorDatabase, owner_id: ObjectId, nom: str) -> dict:
    now = datetime.now(timezone.utc)

    # Garantit un code unique même en cas de collision improbable.
    code = generate_invite_code()
    while await db.groups.find_one({"code_invitation": code}):
        code = generate_invite_code()

    result = await db.groups.insert_one(
        {
            "nom": nom.strip(),
            "photo_url": None,
            "code_invitation": code,
            "owner_id": owner_id,
            "created_at": now,
        }
    )
    group_id = result.inserted_id

    await db.group_members.insert_one(
        {
            "group_id": group_id,
            "user_id": owner_id,
            "role": "owner",
            "joined_at": now,
        }
    )

    return await _to_public_groupe(db, group_id, owner_id)


async def rejoindre_groupe(db: AsyncIOMotorDatabase, user_id: ObjectId, code_invitation: str) -> dict:
    group = await db.groups.find_one({"code_invitation": code_invitation.strip().upper()})
    if group is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Code d'invitation invalide")

    existing = await db.group_members.find_one({"group_id": group["_id"], "user_id": user_id})
    if existing is None:
        await db.group_members.insert_one(
            {
                "group_id": group["_id"],
                "user_id": user_id,
                "role": "member",
                "joined_at": datetime.now(timezone.utc),
            }
        )

    return await _to_public_groupe(db, group["_id"], user_id)


async def lister_mes_groupes(db: AsyncIOMotorDatabase, user_id: ObjectId) -> list[dict]:
    """Retourne TOUS les groupes dont l'utilisateur est membre (jamais un seul)."""
    memberships = await db.group_members.find({"user_id": user_id}).to_list(length=None)
    groupes = []
    for m in memberships:
        g = await _to_public_groupe(db, m["group_id"], user_id, membership=m)
        if g is not None:
            groupes.append(g)
    groupes.sort(key=lambda g: g["created_at"], reverse=True)
    return groupes


async def obtenir_groupe(db: AsyncIOMotorDatabase, group_id: ObjectId, user_id: ObjectId) -> dict:
    groupe = await _to_public_groupe(db, group_id, user_id)
    if groupe is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Groupe introuvable")
    return groupe


async def lister_membres(db: AsyncIOMotorDatabase, group_id: ObjectId) -> list[dict]:
    memberships = await db.group_members.find({"group_id": group_id}).to_list(length=None)
    membres = []
    for m in memberships:
        user = await db.users.find_one({"_id": m["user_id"]})
        if user is None:
            continue
        membres.append(
            {
                "user_id": user["_id"],
                "prenom": user["prenom"],
                "nom": user["nom"],
                "photo_url": user.get("photo_url"),
                "role": m["role"],
                "joined_at": m["joined_at"],
            }
        )
    return membres


async def modifier_groupe(db: AsyncIOMotorDatabase, group_id: ObjectId, updates: dict) -> None:
    updates = {k: v for k, v in updates.items() if v is not None}
    if updates:
        await db.groups.update_one({"_id": group_id}, {"$set": updates})


async def retirer_membre(db: AsyncIOMotorDatabase, group_id: ObjectId, target_user_id: ObjectId) -> None:
    await db.group_members.delete_one({"group_id": group_id, "user_id": target_user_id})


# ---------------------------------------------------------------------------

async def _to_public_groupe(
    db: AsyncIOMotorDatabase, group_id: ObjectId, user_id: ObjectId, membership: dict | None = None
) -> dict | None:
    group = await db.groups.find_one({"_id": group_id})
    if group is None:
        return None

    if membership is None:
        membership = await db.group_members.find_one({"group_id": group_id, "user_id": user_id})

    nombre_membres = await db.group_members.count_documents({"group_id": group_id})
    nombre_evenements = await db.events.count_documents({"group_id": group_id})

    return {
        **group,
        "nombre_membres": nombre_membres,
        "nombre_evenements": nombre_evenements,
        "mon_role": membership["role"] if membership else None,
    }
