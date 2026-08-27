"""
Service métier pour les événements.

Le statut ("à voir" / "inscrit" / "passé") est strictement personnel : il
vit dans `event_statuses`, une collection séparée indexée sur
(event_id, user_id), jamais sur le document event lui-même.
"""

from datetime import datetime, timezone

from bson import ObjectId
from fastapi import HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase


async def creer_event(
    db: AsyncIOMotorDatabase,
    group_id: ObjectId,
    auteur_id: ObjectId,
    lien: str,
    description: str,
    image_url: str | None,
    categorie: str,
) -> dict:
    now = datetime.now(timezone.utc)
    result = await db.events.insert_one(
        {
            "group_id": group_id,
            "auteur_id": auteur_id,
            "lien": lien,
            "description": description.strip(),
            "image_url": image_url,
            "categorie": categorie,
            "created_at": now,
        }
    )
    return await _to_public_event(db, result.inserted_id, auteur_id)


async def lister_events(
    db: AsyncIOMotorDatabase,
    group_id: ObjectId,
    user_id: ObjectId,
    categorie: str | None = None,
    statut: str | None = None,
    recherche: str | None = None,
) -> list[dict]:
    query: dict = {"group_id": group_id}
    if categorie:
        query["categorie"] = categorie
    if recherche:
        query["$or"] = [
            {"description": {"$regex": recherche, "$options": "i"}},
            {"lien": {"$regex": recherche, "$options": "i"}},
        ]

    events = await db.events.find(query).sort("created_at", -1).to_list(length=500)

    resultats = []
    for e in events:
        public = await _to_public_event(db, e["_id"], user_id, event_doc=e)
        if statut and public.get("mon_statut") != statut:
            continue
        resultats.append(public)
    return resultats


async def obtenir_event(db: AsyncIOMotorDatabase, event_id: ObjectId, user_id: ObjectId) -> dict:
    event = await _to_public_event(db, event_id, user_id)
    if event is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Événement introuvable")
    return event


async def modifier_event(db: AsyncIOMotorDatabase, event_id: ObjectId, updates: dict) -> None:
    updates = {k: v for k, v in updates.items() if v is not None}
    if updates:
        await db.events.update_one({"_id": event_id}, {"$set": updates})


async def supprimer_event(db: AsyncIOMotorDatabase, event_id: ObjectId) -> None:
    await db.events.delete_one({"_id": event_id})
    await db.comments.delete_many({"event_id": event_id})
    await db.event_statuses.delete_many({"event_id": event_id})


async def changer_statut(db: AsyncIOMotorDatabase, event_id: ObjectId, user_id: ObjectId, statut: str) -> None:
    await db.event_statuses.update_one(
        {"event_id": event_id, "user_id": user_id},
        {"$set": {"statut": statut, "updated_at": datetime.now(timezone.utc)}},
        upsert=True,
    )


async def ajouter_commentaire(
    db: AsyncIOMotorDatabase, event_id: ObjectId, user_id: ObjectId, texte: str
) -> dict:
    user = await db.users.find_one({"_id": user_id})
    now = datetime.now(timezone.utc)
    result = await db.comments.insert_one(
        {
            "event_id": event_id,
            "user_id": user_id,
            "prenom": user["prenom"],
            "nom": user["nom"],
            "photo_url": user.get("photo_url"),
            "texte": texte.strip(),
            "created_at": now,
        }
    )
    return await db.comments.find_one({"_id": result.inserted_id})


async def lister_commentaires(db: AsyncIOMotorDatabase, event_id: ObjectId) -> list[dict]:
    return await db.comments.find({"event_id": event_id}).sort("created_at", 1).to_list(length=None)


# ---------------------------------------------------------------------------

async def _to_public_event(
    db: AsyncIOMotorDatabase, event_id: ObjectId, user_id: ObjectId, event_doc: dict | None = None
) -> dict | None:
    event = event_doc or await db.events.find_one({"_id": event_id})
    if event is None:
        return None

    auteur = await db.users.find_one({"_id": event["auteur_id"]})
    statut_doc = await db.event_statuses.find_one({"event_id": event["_id"], "user_id": user_id})
    nombre_commentaires = await db.comments.count_documents({"event_id": event["_id"]})

    return {
        **event,
        "auteur": {
            "user_id": auteur["_id"],
            "prenom": auteur["prenom"],
            "nom": auteur["nom"],
            "photo_url": auteur.get("photo_url"),
        }
        if auteur
        else {"user_id": event["auteur_id"], "prenom": "?", "nom": "", "photo_url": None},
        "mon_statut": statut_doc["statut"] if statut_doc else None,
        "nombre_commentaires": nombre_commentaires,
    }
