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

    Champs à définir :
    - nom (str) : nom affiché de l'utilisateur
    - email (str) : email de connexion
    - mot_de_passe_hash (str) : mot de passe stocké de façon sécurisée (jamais en clair)
    - fcm_token (Optional[str]) : token pour recevoir les notifications push
    - groupe_id (Optional[str]) : identifiant du groupe auquel il appartient

    TODO: compléter les champs ci-dessous avec les bons types
    """
    nom: str = None       # TODO
    email: str = None     # TODO
    # TODO: ajouter mot_de_passe_hash, fcm_token, groupe_id
