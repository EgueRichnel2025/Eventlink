import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../firebase_options.dart';
import '../models/notification_model.dart';
import 'api_service.dart';

/// Canal Android utilisé pour les notifications push générales EventLink.
const AndroidNotificationChannel _generalNotificationChannel =
    AndroidNotificationChannel(
  'eventlink_general',
  'Notifications EventLink',
  description: 'Notifications générales de l’application EventLink',
  importance: Importance.high,
);

/// Gère les notifications (FCM + notifications locales pour les rappels).
///
/// Règle impérative : si Firebase n'est pas configuré dans le projet
/// (pas de `firebase_options.dart` généré, pas de google-services.json/plist),
/// l'application doit continuer à fonctionner normalement. Toute erreur
/// d'initialisation est absorbée ici et transformée en simple désactivation
/// des notifications push — jamais un crash.
class NotificationService {
  final ApiService _api;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _firebaseDisponible = false;
  bool get firebaseDisponible => _firebaseDisponible;

  NotificationService({ApiService? api}) : _api = api ?? ApiService();

  /// À appeler une fois au démarrage de l'app (après runApp). N'échoue jamais.
  Future<void> initialiser({
    Future<void> Function()? onNotificationReceived,
  }) async {
    await _initFirebaseEnDouceur(
      onNotificationReceived: onNotificationReceived,
    );
    await _initNotificationsLocales();
  }

  Future<void> _initFirebaseEnDouceur({
    Future<void> Function()? onNotificationReceived,
  }) async {
    try {
      // Firebase est déjà initialisé dans main.dart.
      // Cette vérification évite une double initialisation.
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission();

      FirebaseMessaging.onMessage.listen(
        (message) async {
          await _gererMessagePremierPlan(message);

          // Le backend a déjà enregistré la notification.
          // On recharge simplement la liste pour actualiser le badge.
          if (onNotificationReceived != null) {
            try {
              await onNotificationReceived();
            } catch (e) {
              developer.log(
                'Impossible de recharger les notifications après réception FCM: $e',
                name: 'NotificationService',
              );
            }
          }
        },
      );

      messaging.onTokenRefresh.listen(_enregistrerTokenAuBackend);

      _firebaseDisponible = true;
    } catch (e) {
      developer.log(
        'Firebase indisponible — notifications push désactivées: $e',
        name: 'NotificationService',
      );
      _firebaseDisponible = false;
    }
  }

  Future<void> _initNotificationsLocales() async {
    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.local);

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(settings);

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(
        _generalNotificationChannel,
      );
    } catch (e) {
      developer.log(
        'Notifications locales indisponibles: $e',
        name: 'NotificationService',
      );
    }
  }

  /// Affiche une notification locale lorsqu'un message FCM arrive
  /// alors que l'application est au premier plan.
  Future<void> _gererMessagePremierPlan(RemoteMessage message) async {
    try {
      final notification = message.notification;

      final titre = notification?.title ??
          message.data['titre']?.toString() ??
          'EventLink';

      final corps = notification?.body ??
          message.data['corps']?.toString() ??
          '';

      if (corps.isEmpty) {
        return;
      }

      await _localNotifications.show(
        message.hashCode,
        titre,
        corps,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'eventlink_general',
            'Notifications EventLink',
            channelDescription:
                'Notifications générales de l’application EventLink',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: message.data.toString(),
      );
    } catch (e) {
      developer.log(
        'Impossible d’afficher la notification FCM au premier plan: $e',
        name: 'NotificationService',
      );
    }
  }

  /// Enregistre le token FCM auprès du backend.
  ///
  /// Cette méthode est volontairement appelée après l'authentification,
  /// car l'endpoint backend nécessite un JWT valide.
  Future<void> enregistrerTokenApresConnexion() async {
    if (!_firebaseDisponible) {
      return;
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();

      if (token != null && token.isNotEmpty) {
        await _enregistrerTokenAuBackend(token);
      }
    } catch (e) {
      developer.log(
        'Impossible de récupérer/enregistrer le token FCM après connexion: $e',
        name: 'NotificationService',
      );
    }
  }

  Future<void> _enregistrerTokenAuBackend(String token) async {
    try {
      await _api.post(
        '/notifications/register-token',
        body: {'fcm_token': token},
      );
    } catch (e) {
      developer.log(
        'Impossible d’enregistrer le token FCM: $e',
        name: 'NotificationService',
      );
    }
  }

  Future<List<NotificationModel>> mesNotifications() async {
    final data = await _api.get('/notifications') as List<dynamic>;

    return data
        .map(
          (n) => NotificationModel.fromJson(
            n as Map<String, dynamic>,
          ),
        )
        .toList();
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

      const details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _localNotifications.zonedSchedule(
        id,
        titre,
        corps,
        _toTZDateTime(dateHeure),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      developer.log(
        'Impossible de programmer le rappel local: $e',
        name: 'NotificationService',
      );
    }
  }

  tz.TZDateTime _toTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }
}

/// Handler appelé par Firebase lorsque l'application reçoit un message
/// FCM en arrière-plan.
///
/// Cette fonction doit être au niveau supérieur du fichier et possède
/// l'annotation entry-point afin de rester accessible après compilation.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final plugin = FlutterLocalNotificationsPlugin();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await plugin.initialize(settings);

    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      _generalNotificationChannel,
    );

    final notification = message.notification;

    final titre = notification?.title ??
        message.data['titre']?.toString() ??
        'EventLink';

    final corps = notification?.body ??
        message.data['corps']?.toString() ??
        '';

    if (corps.isEmpty) {
      return;
    }

    await plugin.show(
      message.hashCode,
      titre,
      corps,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'eventlink_general',
          'Notifications EventLink',
          channelDescription:
              'Notifications générales de l’application EventLink',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data.toString(),
    );
  } catch (e) {
    developer.log(
      'Impossible de traiter la notification FCM en arrière-plan: $e',
      name: 'NotificationService',
    );
  }
}