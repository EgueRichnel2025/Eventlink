// event_provider.dart
// Rôle : garder en mémoire la liste des events du groupe et leurs
// statuts, pour que l'écran liste et l'écran détail restent synchronisés.
//
// Responsable suggéré : Juste-Baudouin

import 'package:flutter/foundation.dart';
// TODO: importer EventModel et ApiService

class EventProvider extends ChangeNotifier {
  // TODO: ajouter une variable List<EventModel> pour stocker les events chargés

  Future<void> chargerEvents(String groupeId) async {
    // TODO:
    // - appeler ApiService.getEvents(groupeId)
    // - transformer chaque élément reçu en EventModel
    // - stocker le résultat et appeler notifyListeners()
    throw UnimplementedError();
  }

  Future<void> ajouterEvent({
    required String lien,
    required String description,
    String? imageUrl,
  }) async {
    // TODO:
    // - appeler ApiService.creerEvent(...)
    // - ajouter le nouvel event à la liste stockée
    // - appeler notifyListeners()
    throw UnimplementedError();
  }

  Future<void> changerStatutEvent(String eventId, String nouveauStatut) async {
    // TODO:
    // - appeler ApiService.changerStatut(...)
    // - mettre à jour l'event correspondant dans la liste stockée
    // - appeler notifyListeners()
    throw UnimplementedError();
  }
}
