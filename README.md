# EventLink 📌

_Le conteneur d'événements pour ne plus jamais rater un lien perdu dans WhatsApp_

## 🎯 Le problème

On est 5 dans un groupe WhatsApp. On partage des liens d'opportunités (hackathons, bourses, événements, fêtes...) en continu. Résultat : les liens se noient dans la conversation, personne ne les retrouve, et on rate des inscriptions.

## 💡 La solution

Une app où on colle le lien une seule fois. L'app extrait automatiquement le titre, la description, l'image et la date, notifie tout le groupe en push, et garde tout organisé dans une liste avec statut (à voir / inscrit / passé).

---

## 🧱 Stack technique

| Composant              | Techno                                  |
| ---------------------- | --------------------------------------- |
| Frontend               | Flutter / Dart                          |
| Backend                | FastAPI (Python)                        |
| Base de données        | MongoDB                                 |
| Notifications          | Firebase Cloud Messaging (FCM)          |
| Extraction métadonnées | httpx + BeautifulSoup (Open Graph tags) |
| Hébergement backend    | Render                                  |

---

## 🗂️ Structure du projet

Le projet est en **monorepo** : frontend Flutter et backend FastAPI vivent dans le même dossier `eventlink/`, sur le même repo GitHub.

```
eventlink/
├── README.md
├── .gitignore
├── pubspec.yaml                  # config Flutter
│
├── lib/                          # 📱 FRONTEND FLUTTER
│   ├── main.dart
│   ├── config/
│   ├── models/
│   ├── services/
│   ├── providers/
│   ├── screens/
│   └── widgets/
│
├── android/ ios/ web/ ...        # dossiers générés par Flutter (ne pas toucher)
│
└── eventlink_backend/            # ⚙️ BACKEND FASTAPI
    ├── main.py
    ├── requirements.txt
    ├── .env                      # jamais sur GitHub
    ├── .env.example
    ├── firebase-credentials.json # jamais sur GitHub
    └── app/
        ├── config.py
        ├── database.py
        ├── models/
        ├── schemas/
        ├── routes/
        ├── services/
        └── utils/
```

---

## 📖 À quoi sert chaque fichier

### ⚙️ Backend — `eventlink_backend/`

| Fichier                        | Rôle                                                                                     |
| ------------------------------ | ---------------------------------------------------------------------------------------- |
| `main.py`                      | Point d'entrée de l'API. Lance le serveur FastAPI et connecte toutes les routes.         |
| `requirements.txt`             | Liste des librairies Python nécessaires au projet.                                       |
| `.env`                         | Contient les infos sensibles (URI MongoDB, clés). **Ne jamais commit.**                  |
| `.env.example`                 | Modèle du `.env` — montre quelles variables remplir, sans les vraies valeurs.            |
| `firebase-credentials.json`    | Clé secrète pour envoyer les notifications via Firebase. **Ne jamais commit.**           |
| `app/config.py`                | Lit les variables du `.env` et les rend utilisables dans le code.                        |
| `app/database.py`              | Gère la connexion à la base MongoDB.                                                     |
| `app/models/user.py`           | Décrit à quoi ressemble un utilisateur en base (nom, email, token de notif...).          |
| `app/models/groupe.py`         | Décrit un groupe (nom, code d'invitation, liste des membres).                            |
| `app/models/event.py`          | Décrit un event (lien, titre extrait, image, date, statut par membre).                   |
| `app/schemas/user_schema.py`   | Définit ce que l'API accepte/renvoie pour un utilisateur (validation).                   |
| `app/schemas/groupe_schema.py` | Idem pour les groupes.                                                                   |
| `app/schemas/event_schema.py`  | Idem pour les events.                                                                    |
| `app/routes/auth_routes.py`    | Endpoints pour se connecter / rejoindre un groupe via code.                              |
| `app/routes/groupe_routes.py`  | Endpoints pour créer/consulter un groupe.                                                |
| `app/routes/event_routes.py`   | Endpoints pour ajouter un lien, lister les events, changer un statut.                    |
| `app/services/og_scraper.py`   | Le cœur technique : va chercher automatiquement titre/image/description d'un lien collé. |
| `app/services/fcm_service.py`  | Envoie les notifications push à tous les membres du groupe.                              |
| `app/services/auth_service.py` | Logique de vérification (mot de passe, code d'invitation valide...).                     |
| `app/utils/security.py`        | Fonctions utilitaires : hash de mot de passe, génération de code aléatoire.              |

### 📱 Frontend — `lib/`

| Fichier                                   | Rôle                                                                      |
| ----------------------------------------- | ------------------------------------------------------------------------- |
| `main.dart`                               | Point d'entrée de l'application Flutter.                                  |
| `config/theme.dart`                       | Couleurs, polices, style visuel global de l'app.                          |
| `config/constants.dart`                   | Valeurs fixes : URL du backend, clés partagées.                           |
| `models/user_model.dart`                  | Structure d'un utilisateur côté app (miroir du modèle backend).           |
| `models/groupe_model.dart`                | Structure d'un groupe côté app.                                           |
| `models/event_model.dart`                 | Structure d'un event côté app.                                            |
| `services/api_service.dart`               | Centralise tous les appels HTTP vers le backend FastAPI.                  |
| `services/auth_service.dart`              | Gère la connexion et la session utilisateur.                              |
| `services/notification_service.dart`      | Reçoit et affiche les notifications push (FCM), foreground et background. |
| `providers/auth_provider.dart`            | Garde en mémoire l'état de connexion de l'utilisateur dans l'app.         |
| `providers/event_provider.dart`           | Garde en mémoire la liste des events et leurs statuts.                    |
| `screens/splash_screen.dart`              | Écran de chargement affiché au démarrage de l'app.                        |
| `screens/auth/login_screen.dart`          | Écran de connexion.                                                       |
| `screens/auth/join_groupe_screen.dart`    | Écran pour rejoindre un groupe via code d'invitation.                     |
| `screens/events/event_list_screen.dart`   | Écran principal : liste de tous les events du groupe.                     |
| `screens/events/event_detail_screen.dart` | Écran détail d'un event (infos complètes + changement de statut).         |
| `screens/events/add_link_screen.dart`     | Écran où on colle un lien pour créer un nouvel event.                     |
| `widgets/event_card.dart`                 | Composant réutilisable : la carte qui représente un event dans la liste.  |
| `widgets/status_badge.dart`               | Petit badge visuel (à voir / inscrit / passé).                            |
| `widgets/loading_indicator.dart`          | Indicateur de chargement réutilisable.                                    |

---

## 🗂️ Modèle de données (MongoDB)

```json
// users
{
  "_id": "ObjectId",
  "nom": "string",
  "email": "string",
  "fcm_token": "string",
  "groupe_id": "ObjectId"
}

// groupes
{
  "_id": "ObjectId",
  "nom": "string",
  "code_invitation": "string",
  "membres": ["user_id", "..."]
}

// events
{
  "_id": "ObjectId",
  "groupe_id": "ObjectId",
  "lien_original": "string",
  "titre": "string",
  "description": "string",
  "image_url": "string",
  "date_detectee": "datetime | null",
  "ajoute_par": "user_id",
  "date_ajout": "datetime",
  "statut_membres": {
    "user_id_1": "a_voir | inscrit | passe"
  }
}
```

---

## 🚀 Périmètre du MVP (V1)

**Inclus :**

- [ ] Rejoindre un groupe via code d'invitation
- [ ] Coller un lien → extraction auto titre/description/image
- [ ] Notification push à tout le groupe dès qu'un lien est ajouté
- [ ] Liste des events avec statut par membre
- [ ] Fiche détail d'un event

**Exclus (V2+) :**

- Commentaires sur un event
- Vote "je viens" collectif
- Rappels programmés avant la date
- Catégories / filtres avancés

---

## 🛠️ Étapes de développement (ordre à suivre)

1. **Backend — endpoint d'extraction**
   Endpoint `POST /events` qui reçoit un lien, scrape les balises Open Graph (`og:title`, `og:description`, `og:image`), et enregistre en base. Tester avec Postman avant de toucher à Flutter.

2. **Backend — routes CRUD complètes**
   `GET /events`, `GET /events/{id}`, `PATCH /events/{id}/statut`, gestion groupes et membres.

3. **Setup Firebase**
   Créer le projet Firebase, activer FCM, créer un endpoint backend qui envoie une notif à tous les `fcm_token` d'un groupe.

4. **App Flutter — écrans de base**
   Écran rejoindre/créer groupe → écran liste des events → écran détail event.

5. **Intégration `firebase_messaging`**
   Réception des notifs en foreground et background, navigation vers la fiche event au tap.

6. **Champ "coller un lien"**
   Input + appel API + état de chargement pendant l'extraction + gestion d'échec (formulaire manuel de secours).

7. **Statuts membres**
   Badge visuel à voir / inscrit / passé, mise à jour via `PATCH`.

8. **Déploiement**
   Backend sur Render, build APK pour test en conditions réelles avec le groupe.

---

## ⚠️ Points d'attention connus

- Certains sites (Instagram, LinkedIn) bloquent le scraping ou n'ont pas de bonnes balises OG → prévoir un formulaire manuel de fallback.
- Bien gérer le cas où plusieurs membres ajoutent le même lien (déduplication par URL).
- Les `fcm_token` expirent/changent → prévoir un refresh à chaque login.

---

## 👥 Répartition suggérée

À adapter selon vos disponibilités, mais un découpage possible :

- 1-2 personnes sur le backend (FastAPI + Mongo + FCM)
- 2-3 personnes sur le Flutter (UI + intégration API + notifs)
- Tout le monde teste en conditions réelles dans le groupe WhatsApp habituel

---

## 📋 Setup rapide

```bash
git clone https://github.com/EgueRichnel2025/Eventlink.git
cd Eventlink

# Backend
cd eventlink_backend
pip install -r requirements.txt --break-system-packages
uvicorn main:app --reload

# Frontend (dans un autre terminal, à la racine du projet)
flutter pub get
flutter run
```

Variables d'environnement à définir dans `eventlink_backend/.env` : `MONGO_URI`, `FIREBASE_CREDENTIALS`, `PORT`.

---

## 🤝 Comment contribuer

1. Clone le repo
2. Crée une branche pour ta tâche : `git checkout -b nom/fonctionnalite`
3. Commit régulièrement avec des messages clairs
4. Push ta branche et ouvre une Pull Request
5. Fais relire avant de merger sur `main`
