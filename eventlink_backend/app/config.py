"""
config.py
Rôle : charger les variables d'environnement (.env) et les rendre
utilisables partout dans le backend.

Responsable suggéré : Dine / Elie / Référil (au choix)
"""

from dotenv import load_dotenv
import os

load_dotenv()

# TODO: récupérer la variable MONGO_URI depuis le .env avec os.getenv("MONGO_URI")
MONGO_URI = None

# TODO: récupérer la variable PORT depuis le .env (valeur par défaut 8000 si absente)
PORT = None

# TODO: récupérer le chemin vers firebase-credentials.json depuis le .env
FIREBASE_CREDENTIALS_PATH = None
