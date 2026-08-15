"""
schemas/user_schema.py
Rôle : définir ce que l'API accepte en entrée et renvoie en sortie
pour tout ce qui concerne les utilisateurs. Différent de models/user.py
qui décrit la base de données — ici c'est la validation des requêtes API.

Responsable suggéré : Dine
"""

from pydantic import BaseModel


class UserCreate(BaseModel):
    """
    Données attendues quand un utilisateur s'inscrit.

    TODO: définir les champs attendus (nom, email, mot_de_passe)
    """
    pass


class UserLogin(BaseModel):
    """
    Données attendues quand un utilisateur se connecte.

    TODO: définir les champs attendus (email, mot_de_passe)
    """
    pass


class UserOut(BaseModel):
    """
    Données renvoyées par l'API pour un utilisateur (jamais le mot de passe !).

    TODO: définir les champs à renvoyer (id, nom, email)
    """
    pass
