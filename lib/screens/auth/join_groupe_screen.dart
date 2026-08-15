// join_groupe_screen.dart
// Rôle : écran où l'utilisateur saisit le code d'invitation pour
// rejoindre le groupe EventLink.
//
// Responsable suggéré : Juste-Baudouin

import 'package:flutter/material.dart';

class JoinGroupeScreen extends StatefulWidget {
  const JoinGroupeScreen({super.key});

  @override
  State<JoinGroupeScreen> createState() => _JoinGroupeScreenState();
}

class _JoinGroupeScreenState extends State<JoinGroupeScreen> {
  // TODO: ajouter un TextEditingController pour le code d'invitation

  void _rejoindre() {
    // TODO:
    // - récupérer le code saisi
    // - appeler ApiService.rejoindreGroupe(code)
    // - si succès, naviguer vers EventListScreen
    // - si échec, afficher un message d'erreur (code invalide)
  }

  @override
  Widget build(BuildContext context) {
    // TODO: construire le formulaire (champ code + bouton rejoindre)
    return Scaffold(
      appBar: AppBar(title: const Text("Rejoindre le groupe")),
      body: const Center(child: Text("TODO: formulaire code d'invitation")),
    );
  }
}
