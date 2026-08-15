"""
services/fcm_service.py
Rôle : envoyer les notifications push via Firebase Cloud Messaging (FCM)
à tous les membres d'un groupe quand un nouvel event est ajouté.

Responsable suggéré : Référil

Pré-requis avant de coder :
- avoir créé un projet Firebase
- avoir activé Cloud Messaging
- avoir téléchargé le fichier firebase-credentials.json et l'avoir mis
  dans eventlink_backend/ (déjà présent, à remplir avec les vraies clés)
"""

import firebase_admin
from firebase_admin import credentials, messaging
from app.config import FIREBASE_CREDENTIALS_PATH

# TODO: initialiser l'app Firebase une seule fois avec :
# cred = credentials.Certificate(FIREBASE_CREDENTIALS_PATH)
# firebase_admin.initialize_app(cred)


async def envoyer_notification_groupe(fcm_tokens: list[str], titre: str, corps: str):
    """
    Envoie une notification push à une liste de tokens (donc à plusieurs
    membres d'un groupe en une fois).

    Paramètres :
    - fcm_tokens : liste des tokens FCM des membres à notifier
    - titre : titre affiché dans la notification
    - corps : texte affiché dans la notification

    TODO:
    - construire un message multicast avec messaging.MulticastMessage
    - utiliser messaging.send_multicast(message) pour envoyer
    - gérer le cas où fcm_tokens est vide (ne rien envoyer)
    - logger ou retourner le résultat (combien de notifs envoyées/échouées)
    """
    pass
