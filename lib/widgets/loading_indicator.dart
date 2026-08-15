// loading_indicator.dart
// Rôle : indicateur de chargement réutilisable, à afficher pendant
// les appels API (chargement des events, envoi d'un formulaire, etc.).
//
// Responsable suggéré : Juste-Baudouin

import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: personnaliser si besoin (couleur, taille), sinon garder simple
    return const Center(child: CircularProgressIndicator());
  }
}
