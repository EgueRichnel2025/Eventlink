"""
services/auth_service.py
Rôle : logique métier autour de l'authentification (vérifications),
séparée des routes pour rester réutilisable et testable.

Responsable suggéré : Dine
"""


async def verifier_email_existe(email: str) -> bool:
    """
    Vérifie si un email est déjà utilisé par un compte existant.

    TODO:
    - chercher dans la collection "users" un document avec cet email
    - retourner True si trouvé, False sinon
    """
    pass


async def authentifier_utilisateur(email: str, mot_de_passe: str):
    """
    Vérifie les identifiants d'un utilisateur à la connexion.

    TODO:
    - chercher l'utilisateur par email
    - si non trouvé, retourner None
    - vérifier le mot de passe avec la fonction de app/utils/security.py
    - si le mot de passe est correct, retourner l'utilisateur
    - sinon retourner None
    """
    pass
