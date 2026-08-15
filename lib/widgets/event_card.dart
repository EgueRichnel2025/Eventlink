// event_card.dart
// Rôle : composant réutilisable représentant un event dans la liste
// (image, description tronquée, badge de statut).
//
// Responsable suggéré : Juste-Baudouin

import 'package:flutter/material.dart';
// TODO: importer EventModel et StatusBadge

class EventCard extends StatelessWidget {
  // TODO: recevoir un EventModel en paramètre du constructeur
  // TODO: recevoir une fonction onTap pour naviguer vers le détail au clic

  const EventCard({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: construire une Card avec :
    // - l'image de l'event (si présente)
    // - la description (tronquée si trop longue)
    // - le widget StatusBadge affichant le statut de l'utilisateur courant
    return const Card(
      child: ListTile(title: Text("TODO: carte event")),
    );
  }
}
