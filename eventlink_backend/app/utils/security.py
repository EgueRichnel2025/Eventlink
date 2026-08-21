"""
utils/security.py
Rôle : fonctions utilitaires de sécurité (hash de mot de passe,
génération de code d'invitation).

Responsable suggéré : Dine
"""

from passlib.hash import bcrypt
import random
import string


def hasher_mot_de_passe(mot_de_passe: str) -> str:
    """
    Hashe un mot de passe en clair avec bcrypt (sel intégré automatiquement).

    Args:
        mot_de_passe: mot de passe en clair.

    Returns:
        Hash à stocker en base (champ mot_de_passe_hash).
    """
    return bcrypt.hash(mot_de_passe)


def verifier_mot_de_passe(mot_de_passe_clair: str, mot_de_passe_hash: str) -> bool:
    """
    Vérifie la correspondance entre un mot de passe en clair et un hash stocké.

    Args:
        mot_de_passe_clair: mot de passe saisi à la connexion.
        mot_de_passe_hash: hash stocké en base pour l'utilisateur.

    Returns:
        True si le mot de passe est valide, False sinon.
    """
    return bcrypt.verify(mot_de_passe_clair, mot_de_passe_hash)


def generer_code_invitation(longueur: int = 6) -> str:
    """
    Génère un code d'invitation aléatoire pour un groupe.

    Alphabet restreint (sans 0/O/1/I) pour éviter les erreurs de saisie
    lors de la saisie manuelle du code par l'utilisateur.

    Args:
        longueur: nombre de caractères du code (défaut : 6).

    Returns:
        Code alphanumérique en majuscules, ex: "K3F9RT".
    """
    caracteres = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    return ''.join(random.choice(caracteres) for _ in range(longueur))