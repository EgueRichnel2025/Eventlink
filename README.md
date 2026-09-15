# EventLink

> **« Les conversations servent à échanger. EventLink sert à ne pas perdre ce qui compte. »**

**EventLink** est une application mobile-first conçue pour centraliser les événements, opportunités, formations, hackathons, bourses et autres informations importantes partagées au sein de groupes.

L'objectif est simple : permettre à un groupe de **partager, retrouver, suivre et organiser facilement les opportunités qui comptent**, sans qu'elles se perdent dans les conversations.

> **Projet  — Développeur  : Richnel EGUE**

EventLink est conçu, développé et maintenu  par **Richnel EGUE**, de la conception de l'application jusqu'au développement frontend, backend, base de données, authentification, architecture et interface utilisateur.

---

## ✨ Fonctionnalités

### 👤 Profils utilisateurs

* Création du profil utilisateur.
* Gestion du prénom et du nom.
* Génération automatique des initiales.
* Sélection d'un avatar parmi une collection d'avatars illustrés.
* Possibilité d'utiliser ses initiales à la place d'un avatar.
* Gestion de la photo de profil via URL.
* Affichage cohérent du profil et de l'avatar dans l'application.

### 👥 Groupes

* Création et rejoindre des groupes.
* Gestion de plusieurs groupes par utilisateur.
* Affichage des membres.
* Gestion des administrateurs.
* Gestion des rôles et permissions.
* Ajout et retrait de membres.
* Paramètres du groupe.
* Possibilité de quitter un groupe.

### 📅 Événements et opportunités

EventLink permet de publier différents types de contenus :

* 🎓 Formation
* 💼 Opportunité
* 🚀 Hackathon
* 🎓 Bourse
* 📅 Événement
* 📚 Ressource
* 📌 Autre

Chaque événement peut contenir notamment :

* un titre ;
* une description ;
* une catégorie ;
* une date ;
* une heure ;
* un lieu ;
* un lien externe ;
* une image ;
* des informations complémentaires.

### 📊 Suivi personnel

Chaque utilisateur peut indiquer son propre statut pour un événement.

Le statut est personnel à chaque utilisateur et peut être modifié indépendamment de celui des autres membres du groupe.

### 💬 Commentaires et réactions

* Commentaires sur les événements.
* Affichage des auteurs et de leurs avatars.
* Réactions sur les commentaires.
* Mise à jour des réactions.
* Gestion des commentaires liés à chaque événement.

### 🔔 Notifications

EventLink possède un système de notifications permettant d'informer l'utilisateur des événements importants liés à son utilisation de l'application.

L'application prévoit également l'intégration de notifications push avec Firebase.

### 🗓️ Calendrier

Une vue calendrier permet de retrouver les événements en fonction de leur date.

### 🔐 Authentification et sécurité

* Authentification basée sur JWT.
* Stockage sécurisé du token côté application.
* Rafraîchissement automatique du token.
* Gestion centralisée des appels API.
* Validation des données côté backend.
* Gestion des erreurs réseau.
* Aucun mot de passe stocké en clair.

---

# 🛠️ Stack technique

## Frontend

* **Flutter**
* **Dart**
* **Material 3**
* **Provider**
* **HTTP**
* **flutter_secure_storage**
* **table_calendar**
* **url_launcher**
* **Firebase Messaging**
* **flutter_local_notifications**

## Backend

* **Python**
* **FastAPI**
* **Pydantic**
* **JWT**
* **bcrypt**
* **MongoDB**
* **Motor**

## Architecture générale

```text
Flutter
   │
   │ REST API
   ▼
FastAPI
   │
   ▼
MongoDB
```

---

# 📁 Architecture du projet

```text
EventLink/
│
├── assets/
│   └── images/
│       └── avatars/
│           ├── avatar_01.jpeg
│           ├── avatar_02.jpeg
│           ├── ...
│           └── avatar_39.jpeg
│
├── backend/
│   ├── app/
│   │   ├── models/
│   │   ├── routers/
│   │   ├── services/
│   │   ├── schemas/
│   │   └── main.py
│   │
│   ├── requirements.txt
│   └── README.md
│
├── lib/
│   ├── config/
│   │   ├── app_config.dart
│   │   ├── api_config.dart
│   │   └── theme.dart
│   │
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── groupe_model.dart
│   │   ├── event_model.dart
│   │   ├── comment_model.dart
│   │   └── notification_model.dart
│   │
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── group_provider.dart
│   │   ├── event_provider.dart
│   │   └── notification_provider.dart
│   │
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── auth_service.dart
│   │   ├── group_service.dart
│   │   ├── event_service.dart
│   │   ├── notification_service.dart
│   │   └── storage_service.dart
│   │
│   ├── screens/
│   │   ├── splash/
│   │   ├── auth/
│   │   ├── groups/
│   │   ├── events/
│   │   ├── profile/
│   │   └── notifications/
│   │
│   ├── widgets/
│   │   ├── event_card.dart
│   │   ├── group_card.dart
│   │   ├── empty_state.dart
│   │   └── error_retry_view.dart
│   │
│   ├── routes/
│   │   ├── app_routes.dart
│   │   └── app_router.dart
│   │
│   └── main.dart
│
├── .gitignore
├── pubspec.yaml
└── README.md
```

---

# 🧭 Parcours principal

```text
Splash
   │
   ├── Première utilisation
   │       │
   │       ▼
   │   ProfilSetup
   │       │
   │       ▼
   │   GroupeChoice
   │
   └── Utilisateur déjà configuré
           │
           ├── Aucun groupe
           │       │
           │       ▼
           │   GroupeChoice
           │
           └── Au moins un groupe
                   │
                   ▼
               GroupesScreen
                   │
                   ├── Groupe
                   │      │
                   │      ▼
                   │   EventListScreen
                   │      │
                   │      ▼
                   │   EventDetailScreen
                   │      │
                   │      ├── Commentaires
                   │      ├── Réactions
                   │      └── Statut personnel
                   │
                   └── Ajouter / rejoindre un groupe
```

La navigation utilise principalement `Navigator.push` et `Navigator.pop`.

Le Splash reste le point de décision initial pour déterminer l'état de l'utilisateur avant de l'orienter vers l'écran approprié.

---

# ⚙️ Installation

## 1. Prérequis

Installer :

* Flutter
* Dart
* Python
* MongoDB
* Git

Vérifier Flutter :

```bash
flutter doctor
```

---

## 2. Cloner le projet

```bash
git clone https://github.com/EgueRichnel2025/Eventlink.git
cd Eventlink
```

---

# 📱 Application Flutter

Installer les dépendances :

```bash
flutter pub get
```

Lancer l'application :

```bash
flutter run
```

Pour utiliser une URL spécifique pour le backend :

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

Pour un émulateur Android, l'adresse du backend local peut notamment utiliser :

```text
http://10.0.2.2:8000
```

Pour un appareil physique connecté au même réseau que le PC, utiliser l'adresse IP locale du PC.

---

# 🖥️ Backend FastAPI

Se rendre dans le dossier backend :

```bash
cd backend
```

Créer l'environnement virtuel :

```bash
python3 -m venv venv
```

Activer l'environnement virtuel.

### Linux / macOS

```bash
source venv/bin/activate
```

### Windows

```bash
venv\Scripts\activate
```

Installer les dépendances :

```bash
pip install -r requirements.txt
```

Configurer les variables d'environnement à partir du fichier prévu à cet effet :

```bash
cp .env.example .env
```

Puis renseigner notamment :

```text
MONGODB_URI
JWT_SECRET_KEY
```

Lancer le serveur :

```bash
uvicorn app.main:app --reload --port 8000
```

Le backend est alors accessible sur :

```text
http://localhost:8000
```

La documentation interactive FastAPI est disponible sur :

```text
http://localhost:8000/docs
```

Pour davantage de détails concernant le backend, consulter :

[`backend/README.md`](./backend/README.md)

---

# 🔥 Firebase

Firebase est prévu pour les notifications push.

Pour activer complètement cette fonctionnalité :

1. Créer un projet Firebase.
2. Ajouter l'application Android, iOS ou Web concernée.
3. Configurer FlutterFire.
4. Générer `firebase_options.dart`.
5. Initialiser Firebase dans l'application.

Sans configuration Firebase complète, l'application peut continuer à fonctionner normalement et les fonctionnalités qui dépendent directement de Firebase sont désactivées ou ignorées de manière contrôlée.

---

# 🧪 Tests

Pour lancer les tests Flutter :

```bash
flutter test
```

Pour analyser le projet :

```bash
flutter analyze
```

---

# 🧱 Principes techniques

### Gestion d'état

La gestion d'état est réalisée avec **Provider**.

Les principaux providers concernent :

* l'authentification ;
* les groupes ;
* les événements ;
* les notifications.

### Communication API

Les communications entre Flutter et FastAPI sont centralisées autour du service API.

Cela permet notamment :

* de centraliser les requêtes HTTP ;
* de gérer les erreurs ;
* de gérer les timeouts ;
* de gérer le rafraîchissement du token ;
* d'éviter de dupliquer la logique réseau dans les écrans.

### Gestion des erreurs

Les erreurs API sont transformées en messages compréhensibles pour l'utilisateur.

Les écrans utilisent notamment un composant de type `ErrorRetryView` lorsqu'une requête échoue.

### États vides

Le composant `EmptyState` est réutilisé lorsque certaines sections ne contiennent aucune donnée.

Il est notamment utilisé pour :

* les groupes ;
* les événements ;
* les commentaires ;
* les notifications ;
* les résultats de recherche.

### Navigation

La navigation est organisée autour des routes de l'application et des écrans Flutter correspondants.

Le Splash conserve un rôle particulier : il détermine l'état initial avant d'effectuer la redirection appropriée.

---

# 👤 Système d'avatars

EventLink possède actuellement une collection de **39 avatars illustrés**.

```text
assets/images/avatars/

avatar_01.jpeg
avatar_02.jpeg
avatar_03.jpeg
...
avatar_39.jpeg
```

Les avatars ont été pensés pour offrir une diversité de profils, de styles, de carnations, de coiffures et d'expressions.

L'utilisateur peut :

* sélectionner un avatar ;
* conserver ses initiales ;
* utiliser une photo via URL lorsque cette fonctionnalité est disponible.

---

# 📌 Statut du projet

**EventLink est actuellement en développement.**

Le projet dispose déjà de plusieurs fonctionnalités fonctionnelles :

* onboarding ;
* profils utilisateurs ;
* avatars ;
* authentification ;
* groupes ;
* administration des groupes ;
* membres ;
* événements ;
* catégories ;
* statuts personnels ;
* commentaires ;
* réactions ;
* notifications ;
* calendrier ;
* backend FastAPI ;
* base de données MongoDB ;
* gestion des erreurs API ;
* stockage sécurisé de session.

Certaines fonctionnalités restent à améliorer avant une version finale destinée à une utilisation à grande échelle.

---

# 🚀 Améliorations futures

Parmi les évolutions envisagées :

* configuration complète de Firebase et FCM ;
* upload réel d'images ;
* stockage cloud des médias ;
* pagination des événements et des membres ;
* recherche plus avancée ;
* système de filtres plus complet ;
* mode hors-ligne ;
* cache local ;
* amélioration des performances ;
* amélioration de l'expérience utilisateur ;
* déploiement du backend ;
* déploiement de l'application mobile.

---

# 👨‍💻 Développement

## Développeur unique

**Richnel EGUE**

EventLink est un **projet individuel**.

L'ensemble du développement du projet est réalisé individuellement, notamment :

* conception du concept ;
* conception de l'architecture ;
* développement Flutter ;
* développement de l'interface utilisateur ;
* développement du backend FastAPI ;
* intégration MongoDB ;
* authentification JWT ;
* gestion des groupes ;
* gestion des événements ;
* gestion des commentaires et réactions ;
* système de notifications ;
* calendrier ;
* gestion des profils ;
* système d'avatars ;
* intégration frontend/backend ;
* gestion des erreurs ;
* configuration du projet ;
* maintenance et évolution de l'application.

---

# 📚 Objectif du projet

EventLink est avant tout un projet visant à résoudre un problème concret :

> **Comment éviter qu'une opportunité importante disparaisse dans une conversation de groupe ?**

L'idée est de transformer les informations dispersées dans les conversations en contenus structurés, accessibles et organisés.

À terme, EventLink a vocation à devenir un espace où les utilisateurs peuvent retrouver rapidement les opportunités importantes de leurs communautés.

---

## 📄 Licence

Ce projet est un projet personnel en cours de développement.

Toute utilisation, modification ou redistribution du code doit respecter les conditions définies ultérieurement par l'auteur.

---

## 👨‍💻 Auteur

**Richnel EGUE**

**EventLink — Projet**
