"""
schemas/groupe_schema.py
Rôle : définir ce que l'API accepte/renvoie pour la gestion des groupes.

Responsable suggéré : Dine
"""

from pydantic import BaseModel


class GroupeCreate(BaseModel):
    """
    Données attendues pour créer un nouveau groupe.

    TODO: définir les champs attendus (nom du groupe)
    """
    pass


class GroupeJoin(BaseModel):
    """
    Données attendues pour rejoindre un groupe existant.

    TODO: définir les champs attendus (code_invitation)
    """
    pass


class GroupeOut(BaseModel):
    """
    Données renvoyées par l'API pour un groupe.

    TODO: définir les champs à renvoyer (id, nom, nombre de membres)
    """
    pass
