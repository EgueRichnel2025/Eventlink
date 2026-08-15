"""
utils/security.py
Rôle : fonctions utilitaires de sécurité (hash de mot de passe,
génération de code d'invitation).

Responsable suggéré : Dine
"""

import random
import string


def hasher_mot_de_passe(mot_de_passe: str) -> str:
    """
    Transforme un mot de passe en clair en une version hashée sécurisée
    à stocker en base (jamais stocker un mot de passe en clair).

    TODO:
    - utiliser une librairie de hash sécurisée (ex: passlib avec bcrypt)
    - retourner le hash
    """
    pass


def verifier_mot_de_passe(mot_de_passe_clair: str, mot_de_passe_hash: str) -> bool:
    """
    Vérifie qu'un mot de passe en clair correspond bien au hash stocké.

    TODO:
    - utiliser la même librairie que hasher_mot_de_passe pour comparer
    - retourner True si ça correspond, False sinon
    """
    pass


def generer_code_invitation(longueur: int = 6) -> str:
    """
    Génère un code d'invitation aléatoire pour un groupe (ex: "A3F9K1").

    TODO:
    - générer une chaîne aléatoire de `longueur` caractères
      (lettres majuscules + chiffres, voir string.ascii_uppercase + string.digits)
    - retourner le code généré
    """
    pass
