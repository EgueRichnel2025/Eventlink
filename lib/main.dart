// main.dart
// Rôle : point d'entrée de l'application Flutter.
//
// Responsable suggéré : toi (Richnel) en coordination avec Juste-Baudouin

import 'package:flutter/material.dart';
// TODO: importer le splash_screen une fois créé
// import 'screens/splash_screen.dart';

void main() {
  runApp(const EventLinkApp());
}

class EventLinkApp extends StatelessWidget {
  const EventLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventLink',
      debugShowCheckedModeBanner: false,
      // TODO: appliquer le thème défini dans config/theme.dart
      // theme: AppTheme.themeClair,

      // TODO: remplacer par SplashScreen() une fois créé
      home: const Placeholder(),
    );
  }
}
