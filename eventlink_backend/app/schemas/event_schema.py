"""
schemas/event_schema.py
Rôle : définir ce que l'API accepte/renvoie pour les events et les
commentaires. C'est le fichier le plus important du backend.

Responsable suggéré : Elie
"""

from pydantic import BaseModel
from typing import Optional


class EventCreate(BaseModel):
    """
    Données attendues quand un membre ajoute un nouvel event via
    le bouton "Ajouter" dans l'app.

    TODO: définir les champs attendus
    - lien (str, obligatoire)
    - description (str, obligatoire)
    - image_url (Optional[str], optionnel)
    """
    pass


class EventStatutUpdate(BaseModel):
    """
    Données attendues quand un membre change son statut sur un event
    (a_voir / inscrit / passe).

    TODO: définir le champ attendu (nouveau_statut: str)
    """
    pass


class CommentaireCreate(BaseModel):
    """
    Données attendues quand un membre ajoute un commentaire sur un event.

    TODO: définir le champ attendu (texte: str)
    """
    pass


class EventOut(BaseModel):
    """
    Données renvoyées par l'API pour un event complet (avec ses commentaires).

    TODO: définir tous les champs à renvoyer (miroir du model Event)
    """
    pass
