"""
Service de notifications push (Firebase Cloud Messaging).

Règle impérative du cahier des charges : si Firebase n'est pas configuré
(pas de fichier de credentials, clé absente, etc.), l'application ne doit
JAMAIS planter. Les notifications sont alors simplement désactivées et
tout est loggé, mais l'API continue de fonctionner normalement.
"""

import logging
from datetime import datetime, timezone

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.config.settings import settings

logger = logging.getLogger("eventlink.notifications")

_firebase_app = None
_firebase_available = False


def init_firebase() -> None:
    """À appeler au démarrage. N'échoue jamais : logge et continue en mode dégradé."""
    global _firebase_app, _firebase_available

    if not settings.FIREBASE_CREDENTIALS_PATH:
        logger.warning("FIREBASE_CREDENTIALS_PATH non défini — notifications FCM désactivées.")
        return

    try:
        import firebase_admin
        from firebase_admin import credentials

        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        _firebase_app = firebase_admin.initialize_app(cred)
        _firebase_available = True
        logger.info("Firebase initialisé — notifications FCM activées.")
    except Exception as exc:  # noqa: BLE001 - on ne veut jamais crasher au démarrage
        logger.warning("Impossible d'initialiser Firebase (%s) — notifications désactivées.", exc)
        _firebase_available = False


async def enregistrer_token(db: AsyncIOMotorDatabase, user_id: ObjectId, fcm_token: str) -> None:
    await db.users.update_one({"_id": user_id}, {"$set": {"fcm_token": fcm_token}})


async def notifier_membres_groupe(
    db: AsyncIOMotorDatabase,
    group_id: ObjectId,
    exclure_user_id: ObjectId,
    type_notif: str,
    titre: str,
    corps: str,
    data: dict | None = None,
) -> None:
    """Notifie tous les membres d'un groupe sauf l'auteur de l'action.

    Persiste toujours la notification en base (pour l'écran Notifications
    in-app), et tente en plus l'envoi FCM si disponible.
    """
    memberships = await db.group_members.find({"group_id": group_id}).to_list(length=None)
    now = datetime.now(timezone.utc)

    for m in memberships:
        if m["user_id"] == exclure_user_id:
            continue

        await db.notifications.insert_one(
            {
                "user_id": m["user_id"],
                "type": type_notif,
                "titre": titre,
                "corps": corps,
                "data": data or {},
                "lu": False,
                "created_at": now,
            }
        )

        if _firebase_available:
            await _envoyer_push(db, m["user_id"], titre, corps, data or {})


async def _envoyer_push(db: AsyncIOMotorDatabase, user_id: ObjectId, titre: str, corps: str, data: dict) -> None:
    user = await db.users.find_one({"_id": user_id})
    token = user.get("fcm_token") if user else None
    if not token:
        return

    try:
        from firebase_admin import messaging

        message = messaging.Message(
            notification=messaging.Notification(title=titre, body=corps),
            data={k: str(v) for k, v in data.items()},
            token=token,
        )
        messaging.send(message)
    except Exception as exc:  # noqa: BLE001 - un échec d'envoi ne doit jamais casser la requête
        logger.warning("Échec d'envoi FCM pour %s: %s", user_id, exc)

async def notifier_mentions_commentaire(
    db: AsyncIOMotorDatabase,
    group_id: ObjectId,
    auteur_id: ObjectId,
    event_id: ObjectId,
    comment_id: ObjectId,
    mentions: list[dict] | None = None,
) -> None:
    """Notifie les utilisateurs mentionnés dans un commentaire.

    - Une mention individuelle cible uniquement l'utilisateur mentionné.
    - @all cible tous les membres du groupe.
    - L'auteur du commentaire est toujours exclu.
    - Les utilisateurs sont dédupliqués.
    - La notification est persistée en base et envoyée via FCM si disponible.
    """
    mentions = mentions or []

    utilisateurs_a_notifier: set[ObjectId] = set()
    mention_all = False

    for mention in mentions:
        mention_type = mention.get("mention_type", "user")

        if mention_type == "all":
            mention_all = True
            continue

        user_id = mention.get("user_id")
        if user_id is not None:
            utilisateurs_a_notifier.add(user_id)

    if mention_all:
        memberships = await db.group_members.find(
            {"group_id": group_id}
        ).to_list(length=None)

        utilisateurs_a_notifier.update(
            membre["user_id"]
            for membre in memberships
        )

    utilisateurs_a_notifier.discard(auteur_id)

    if not utilisateurs_a_notifier:
        return

    now = datetime.now(timezone.utc)

    for user_id in utilisateurs_a_notifier:
        if mention_all:
            titre = "Vous avez été mentionné"
            corps = "Vous avez été mentionné dans une conversation de groupe."
        else:
            titre = "Vous avez été mentionné"
            corps = "Vous avez été mentionné dans un commentaire."

        data = {
            "event_id": str(event_id),
            "group_id": str(group_id),
            "comment_id": str(comment_id),
            "mention_type": "all" if mention_all else "user",
        }

        await db.notifications.insert_one(
            {
                "user_id": user_id,
                "type": "mention_commentaire",
                "titre": titre,
                "corps": corps,
                "data": data,
                "lu": False,
                "created_at": now,
            }
        )

        if _firebase_available:
            await _envoyer_push(
                db,
                user_id,
                titre,
                corps,
                data,
            )


async def notifier_suppression_evenement(
    db: AsyncIOMotorDatabase,
    auteur_id: ObjectId,
    event_id: ObjectId,
    group_id: ObjectId,
    supprimeur_nom: str,
    supprimeur_role: str,
    raison: str,
) -> None:
    role_label = (
        "propriétaire du groupe"
        if supprimeur_role == "owner"
        else "administrateur du groupe"
    )

    titre = "Votre événement a été supprimé"
    corps = (
        f"{supprimeur_nom}, {role_label}, "
        f"a supprimé votre événement. "
        f"Raison : {raison}"
    )

    data = {
        "event_id": str(event_id),
        "group_id": str(group_id),
        "deleted_by_name": supprimeur_nom,
        "deleted_by_role": supprimeur_role,
        "reason": raison,
    }

    await db.notifications.insert_one(
        {
            "user_id": auteur_id,
            "type": "event_deleted",
            "titre": titre,
            "corps": corps,
            "data": data,
            "lu": False,
            "created_at": datetime.now(timezone.utc),
        }
    )

    if _firebase_available:
        await _envoyer_push(
            db,
            auteur_id,
            titre,
            corps,
            data,
        )
