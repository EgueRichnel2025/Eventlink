from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, Query, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.database.mongodb import get_database
from app.schemas.event_schemas import (
    ChangerStatutRequest,
    CommentairePublic,
    CommentaireRequest,
    CreerEventRequest,
    EventPublic,
    ModifierEventRequest,
)
from app.services import event_service, notification_service
from app.utils.dependencies import get_current_user, get_current_user_id

router = APIRouter(tags=["Événements"])


async def _verifier_membre(db: AsyncIOMotorDatabase, group_id: ObjectId, user_id: ObjectId) -> dict:
    """Vérifie l'appartenance au groupe pour des identifiants passés en query/déduits d'un event.

    Utilisé partout où le group_id ne provient pas d'un paramètre de chemin nommé
    `group_id` (auquel cas `require_group_member` de dependencies.py suffit).
    """
    membership = await db.group_members.find_one({"group_id": group_id, "user_id": user_id})
    if membership is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Vous n'êtes pas membre de ce groupe")
    return membership


@router.post("/events", response_model=EventPublic, status_code=status.HTTP_201_CREATED)
async def creer_event(
    payload: CreerEventRequest,
    groupe_id: str = Query(..., alias="groupe_id"),
    user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    await _verifier_membre(db, ObjectId(groupe_id), user["_id"])
    event = await event_service.creer_event(
        db,
        group_id=ObjectId(groupe_id),
        auteur_id=user["_id"],
        lien=str(payload.lien),
        description=payload.description,
        image_url=payload.image_url,
        categorie=payload.categorie.value,
    )

    await notification_service.notifier_membres_groupe(
        db,
        group_id=ObjectId(groupe_id),
        exclure_user_id=user["_id"],
        type_notif="nouvel_evenement",
        titre="Nouvel événement",
        corps=f"{user['prenom']} a ajouté une nouvelle opportunité.",
        data={"event_id": str(event["_id"]), "group_id": groupe_id},
    )

    return EventPublic.model_validate(event)


@router.get("/events", response_model=list[EventPublic])
async def lister_events(
    groupe_id: str = Query(..., alias="groupe_id"),
    categorie: str | None = None,
    statut: str | None = None,
    q: str | None = None,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    await _verifier_membre(db, ObjectId(groupe_id), ObjectId(user_id))
    events = await event_service.lister_events(
        db, ObjectId(groupe_id), ObjectId(user_id), categorie=categorie, statut=statut, recherche=q
    )
    return [EventPublic.model_validate(e) for e in events]


@router.get("/events/{event_id}", response_model=EventPublic)
async def obtenir_event(
    event_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    # require_group_member a besoin du group_id dans le path : on le déduit de l'event.
    event = await event_service.obtenir_event(db, ObjectId(event_id), ObjectId(user_id))
    membership = await db.group_members.find_one(
        {"group_id": event["group_id"], "user_id": ObjectId(user_id)}
    )
    if membership is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Vous n'êtes pas membre de ce groupe")
    return EventPublic.model_validate(event)


@router.put("/events/{event_id}", response_model=dict)
async def modifier_event(
    event_id: str,
    payload: ModifierEventRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    event = await db.events.find_one({"_id": ObjectId(event_id)})
    if event is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Événement introuvable")
    if str(event["auteur_id"]) != user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Seul l'auteur peut modifier cet événement")

    updates = payload.model_dump()
    if updates.get("lien") is not None:
        updates["lien"] = str(updates["lien"])
    if updates.get("categorie") is not None:
        updates["categorie"] = updates["categorie"].value if hasattr(updates["categorie"], "value") else updates["categorie"]

    await event_service.modifier_event(db, ObjectId(event_id), updates)
    return {"success": True}


@router.delete("/events/{event_id}", response_model=dict)
async def supprimer_event(
    event_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    event = await db.events.find_one({"_id": ObjectId(event_id)})
    if event is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Événement introuvable")

    membership = await db.group_members.find_one(
        {"group_id": event["group_id"], "user_id": ObjectId(user_id)}
    )
    est_auteur = str(event["auteur_id"]) == user_id
    est_admin = membership is not None and membership["role"] in ("owner", "admin")
    if not (est_auteur or est_admin):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Action non autorisée")

    await event_service.supprimer_event(db, ObjectId(event_id))
    return {"success": True}


@router.patch("/events/{event_id}/statut", response_model=dict)
async def changer_statut(
    event_id: str,
    payload: ChangerStatutRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    event = await db.events.find_one({"_id": ObjectId(event_id)})
    if event is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Événement introuvable")
    membership = await db.group_members.find_one(
        {"group_id": event["group_id"], "user_id": ObjectId(user_id)}
    )
    if membership is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Vous n'êtes pas membre de ce groupe")

    await event_service.changer_statut(db, ObjectId(event_id), ObjectId(user_id), payload.statut.value)
    return {"success": True}


@router.get("/events/{event_id}/commentaires", response_model=list[CommentairePublic])
async def lister_commentaires(
    event_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    event = await db.events.find_one({"_id": ObjectId(event_id)})
    if event is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Événement introuvable")
    membership = await db.group_members.find_one(
        {"group_id": event["group_id"], "user_id": ObjectId(user_id)}
    )
    if membership is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Vous n'êtes pas membre de ce groupe")

    commentaires = await event_service.lister_commentaires(db, ObjectId(event_id))
    return [CommentairePublic.model_validate(c) for c in commentaires]


@router.post("/events/{event_id}/commentaires", response_model=CommentairePublic, status_code=status.HTTP_201_CREATED)
async def ajouter_commentaire(
    event_id: str,
    payload: CommentaireRequest,
    user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    event = await db.events.find_one({"_id": ObjectId(event_id)})
    if event is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Événement introuvable")
    membership = await db.group_members.find_one(
        {"group_id": event["group_id"], "user_id": user["_id"]}
    )
    if membership is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Vous n'êtes pas membre de ce groupe")

    commentaire = await event_service.ajouter_commentaire(db, ObjectId(event_id), user["_id"], payload.texte)

    await notification_service.notifier_membres_groupe(
        db,
        group_id=event["group_id"],
        exclure_user_id=user["_id"],
        type_notif="nouveau_commentaire",
        titre="Nouveau commentaire",
        corps=f"{user['prenom']} a commenté un événement.",
        data={"event_id": event_id, "group_id": str(event["group_id"])},
    )

    return CommentairePublic.model_validate(commentaire)
