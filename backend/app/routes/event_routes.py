from pathlib import Path
from uuid import uuid4

from bson import ObjectId
from fastapi import (
    APIRouter,
    Depends,
    File,
    HTTPException,
    Query,
    Request,
    UploadFile,
    status,
)
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.database.mongodb import get_database
from app.schemas.event_schemas import (
    ChangerStatutRequest,
    CommentairePublic,
    CommentaireRequest,
    CreerEventRequest,
    EventPublic,
    ModifierEventRequest,
    ReactionRequest,
)
from app.services import event_service, notification_service
from app.utils.dependencies import get_current_user, get_current_user_id

router = APIRouter(tags=["Événements"])


BASE_DIR = Path(__file__).resolve().parent.parent.parent
EVENT_UPLOADS_DIR = BASE_DIR / "uploads" / "events"
EVENT_UPLOADS_DIR.mkdir(parents=True, exist_ok=True)

ALLOWED_IMAGE_TYPES = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
}

ALLOWED_IMAGE_EXTENSIONS = {
    ".jpg": ".jpg",
    ".jpeg": ".jpg",
    ".png": ".png",
    ".webp": ".webp",
}

MAX_IMAGE_SIZE = 10 * 1024 * 1024


async def _verifier_membre(
    db: AsyncIOMotorDatabase,
    group_id: ObjectId,
    user_id: ObjectId,
) -> dict:
    """Vérifie l'appartenance au groupe pour des identifiants passés en query/déduits d'un event.

    Utilisé partout où le group_id ne provient pas d'un paramètre de chemin nommé
    `group_id` (auquel cas `require_group_member` de dependencies.py suffit).
    """
    membership = await db.group_members.find_one(
        {
            "group_id": group_id,
            "user_id": user_id,
        }
    )

    if membership is None:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Vous n'êtes pas membre de ce groupe",
        )

    return membership


@router.post("/events/upload", response_model=dict)
async def uploader_image_event(
    request: Request,
    file: UploadFile = File(...),
    user: dict = Depends(get_current_user),
):
    """Upload une image destinée à être utilisée par un événement."""

    print(
        f"[UPLOAD] fichier={file.filename!r} "
        f"content_type={file.content_type!r}"
    )

    content_type = file.content_type
    extension = None

    if content_type in ALLOWED_IMAGE_TYPES:
        extension = ALLOWED_IMAGE_TYPES[content_type]
    else:
        nom_fichier = file.filename or ""
        extension_fichier = Path(nom_fichier).suffix.lower()

        if extension_fichier in ALLOWED_IMAGE_EXTENSIONS:
            extension = ALLOWED_IMAGE_EXTENSIONS[extension_fichier]
            print(
                f"[UPLOAD] MIME non standard, "
                f"extension reconnue : {extension_fichier!r}"
            )
        else:
            print(
                f"[UPLOAD] FORMAT REFUSÉ : "
                f"content_type={content_type!r}, "
                f"extension={extension_fichier!r}"
            )
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                "Format d'image non supporté. Utilisez JPG, PNG ou WebP.",
            )

    contenu = await file.read()

    print(
        f"[UPLOAD] taille={len(contenu)} octets "
        f"extension={extension!r}"
    )

    if not contenu:
        print("[UPLOAD] FICHIER VIDE")
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Le fichier image est vide.",
        )

    if len(contenu) > MAX_IMAGE_SIZE:
        raise HTTPException(
            status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            "L'image ne doit pas dépasser 10 Mo.",
        )

    nom_fichier = f"{uuid4().hex}{extension}"
    chemin_fichier = EVENT_UPLOADS_DIR / nom_fichier

    try:
        chemin_fichier.write_bytes(contenu)
    except OSError as exc:
        raise HTTPException(
            status.HTTP_500_INTERNAL_SERVER_ERROR,
            "Impossible d'enregistrer l'image.",
        ) from exc

    base_url = str(request.base_url).rstrip("/")
    image_url = f"{base_url}/uploads/events/{nom_fichier}"

    print(
        f"[UPLOAD] SUCCÈS : {image_url}"
    )

    return {
        "success": True,
        "image_url": image_url,
        "filename": nom_fichier,
    }


@router.post(
    "/events",
    response_model=EventPublic,
    status_code=status.HTTP_201_CREATED,
)
async def creer_event(
    payload: CreerEventRequest,
    groupe_id: str = Query(..., alias="groupe_id"),
    user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    await _verifier_membre(
        db,
        ObjectId(groupe_id),
        user["_id"],
    )

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
        data={
            "event_id": str(event["_id"]),
            "group_id": groupe_id,
        },
    )

    return EventPublic.model_validate(event)


@router.get(
    "/events",
    response_model=list[EventPublic],
)
async def lister_events(
    groupe_id: str = Query(..., alias="groupe_id"),
    categorie: str | None = None,
    statut: str | None = None,
    q: str | None = None,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    await _verifier_membre(
        db,
        ObjectId(groupe_id),
        ObjectId(user_id),
    )

    events = await event_service.lister_events(
        db,
        ObjectId(groupe_id),
        ObjectId(user_id),
        categorie=categorie,
        statut=statut,
        recherche=q,
    )

    return [
        EventPublic.model_validate(e)
        for e in events
    ]


@router.get(
    "/events/{event_id}",
    response_model=EventPublic,
)
async def obtenir_event(
    event_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    event = await event_service.obtenir_event(
        db,
        ObjectId(event_id),
        ObjectId(user_id),
    )

    membership = await db.group_members.find_one(
        {
            "group_id": event["group_id"],
            "user_id": ObjectId(user_id),
        }
    )

    if membership is None:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Vous n'êtes pas membre de ce groupe",
        )

    return EventPublic.model_validate(event)


@router.put(
    "/events/{event_id}",
    response_model=dict,
)
async def modifier_event(
    event_id: str,
    payload: ModifierEventRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    event = await db.events.find_one(
        {"_id": ObjectId(event_id)}
    )

    if event is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Événement introuvable",
        )

    if str(event["auteur_id"]) != user_id:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Seul l'auteur peut modifier cet événement",
        )

    updates = payload.model_dump()

    if updates.get("lien") is not None:
        updates["lien"] = str(updates["lien"])

    if updates.get("categorie") is not None:
        updates["categorie"] = (
            updates["categorie"].value
            if hasattr(updates["categorie"], "value")
            else updates["categorie"]
        )

    await event_service.modifier_event(
        db,
        ObjectId(event_id),
        updates,
    )

    return {"success": True}


@router.delete(
    "/events/{event_id}",
    response_model=dict,
)
async def supprimer_event(
    event_id: str,
    raison: str | None = None,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    event = await db.events.find_one(
        {"_id": ObjectId(event_id)}
    )

    if event is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Événement introuvable",
        )

    membership = await db.group_members.find_one(
        {
            "group_id": event["group_id"],
            "user_id": ObjectId(user_id),
        }
    )

    est_auteur = str(event["auteur_id"]) == user_id

    est_admin = (
        membership is not None
        and membership["role"] in ("owner", "admin")
    )

    # L'auteur peut supprimer son propre événement sans raison.
    if est_auteur:
        await event_service.supprimer_event(
            db,
            ObjectId(event_id),
        )

        return {"success": True}

    # Un administrateur ou le propriétaire peut supprimer
    # l'événement d'un autre membre, mais une raison est obligatoire.
    if not est_admin:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Action non autorisée",
        )

    raison = raison.strip() if raison else ""

    if not raison:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Une raison est obligatoire pour supprimer l'événement d'un autre membre",
        )

    if len(raison) > 500:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "La raison ne peut pas dépasser 500 caractères",
        )

    supprimeur = await db.users.find_one(
        {"_id": ObjectId(user_id)}
    )

    if supprimeur is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Utilisateur introuvable",
        )

    supprimeur_nom = (
        f"{supprimeur.get('prenom', '')} "
        f"{supprimeur.get('nom', '')}"
    ).strip()

    if not supprimeur_nom:
        supprimeur_nom = "Un administrateur"

    role = membership["role"]

    # La notification est enregistrée avant la suppression
    # afin que l'auteur conserve l'information même sans Firebase.
    await notification_service.notifier_suppression_evenement(
        db=db,
        auteur_id=event["auteur_id"],
        event_id=ObjectId(event_id),
        group_id=event["group_id"],
        supprimeur_nom=supprimeur_nom,
        supprimeur_role=role,
        raison=raison,
    )

    await event_service.supprimer_event(
        db,
        ObjectId(event_id),
    )

    return {"success": True}


@router.patch(
    "/events/{event_id}/statut",
    response_model=dict,
)
async def changer_statut(
    event_id: str,
    payload: ChangerStatutRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    event = await db.events.find_one(
        {"_id": ObjectId(event_id)}
    )

    if event is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Événement introuvable",
        )

    membership = await db.group_members.find_one(
        {
            "group_id": event["group_id"],
            "user_id": ObjectId(user_id),
        }
    )

    if membership is None:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Vous n'êtes pas membre de ce groupe",
        )

    await event_service.changer_statut(
        db,
        ObjectId(event_id),
        ObjectId(user_id),
        payload.statut.value,
    )

    return {"success": True}


@router.post(
    "/events/{event_id}/reactions",
    response_model=dict,
)
async def add_reaction(
    event_id: str,
    payload: ReactionRequest,
    user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Ajoute, modifie ou supprime la réaction d'un utilisateur."""

    event_object_id = ObjectId(event_id)
    user_object_id = ObjectId(user["_id"])
    reaction_type = payload.type.strip()

    if not reaction_type:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Le type de réaction ne peut pas être vide",
        )

    event = await event_service.obtenir_event(
        db,
        event_object_id,
        user_object_id,
    )

    if event is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Événement introuvable",
        )

    existing_reaction = await db.event_reactions.find_one(
        {
            "event_id": event_object_id,
            "user_id": user_object_id,
        }
    )

    if existing_reaction is None:
        await db.event_reactions.insert_one(
            {
                "event_id": event_object_id,
                "user_id": user_object_id,
                "reaction_type": reaction_type,
            }
        )

    elif existing_reaction["reaction_type"] == reaction_type:
        await db.event_reactions.delete_one(
            {
                "_id": existing_reaction["_id"],
            }
        )

    else:
        await db.event_reactions.update_one(
            {
                "_id": existing_reaction["_id"],
            },
            {
                "$set": {
                    "reaction_type": reaction_type,
                }
            },
        )

    updated_event = await event_service.obtenir_event(
        db,
        event_object_id,
        user_object_id,
    )

    return EventPublic.model_validate(
        updated_event
    ).model_dump()


@router.post(
    "/events/{event_id}/views",
    response_model=dict,
)
async def increment_views(
    event_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Incrémente le nombre de vues d'un événement."""

    event = await db.events.find_one(
        {"_id": ObjectId(event_id)}
    )

    if event is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Événement introuvable",
        )

    membership = await db.group_members.find_one(
        {
            "group_id": event["group_id"],
            "user_id": ObjectId(user_id),
        }
    )

    if membership is None:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Vous n'êtes pas membre de ce groupe",
        )

    await db.events.update_one(
        {"_id": ObjectId(event_id)},
        {"$inc": {"vues": 1}},
    )

    updated_event = await event_service.obtenir_event(
        db,
        ObjectId(event_id),
        ObjectId(user_id),
    )

    return EventPublic.model_validate(
        updated_event
    ).model_dump()


@router.get(
    "/events/{event_id}/commentaires",
    response_model=list[CommentairePublic],
)
async def lister_commentaires(
    event_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    event = await db.events.find_one(
        {"_id": ObjectId(event_id)}
    )

    if event is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Événement introuvable",
        )

    membership = await db.group_members.find_one(
        {
            "group_id": event["group_id"],
            "user_id": ObjectId(user_id),
        }
    )

    if membership is None:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Vous n'êtes pas membre de ce groupe",
        )

    commentaires = await event_service.lister_commentaires(
        db,
        ObjectId(event_id),
        ObjectId(user_id),
    )

    return [
        CommentairePublic.model_validate(c)
        for c in commentaires
    ]


@router.post(
    "/events/{event_id}/commentaires",
    response_model=CommentairePublic,
    status_code=status.HTTP_201_CREATED,
)
async def ajouter_commentaire(
    event_id: str,
    payload: CommentaireRequest,
    user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    event = await db.events.find_one(
        {"_id": ObjectId(event_id)}
    )

    if event is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Événement introuvable",
        )

    membership = await db.group_members.find_one(
        {
            "group_id": event["group_id"],
            "user_id": user["_id"],
        }
    )

    if membership is None:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Vous n'êtes pas membre de ce groupe",
        )

    commentaire = await event_service.ajouter_commentaire(
        db,
        ObjectId(event_id),
        user["_id"],
        payload.texte,
        payload.parent_comment_id,
    )

    await notification_service.notifier_membres_groupe(
        db,
        group_id=event["group_id"],
        exclure_user_id=user["_id"],
        type_notif="nouveau_commentaire",
        titre="Nouveau commentaire",
        corps=f"{user['prenom']} a commenté un événement.",
        data={
            "event_id": event_id,
            "group_id": str(event["group_id"]),
        },
    )

    return CommentairePublic.model_validate(commentaire)


@router.put(
    "/events/{event_id}/commentaires/{comment_id}",
    response_model=CommentairePublic,
)
async def modifier_commentaire(
    event_id: str,
    comment_id: str,
    payload: CommentaireRequest,
    user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    event = await db.events.find_one(
        {"_id": ObjectId(event_id)}
    )

    if event is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Événement introuvable",
        )

    membership = await db.group_members.find_one(
        {
            "group_id": event["group_id"],
            "user_id": user["_id"],
        }
    )

    if membership is None:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Vous n'êtes pas membre de ce groupe",
        )

    commentaire = await db.comments.find_one(
        {
            "_id": ObjectId(comment_id),
            "event_id": ObjectId(event_id),
        }
    )

    if commentaire is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Commentaire introuvable",
        )

    if commentaire["user_id"] != user["_id"]:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Seul l'auteur peut modifier ce commentaire",
        )

    commentaire = await event_service.modifier_commentaire(
        db,
        ObjectId(event_id),
        ObjectId(comment_id),
        user["_id"],
        payload.texte,
    )

    return CommentairePublic.model_validate(commentaire)


@router.delete(
    "/events/{event_id}/commentaires/{comment_id}",
    response_model=dict,
)
async def supprimer_commentaire(
    event_id: str,
    comment_id: str,
    user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    event = await db.events.find_one(
        {"_id": ObjectId(event_id)}
    )

    if event is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Événement introuvable",
        )

    membership = await db.group_members.find_one(
        {
            "group_id": event["group_id"],
            "user_id": user["_id"],
        }
    )

    if membership is None:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Vous n'êtes pas membre de ce groupe",
        )

    commentaire = await db.comments.find_one(
        {
            "_id": ObjectId(comment_id),
            "event_id": ObjectId(event_id),
        }
    )

    if commentaire is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Commentaire introuvable",
        )

    est_auteur = commentaire["user_id"] == user["_id"]
    est_admin = membership["role"] in ("admin", "owner")

    if not (est_auteur or est_admin):
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Action non autorisée",
        )

    await event_service.supprimer_commentaire(
        db,
        ObjectId(event_id),
        ObjectId(comment_id),
    )

    return {"success": True}


@router.post(
    "/events/{event_id}/commentaires/{comment_id}/epingle",
    response_model=CommentairePublic,
)
async def toggle_comment_epingle(
    event_id: str,
    comment_id: str,
    user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    event = await db.events.find_one(
        {"_id": ObjectId(event_id)}
    )

    if event is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Événement introuvable",
        )

    membership = await db.group_members.find_one(
        {
            "group_id": event["group_id"],
            "user_id": user["_id"],
        }
    )

    if membership is None:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Vous n'êtes pas membre de ce groupe",
        )

    est_admin = membership["role"] in ("admin", "owner")

    if not est_admin:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Seuls les administrateurs ou le propriétaire peuvent épingler un commentaire",
        )

    commentaire = await event_service.toggle_comment_epingle(
        db,
        ObjectId(event_id),
        ObjectId(comment_id),
    )

    return CommentairePublic.model_validate(commentaire)


@router.post(
    "/events/{event_id}/commentaires/{comment_id}/reactions",
    response_model=CommentairePublic,
)
async def toggle_comment_reaction(
    event_id: str,
    comment_id: str,
    payload: ReactionRequest,
    user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    event = await db.events.find_one(
        {"_id": ObjectId(event_id)}
    )

    if event is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Événement introuvable",
        )

    membership = await db.group_members.find_one(
        {
            "group_id": event["group_id"],
            "user_id": user["_id"],
        }
    )

    if membership is None:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Vous n'êtes pas membre de ce groupe",
        )

    commentaire = await event_service.toggle_comment_reaction(
        db,
        ObjectId(event_id),
        ObjectId(comment_id),
        user["_id"],
        payload.type,
    )

    return CommentairePublic.model_validate(commentaire)
