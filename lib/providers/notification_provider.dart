import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import '../services/api_exception.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService;

  NotificationProvider({NotificationService? notificationService})
      : _notificationService =
            notificationService ?? NotificationService();

  List<NotificationModel> notifications = [];
  bool isLoading = false;
  String? errorMessage;

  int get nombreNonLues => notifications.where((n) => !n.lu).length;

  Future<void> initialiser() async {
    // N'échoue jamais, même si Firebase n'est pas configuré.
    await _notificationService.initialiser(
      onNotificationReceived: chargerNotifications,
    );
  }

  /// Enregistre le token FCM une fois que l'utilisateur possède
  /// une session authentifiée.
  Future<void> enregistrerTokenApresConnexion() async {
    await _notificationService.enregistrerTokenApresConnexion();
  }

  Future<void> chargerNotifications() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      notifications = await _notificationService.mesNotifications();
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> marquerCommeLue(String notificationId) async {
    try {
      await _notificationService.marquerCommeLue(notificationId);

      notifications = notifications
          .map(
            (n) => n.id == notificationId
                ? NotificationModel(
                    id: n.id,
                    userId: n.userId,
                    type: n.type,
                    titre: n.titre,
                    corps: n.corps,
                    data: n.data,
                    lu: true,
                    createdAt: n.createdAt,
                  )
                : n,
          )
          .toList();

      notifyListeners();
    } on ApiException {
      // Une notification qui reste "non lue" faute de réseau n'est pas bloquant.
    }
  }

  Future<void> marquerToutesCommeLues() async {
    try {
      await _notificationService.marquerToutesCommeLues();

      notifications = notifications
          .map(
            (n) => NotificationModel(
              id: n.id,
              userId: n.userId,
              type: n.type,
              titre: n.titre,
              corps: n.corps,
              data: n.data,
              lu: true,
              createdAt: n.createdAt,
            ),
          )
          .toList();

      notifyListeners();
    } on ApiException {
      // Si le réseau échoue, on conserve l'état local
      // afin de ne pas prétendre que les notifications sont lues.
    }
  }
}
