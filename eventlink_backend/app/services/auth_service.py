"""
services/auth_service.py
Rôle : logique métier autour de l'authentification (vérifications),
séparée des routes pour rester réutilisable et testable.

Responsable suggéré : Dine
"""

from app.database import get_collection
from app.utils.security import verifier_mot_de_passe


async def verifier_email_existe(email: str) -> bool:
    """
    Vérifie si un email est déjà utilisé par un compte existant.

    Args:
        email: email à vérifier.

    Returns:
        True si un utilisateur avec cet email existe déjà, False sinon.
    """
    users = get_collection("users")
    utilisateur = await users.find_one({"email": email})
    return utilisateur is not None


async def authentifier_utilisateur(email: str, mot_de_passe: str):
    """
    Vérifie les identifiants d'un utilisateur à la connexion.

    Args:
        email: email fourni à la connexion.
        mot_de_passe: mot de passe en clair fourni à la connexion.

    Returns:
        Le document utilisateur (dict) si les identifiants sont
        valides, None sinon (email inconnu ou mot de passe incorrect).
    """
    users = get_collection("users")
    utilisateur = await users.find_one({"email": email})
    if utilisateur is None:
        return None

    if not verifier_mot_de_passe(mot_de_passe, utilisateur["mot_de_passe_hash"]):
        return None

    return utilisateur