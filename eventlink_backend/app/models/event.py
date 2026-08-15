"""
models/event.py
Rôle : décrire à quoi ressemble un event (le cœur de l'app) dans MongoDB.
Un event = un lien partagé, avec description, image, statuts et commentaires.

Responsable suggéré : Elie
"""

from pydantic import BaseModel
from typing import Optional, List, Dict
from datetime import datetime


class Commentaire(BaseModel):
    """
    Représente un commentaire laissé sur un event.

    Champs à définir :
    - user_id (str) : qui a écrit le commentaire
    - texte (str) : contenu du commentaire
    - date (datetime) : date d'écriture

    TODO: compléter les champs ci-dessous
    """
    user_id: str = None  # TODO
    texte: str = None    # TODO
    # TODO: ajouter date: datetime


class Event(BaseModel):
    """
    Représente un event ajouté par un membre du groupe.

    Champs à définir :
    - groupe_id (str) : à quel groupe appartient cet event
    - lien (str) : le lien partagé (obligatoire)
    - description (str) : description écrite par le membre (obligatoire)
    - image_url (Optional[str]) : lien vers l'image, si fournie
    - ajoute_par (str) : identifiant du membre qui a créé l'event
    - date_ajout (datetime) : date de création
    - statut_membres (Dict[str, str]) : pour chaque user_id, son statut
      ("a_voir" | "inscrit" | "passe")
    - commentaires (List[Commentaire]) : liste des commentaires sur l'event

    TODO: compléter les champs ci-dessous avec les bons types
    """
    groupe_id: str = None    # TODO
    lien: str = None         # TODO
    description: str = None  # TODO
    # TODO: ajouter image_url, ajoute_par, date_ajout, statut_membres, commentaires
