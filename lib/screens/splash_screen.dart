// splash_screen.dart
// Rôle : premier écran affiché au lancement de l'app. Vérifie si
// l'utilisateur est déjà connecté et redirige en conséquence.
//
// Responsable suggéré : Juste-Baudouin

import 'package:flutter/material.dart';
// TODO: importer login_screen.dart et event_list_screen.dart

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // TODO:
    // - vérifier si l'utilisateur est déjà connecté (AuthService.estConnecte())
    // - si oui, naviguer vers EventListScreen
    // - sinon, naviguer vers LoginScreen
  }

  @override
  Widget build(BuildContext context) {
    // TODO: afficher un logo/loader pendant la vérification
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
