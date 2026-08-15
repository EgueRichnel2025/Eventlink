// status_badge.dart
// Rôle : petit badge visuel affichant le statut d'un membre sur un
// event (à voir / inscrit / passé), avec une couleur différente pour chaque.
//
// Responsable suggéré : Juste-Baudouin

import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  // TODO: recevoir le statut actuel en paramètre (String : "a_voir" | "inscrit" | "passe")

  const StatusBadge({super.key});

  Color _couleurPourStatut(String statut) {
    // TODO: retourner une couleur différente selon le statut
    // (ex: gris pour "a_voir", vert pour "inscrit", rouge/gris foncé pour "passe")
    throw UnimplementedError();
  }

  String _texteAffiche(String statut) {
    // TODO: retourner un texte lisible selon le statut
    // ("À voir" / "Inscrit" / "Passé")
    throw UnimplementedError();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: construire un petit badge (Container arrondi) avec la couleur
    // et le texte correspondant au statut
    return const Chip(label: Text("TODO: badge statut"));
  }
}
