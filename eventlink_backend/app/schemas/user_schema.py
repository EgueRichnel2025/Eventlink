"""
schemas/user_schema.py
Rôle : définir ce que l'API accepte en entrée et renvoie en sortie
pour tout ce qui concerne les utilisateurs. Différent de models/user.py
qui décrit la base de données — ici c'est la validation des requêtes API.

Responsable suggéré : Dine
"""

from pydantic import BaseModel
from typing import Optional


class UserCreate(BaseModel):
    """
    Données attendues quand un utilisateur s'inscrit.

    Attributes:
        nom: nom affiché de l'utilisateur.
        email: email de connexion.
        mot_de_passe: mot de passe en clair, hashé par
            utils/security.hasher_mot_de_passe avant stockage.
    """
    nom: str
    email: str
    mot_de_passe: str


class UserLogin(BaseModel):
    """
    Données attendues quand un utilisateur se connecte.

    Attributes:
        email: email de connexion.
        mot_de_passe: mot de passe en clair, vérifié via
            utils/security.verifier_mot_de_passe.
    """
    email: str
    mot_de_passe: str


class UserOut(BaseModel):
    """
    Données renvoyées par l'API pour un utilisateur (jamais le mot de passe !).

    Attributes:
        id: identifiant MongoDB de l'utilisateur, requis côté app pour
            les requêtes ultérieures (ex: récupérer ses events).
        nom: nom affiché de l'utilisateur.
        email: email de connexion.
        groupe_id: groupe rejoint par l'utilisateur, évite une requête
            supplémentaire côté app pour l'obtenir. Absent tant que
            l'utilisateur n'a rejoint aucun groupe.
    """
    id: str
    nom: str
    email: str
    groupe_id: Optional[str] = None