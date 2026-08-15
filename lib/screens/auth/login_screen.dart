// login_screen.dart
// Rôle : écran de connexion (email + mot de passe).
//
// Responsable suggéré : Juste-Baudouin

import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // TODO: ajouter des TextEditingController pour email et mot de passe

  void _seConnecter() {
    // TODO:
    // - récupérer les valeurs saisies
    // - appeler AuthProvider.connecter(email, motDePasse)
    // - si succès, naviguer vers l'écran suivant (rejoindre groupe ou liste events)
    // - si échec, afficher un message d'erreur
  }

  @override
  Widget build(BuildContext context) {
    // TODO: construire le formulaire (champs email/mot de passe + bouton connexion)
    return Scaffold(
      appBar: AppBar(title: const Text("Connexion")),
      body: const Center(child: Text("TODO: formulaire de connexion")),
    );
  }
}
