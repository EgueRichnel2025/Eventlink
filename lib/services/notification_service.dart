import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/notification_model.dart';
import 'api_service.dart';

/// Gère les notifications (FCM + notifications locales pour les rappels).
///
/// Règle impérative : si Firebase n'est pas configuré dans le projet
/// (pas de `firebase_options.dart` généré, pas de google-services.json/plist),
/// l'application doit continuer à fonctionner normalement. Toute erreur
/// d'initialisation est absorbée ici et transformée en simple désactivation
/// des notifications push — jamais un crash.
class NotificationService {
  final ApiService _api;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _firebaseDisponible = false;
  bool get firebaseDisponible => _firebaseDisponible;

  NotificationService({ApiService? api}) : _api = api ?? ApiService();

  /// À appeler une fois au démarrage de l'app (après runApp). N'échoue jamais.
  Future<void> initialiser() async {
    await _initFirebaseEnDouceur();
    await _initNotificationsLocales();
  }

  Future<void> _initFirebaseEnDouceur() async {
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      final token = await messaging.getToken();
      if (token != null) {
        await _enregistrerTokenAuBackend(token);
      }
      messaging.onTokenRefresh.listen(_enregistrerTokenAuBackend);

      _firebaseDisponible = true;
    } catch (e) {
      // Firebase non configuré (pas d'options par défaut, projet non lié, etc.)
      // -> on continue sans notifications push, sans jamais faire planter l'app.
      developer.log('Firebase indisponible — notifications push désactivées: $e', name: 'NotificationService');
      _firebaseDisponible = false;
    }
  }

  Future<void> _initNotificationsLocales() async {
    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.local);

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
      await _localNotifications.initialize(settings);
    } catch (e) {
      developer.log('Notifications locales indisponibles: $e', name: 'NotificationService');
    }
  }

  Future<void> _enregistrerTokenAuBackend(String token) async {
    try {
      await _api.post('/notifications/register-token', body: {'fcm_token': token});
    } catch (e) {
      developer.log("Impossible d'enregistrer le token FCM: $e", name: 'NotificationService');
    }
  }

  Future<List<NotificationModel>> mesNotifications() async {
    final data = await _api.get('/notifications') as List<dynamic>;
    return data.map((n) => NotificationModel.fromJson(n as Map<String, dynamic>)).toList();
  }

  Future<void> marquerCommeLue(String notificationId) async {
    await _api.patch('/notifications/$notificationId/lu');
  }

  /// Programme un rappel local pour un événement (fonctionne même sans Firebase).
  Future<void> programmerRappel({
    required int id,
    required String titre,
    required String corps,
    required DateTime dateHeure,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'eventlink_rappels',
        'Rappels EventLink',
        channelDescription: 'Rappels programmés pour les événements',
        importance: Importance.high,
        priority: Priority.high,
      );
      const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

      await _localNotifications.zonedSchedule(
        id,
        titre,
        corps,
        _toTZDateTime(dateHeure) as tz.TZDateTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      developer.log('Impossible de programmer le rappel local: $e', name: 'NotificationService');
    }
  }

  dynamic _toTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }
}
