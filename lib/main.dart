import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/group_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'routes/app_router.dart';
import 'routes/app_routes.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  runApp(const EventLinkApp());
}

class EventLinkApp extends StatelessWidget {
  const EventLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) {
          final provider = NotificationProvider();

          // N'échoue jamais, même si Firebase n'est pas configuré dans le projet.
          provider.initialiser();

          return provider;
        }),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(
            context.read<StorageService>(),
          ),
        ),
      ],
      child: const _EventLinkMaterialApp(),
    );
  }
}

class _EventLinkMaterialApp extends StatelessWidget {
  const _EventLinkMaterialApp();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'EventLink',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}