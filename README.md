# EventLink 📌
*Le conteneur d'événements pour ne plus jamais rater un lien perdu dans WhatsApp*

## 🎯 Le problème

On est 5 dans un groupe WhatsApp. On partage des liens d'opportunités (hackathons, bourses, événements, fêtes...) en continu. Résultat : les liens se noient dans la conversation, personne ne les retrouve, et on rate des inscriptions.

## 💡 La solution

Une app simple : un bouton **Ajouter**, on colle le lien, on écrit une description, on ajoute une image si on en a une. L'event est visible par tout le groupe, avec une section commentaires pour en discuter directement dessus.

---

## 🧱 Stack technique

| Composant | Techno |
|---|---|
| Frontend | Flutter / Dart |
| Backend | FastAPI (Python) |
| Base de données | MongoDB |
| Notifications | Firebase Cloud Messaging (FCM) |
| Stockage image | à définir (Firebase Storage ou Cloudinary) |
| Hébergement backend | Render |

---

## 🔄 Fonctionnement (V1 simplifiée)

1. Un membre appuie sur **Ajouter**
2. Il remplit : lien (obligatoire), description (obligatoire), image (optionnelle)
3. L'event est créé et visible par tout le groupe
4. Tout le monde reçoit une notification push
5. Chacun peut changer son statut (à voir / inscrit / passé) sur l'event
6. Une section **commentaires** sous chaque event permet d'en discuter

Pas d'extraction automatique des infos du lien pour l'instant — c'est le membre qui remplit lui-même. Plus simple à développer et à comprendre pour tout le monde. L'extraction auto (Open Graph) reste possible plus tard (V2), pas bloquante pour commencer.

---

## 📖 À quoi sert chaque fichier

### ⚙️ Backend — `eventlink_backend/`

| Fichier | Rôle |
|---|---|
| `main.py` | Point d'entrée de l'API. Lance le serveur FastAPI et connecte toutes les routes. |
| `requirements.txt` | Liste des librairies Python nécessaires. |
| `.env` | Infos sensibles (URI MongoDB, clés). **Ne jamais commit.** |
| `.env.example` | Modèle du `.env` sans les vraies valeurs. |
| `firebase-credentials.json` | Clé secrète pour les notifications Firebase. **Ne jamais commit.** |
| `app/config.py` | Lit les variables du `.env`. |
| `app/database.py` | Connexion à MongoDB. |
| `app/models/user.py` | Structure d'un utilisateur en base. |
| `app/models/groupe.py` | Structure d'un groupe (nom, code d'invitation, membres). |
| `app/models/event.py` | Structure d'un event : lien, description, image, statuts, **commentaires**. |
| `app/schemas/user_schema.py` | Validation des données utilisateur pour l'API. |
| `app/schemas/groupe_schema.py` | Validation des données groupe. |
| `app/schemas/event_schema.py` | Validation des events **et des commentaires**. |
| `app/routes/auth_routes.py` | Connexion / rejoindre un groupe via code. |
| `app/routes/groupe_routes.py` | Créer/consulter un groupe. |
| `app/routes/event_routes.py` | Créer un event, lister, changer statut, **ajouter un commentaire**. |
| `app/services/og_scraper.py` | *(optionnel, V2)* extraction auto — pas utilisé en V1. |
| `app/services/fcm_service.py` | Envoie les notifications push. |
| `app/services/auth_service.py` | Vérification connexion / code d'invitation. |
| `app/utils/security.py` | Hash mot de passe, génération de code. |

### 📱 Frontend — `lib/`

| Fichier | Rôle |
|---|---|
| `main.dart` | Point d'entrée de l'app Flutter. |
| `config/theme.dart` | Couleurs, style visuel global. |
| `config/constants.dart` | URL backend, clés fixes. |
| `models/user_model.dart` | Structure utilisateur côté app. |
| `models/groupe_model.dart` | Structure groupe côté app. |
| `models/event_model.dart` | Structure event côté app, **avec ses commentaires**. |
| `services/api_service.dart` | Tous les appels HTTP vers le backend. |
| `services/auth_service.dart` | Connexion / session utilisateur. |
| `services/notification_service.dart` | Réception des notifs push (foreground/background). |
| `providers/auth_provider.dart` | État de connexion de l'utilisateur. |
| `providers/event_provider.dart` | Liste des events et leurs statuts en mémoire. |
| `screens/splash_screen.dart` | Écran de chargement au démarrage. |
| `screens/auth/login_screen.dart` | Écran de connexion. |
| `screens/auth/join_groupe_screen.dart` | Rejoindre un groupe via code. |
| `screens/events/event_list_screen.dart` | Liste des events + bouton **Ajouter**. |
| `screens/events/event_detail_screen.dart` | Détail event + statut + **section commentaires**. |
| `screens/events/add_link_screen.dart` | Formulaire : lien, description, image. |
| `widgets/event_card.dart` | Carte d'un event dans la liste. |
| `widgets/status_badge.dart` | Badge à voir / inscrit / passé. |
| `widgets/loading_indicator.dart` | Indicateur de chargement. |

---

## 🗂️ Modèle de données (MongoDB)

```json
// events
{
  "_id": "ObjectId",
  "groupe_id": "ObjectId",
  "lien": "string",
  "description": "string",
  "image_url": "string | null",
  "ajoute_par": "user_id",
  "date_ajout": "datetime",
  "statut_membres": { "user_id_1": "a_voir | inscrit | passe" },
  "commentaires": [
    { "user_id": "string", "texte": "string", "date": "datetime" }
  ]
}
```

---

## 🚀 Périmètre du MVP (V1)

**Inclus :**
- [ ] Rejoindre un groupe via code d'invitation
- [ ] Bouton "Ajouter" → lien + description + image (optionnelle)
- [ ] Notification push à tout le groupe
- [ ] Liste des events avec statut par membre
- [ ] Section commentaires sur chaque event

**Exclus (V2+) :**
- Extraction automatique des infos d'un lien
- Rappels programmés
- Catégories / filtres avancés

---

## 🛠️ Étapes de développement

1. Backend — CRUD events (lien, description, image)
2. Backend — commentaires (ajouter/lister)
3. Setup Firebase + notifications push
4. Écrans Flutter de base (groupe → liste → détail)
5. Formulaire d'ajout (lien/description/image)
6. Section commentaires dans l'écran détail
7. Intégration `firebase_messaging`
8. Statuts membres
9. Déploiement Render + build APK

---

## 👥 Répartition suggérée

- Backend (FastAPI + Mongo + FCM) : 2 personnes
- Frontend Flutter : 2-3 personnes
- Tests en conditions réelles sur le groupe WhatsApp

---

## 📋 Setup rapide

\`\`\`bash
git clone https://github.com/EgueRichnel2025/Eventlink.git
cd Eventlink

# Backend
cd eventlink_backend
pip install -r requirements.txt --break-system-packages
uvicorn main:app --reload

# Frontend
flutter pub get
flutter run
\`\`\`