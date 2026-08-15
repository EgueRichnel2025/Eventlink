// notification_service.dart
// Rôle : gérer la réception des notifications push (Firebase Cloud
// Messaging) en foreground et en background.
//
// Responsable suggéré : Juste-Baudouin
//
// Pré-requis avant de coder :
// - avoir ajouté le package firebase_messaging au pubspec.yaml
// - avoir configuré le projet Firebase côté Flutter (google-services.json)

class NotificationService {
  Future<void> initialiser() async {
    // TODO:
    // - demander la permission de notifications à l'utilisateur
    // - récupérer le token FCM de l'appareil
    // - envoyer ce token au backend pour qu'il soit associé à l'utilisateur
    throw UnimplementedError();
  }

  void ecouterNotificationsForeground() {
    // TODO:
    // - utiliser FirebaseMessaging.onMessage.listen(...)
    // - afficher une notification locale quand l'app est ouverte
    throw UnimplementedError();
  }

  void ecouterClicNotification() {
    // TODO:
    // - utiliser FirebaseMessaging.onMessageOpenedApp.listen(...)
    // - naviguer vers l'écran détail de l'event concerné au clic
    throw UnimplementedError();
  }
}
