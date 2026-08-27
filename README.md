# EventLink

"Les conversations servent à échanger. EventLink sert à ne pas perdre ce qui compte."

Ce dépôt regroupe l'application **Flutter** (ce dossier) et le **backend FastAPI + MongoDB** dans [`backend/`](./backend).

## Démarrage rapide

**Backend :**
```bash
cd backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # renseigner MONGODB_URI, JWT_SECRET_KEY...
uvicorn app.main:app --reload --port 8000
```

**Application Flutter (à la racine) :**
```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

Détails complets du backend : [`backend/README.md`](./backend/README.md).

---

## Application Flutter

Application mobile-first (Android / iOS / Web / Windows) pour centraliser les opportunités partagées en groupe.

## Stack

- **Flutter** / **Dart**, null-safety
- **Provider** pour la gestion d'état
- **http** pour les appels REST vers le [backend FastAPI](./backend)
- **flutter_secure_storage** pour la session (jamais de token en clair)
- **firebase_messaging** + **flutter_local_notifications** (dégradation silencieuse si Firebase absent)
- **table_calendar** pour la vue calendrier
- **url_launcher** pour ouvrir les liens d'événements

## Installation

```bash
flutter pub get
```

Renseigner l'URL du backend au lancement (par défaut `http://10.0.2.2:8000`, adapté à l'émulateur Android) :

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

### Firebase (optionnel)

Pour activer réellement les notifications push :

1. Créer un projet Firebase et y ajouter l'application (Android/iOS/Web).
2. Générer `firebase_options.dart` avec la CLI FlutterFire (`flutterfire configure`).
3. Importer ce fichier dans `main.dart` et l'utiliser dans `Firebase.initializeApp(options: ...)`.

**Sans cette configuration, l'application démarre et fonctionne normalement** — seules les notifications push sont désactivées (`NotificationService.firebaseDisponible == false`).

## Tests

```bash
flutter test
```

## Architecture

```
lib/
  config/      theme.dart (identité orange/blanc centralisée), api_config.dart
  models/      UserModel, GroupeModel, EventModel, CommentModel, NotificationModel
  services/    ApiService (centralise le REST + refresh automatique du token),
               AuthService, GroupService, EventService, NotificationService, StorageService
  providers/   AuthProvider, GroupProvider, EventProvider, NotificationProvider
  screens/     splash/  auth/  groups/  events/  profile/  notifications/
  widgets/     EventCard, GroupCard, EmptyState, ErrorRetryView
  routes/      app_routes.dart (noms), app_router.dart (génération des routes)
  main.dart
```

## Parcours de navigation

```
Splash
  ├─ (pas de session) ──────────────► ProfilSetup ──► GroupeChoice
  └─ (session, 0 groupe) ───────────► GroupeChoice
  └─ (session, ≥1 groupe) ──────────► GroupesScreen
                                          │
                                          ├─ Groupe X ──► EventListScreen ──► EventDetailScreen
                                          │                                        │
                                          │                                   Commentaires, statut
                                          └─ + Ajouter/rejoindre ──► GroupeChoice
```

Navigation implémentée avec `Navigator.push`/`pop` classiques — jamais de `pushReplacement` qui casserait la pile, sauf au moment précis où le Splash redirige selon l'état de session (comportement voulu : impossible de revenir au Splash).

## Points clés d'implémentation

- **Plusieurs groupes** : `GroupProvider.groupes` est une liste, alimentée par `GET /groupes/mes-groupes` qui renvoie systématiquement tous les groupes de l'utilisateur.
- **Statut personnel** : porté par `EventModel.monStatut`, mis à jour uniquement via `PATCH /events/{id}/statut` — jamais partagé entre utilisateurs.
- **Gestion d'erreurs réseau** : `ApiService` traduit timeouts/4xx/5xx en `ApiException` avec un message toujours compréhensible ; chaque écran affiche `ErrorRetryView` plutôt qu'un écran blanc.
- **Empty states** : `EmptyState` réutilisé pour groupes, événements, commentaires, notifications et recherche sans résultat.
- **Notifications** : `NotificationService.initialiser()` absorbe toute erreur Firebase — l'app ne plante jamais si Firebase n'est pas configuré.

## Prochaines étapes suggérées (au-delà du MVP)

- Génération réelle de `firebase_options.dart` pour activer FCM.
- Pagination des événements/membres pour les très grands groupes.
- Upload d'image réel (actuellement : URL d'image saisie manuellement) via `image_picker` + stockage cloud.
- Mode hors-ligne avec cache local (ex. `hive` ou `sqflite`).
