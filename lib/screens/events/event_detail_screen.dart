// event_detail_screen.dart
// Rôle : écran détail d'un event. Affiche toutes ses infos, permet
// de changer son statut, et affiche/ajoute des commentaires.
//
// Responsable suggéré : Juste-Baudouin

import 'package:flutter/material.dart';
// TODO: importer EventModel, EventProvider, StatusBadge

class EventDetailScreen extends StatefulWidget {
  // TODO: recevoir l'event (ou son id) en paramètre du constructeur
  const EventDetailScreen({super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  // TODO: ajouter un TextEditingController pour le champ de nouveau commentaire

  void _changerStatut(String nouveauStatut) {
    // TODO: appeler EventProvider.changerStatutEvent(eventId, nouveauStatut)
  }

  void _envoyerCommentaire() {
    // TODO:
    // - récupérer le texte saisi
    // - appeler ApiService.ajouterCommentaire(eventId, texte)
    // - vider le champ et rafraîchir la liste des commentaires affichés
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Détail de l'event")),
      body: Column(
        children: [
          // TODO: afficher lien, description, image (si présente)
          // TODO: afficher les boutons de statut (à voir / inscrit / passé)
          // avec le widget StatusBadge

          // TODO: afficher la section commentaires :
          // - liste des commentaires existants (ListView)
          // - champ de saisie + bouton envoyer en bas de l'écran

          const Expanded(child: Center(child: Text("TODO: contenu de l'event"))),
        ],
      ),
    );
  }
}
