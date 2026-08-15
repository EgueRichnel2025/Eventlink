"""
models/groupe.py
Rôle : décrire à quoi ressemble un groupe (l'équipe de 5) dans MongoDB.

Responsable suggéré : Dine
"""

from pydantic import BaseModel
from typing import List


class Groupe(BaseModel):
    """
    Représente un groupe d'utilisateurs qui partagent les mêmes events.

    Champs à définir :
    - nom (str) : nom du groupe (ex: "Les 5")
    - code_invitation (str) : code unique permettant de rejoindre le groupe
    - membres (List[str]) : liste des identifiants des utilisateurs membres

    TODO: compléter les champs ci-dessous avec les bons types
    """
    nom: str = None              # TODO
    code_invitation: str = None  # TODO
    # TODO: ajouter membres: List[str] = []
