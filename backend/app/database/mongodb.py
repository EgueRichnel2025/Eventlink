"""
Connexion MongoDB (Motor - driver async) et création des index.

Ce module expose un client unique réutilisé dans toute l'application via
`get_database()`, ainsi qu'un accès direct à chaque collection.
"""

import logging

from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

from app.config.settings import settings

logger = logging.getLogger("eventlink.database")


class MongoDB:
    client: AsyncIOMotorClient | None = None
    db: AsyncIOMotorDatabase | None = None


mongodb = MongoDB()


async def connect_to_mongo() -> None:
    """À appeler au démarrage de l'application (startup event)."""
    mongodb.client = AsyncIOMotorClient(settings.MONGODB_URI)
    mongodb.db = mongodb.client[settings.MONGODB_DB_NAME]
    await _ensure_indexes(mongodb.db)
    logger.info("Connecté à MongoDB (%s)", settings.MONGODB_DB_NAME)


async def close_mongo_connection() -> None:
    """À appeler à l'arrêt de l'application (shutdown event)."""
    if mongodb.client is not None:
        mongodb.client.close()
        logger.info("Connexion MongoDB fermée")


def get_database() -> AsyncIOMotorDatabase:
    """Accès direct à la base, utilisé par les services/routes."""
    if mongodb.db is None:
        raise RuntimeError("La base de données n'est pas initialisée. Appelez connect_to_mongo() au démarrage.")
    return mongodb.db


async def _ensure_indexes(db: AsyncIOMotorDatabase) -> None:
    """Crée les index nécessaires à la cohérence et aux performances."""
    await db.groups.create_index("code_invitation", unique=True)
    await db.group_members.create_index([("group_id", 1), ("user_id", 1)], unique=True)
    await db.group_members.create_index("user_id")
    await db.events.create_index("group_id")
    await db.events.create_index([("group_id", 1), ("created_at", -1)])
    await db.event_statuses.create_index([("event_id", 1), ("user_id", 1)], unique=True)
    await db.comments.create_index([("event_id", 1), ("created_at", 1)])
    await db.notifications.create_index([("user_id", 1), ("created_at", -1)])
    await db.refresh_tokens.create_index("token_hash", unique=True)
    await db.refresh_tokens.create_index("expires_at", expireAfterSeconds=0)
