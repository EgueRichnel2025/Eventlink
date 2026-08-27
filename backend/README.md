# EventLink — Backend (FastAPI + MongoDB)

API du backend d'EventLink : centraliser les liens et opportunités partagés au sein de groupes.

## Stack

- **FastAPI** (async) + **Uvicorn**
- **MongoDB** via **Motor** (driver async)
- **JWT** (access + refresh) pour l'authentification
- **bcrypt** pour tout hashage de secret
- **Firebase Cloud Messaging** (optionnel — dégradation silencieuse si non configuré)

## Installation

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # puis renseigner MONGODB_URI, JWT_SECRET_KEY, etc.
```

## Lancement

```bash
uvicorn app.main:app --reload --port 8000
```

Documentation interactive : http://localhost:8000/docs

## Tests

```bash
pip install -r requirements-dev.txt
pytest -v
```

Les tests utilisent `mongomock-motor` : aucune base MongoDB réelle n'est nécessaire pour les lancer.

## Architecture

```
app/
  config/     settings.py         → lecture des variables d'environnement
  database/   mongodb.py          → connexion Motor + création des index
  schemas/    *.py                → schémas Pydantic (requêtes/réponses)
  services/   *.py                → logique métier (indépendante de FastAPI)
  routes/     *.py                → endpoints HTTP
  utils/      security.py         → JWT, bcrypt, codes d'invitation
              dependencies.py     → get_current_user, require_group_member
              objectid.py         → PyObjectId (ObjectId <-> str pour Pydantic)
  main.py     → point d'entrée, montage des routers, CORS, gestion d'erreurs
tests/        → tests d'intégration (parcours complet)
```

## Modèle de données (collections MongoDB)

| Collection | Rôle |
|---|---|
| `users` | prénom, nom, photo, fcm_token |
| `groups` | nom, code_invitation (unique), owner_id |
| `group_members` | relation N↔N utilisateur/groupe + rôle (owner/admin/member) |
| `events` | lien, description, catégorie, auteur, groupe |
| `event_statuses` | statut **personnel** par (event, utilisateur) — jamais sur `events` |
| `comments` | commentaires d'un événement |
| `notifications` | notifications persistées (lues/non lues) + tentative FCM |
| `refresh_tokens` | refresh tokens hashés, expiration automatique (TTL index) |

Point clé : un utilisateur appartient à **plusieurs** groupes (`group_members`), jamais un seul `group_id` sur `users`.

## Sécurité

- Aucun secret en clair dans le code : tout passe par `.env` (voir `.env.example`).
- Mots de passe/refresh tokens hashés avec bcrypt.
- Chaque route liée à un groupe vérifie l'appartenance côté serveur (`group_members`), jamais confiance dans le frontend.
- Seul l'auteur (ou un owner/admin) peut modifier/supprimer un événement.

## Notifications

Si `FIREBASE_CREDENTIALS_PATH` n'est pas défini ou invalide, l'app démarre normalement et les notifications sont
simplement désactivées (loggées en warning) — jamais de crash.

## Routes principales

Voir la documentation interactive `/docs`, ou le détail dans le message de présentation de l'architecture.
