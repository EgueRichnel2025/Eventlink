"""
database.py
Rôle : établir et exposer la connexion à la base MongoDB, pour que
les autres fichiers (routes, services) puissent l'utiliser.

Responsable suggéré : Dine
"""

from motor.motor_asyncio import AsyncIOMotorClient
from app.config import MONGO_URI


# TODO: créer le client MongoDB avec AsyncIOMotorClient(MONGO_URI)
client = None

# TODO: sélectionner la base de données (ex: client["eventlink"])
database = None


def get_collection(nom_collection: str):
    """
    Retourne une collection MongoDB par son nom (ex: "users", "events").

    TODO:
    - vérifier que `database` est bien initialisée
    - retourner database[nom_collection]
    """
    pass
