// event_list_screen.dart
// Rôle : écran principal de l'app. Affiche la liste de tous les events
// du groupe, avec le bouton "Ajouter" pour en créer un nouveau.
//
// Responsable suggéré : Juste-Baudouin

import 'package:flutter/material.dart';
// TODO: importer EventProvider, EventCard, AddLinkScreen, EventDetailScreen

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  @override
  void initState() {
    super.initState();
    // TODO: appeler EventProvider.chargerEvents(groupeId) au chargement de l'écran
  }

  void _allerVersAjout() {
    // TODO: naviguer vers AddLinkScreen (le formulaire d'ajout)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("EventLink")),
      // TODO: afficher la liste des events avec ListView.builder
      // et le widget EventCard pour chaque event
      body: const Center(child: Text("TODO: liste des events")),

      // Bouton "Ajouter"
      floatingActionButton: FloatingActionButton(
        onPressed: _allerVersAjout,
        child: const Icon(Icons.add),
      ),
    );
  }
}
