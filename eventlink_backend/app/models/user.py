"""
models/user.py
Rôle : décrire à quoi ressemble un utilisateur dans la base MongoDB.

Responsable suggéré : Dine
"""

from pydantic import BaseModel
from typing import Optional


class User(BaseModel):
    """
    Représente un utilisateur enregistré dans l'app.

    Attributes:
        nom: nom affiché de l'utilisateur.
        email: email de connexion.
        mot_de_passe_hash: mot de passe hashé (voir utils/security.py),
            jamais stocké en clair.
        fcm_token: token Firebase Cloud Messaging pour les notifications
            push, absent tant que l'app ne l'a pas encore transmis.
        groupe_id: identifiant du groupe rejoint, absent avant qu'un
            utilisateur ne rejoigne un groupe via code d'invitation.
    """
    nom: str
    email: str
    mot_de_passe_hash: str
    fcm_token: Optional[str] = None
    groupe_id: Optional[str] = None