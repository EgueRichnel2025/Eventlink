import 'package:flutter/foundation.dart';

import '../models/comment_model.dart';
import '../models/event_model.dart';
import '../services/api_exception.dart';
import '../services/event_service.dart';

class EventProvider extends ChangeNotifier {
  final EventService _eventService;

  EventProvider({EventService? eventService}) : _eventService = eventService ?? EventService();

  List<EventModel> events = [];
  bool isLoading = false;
  String? errorMessage;

  // Filtres actifs
  CategorieEvent? filtreCategorie;
  StatutPersonnel? filtreStatut;
  String recherche = '';

  List<CommentModel> commentaires = [];
  bool chargementCommentaires = false;

  Future<void> chargerEvents(String groupId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      events = await _eventService.listerEvents(
        groupId: groupId,
        categorie: filtreCategorie,
        statut: filtreStatut,
        recherche: recherche,
      );
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void definirFiltres({CategorieEvent? categorie, StatutPersonnel? statut, String? recherche}) {
    filtreCategorie = categorie;
    filtreStatut = statut;
    if (recherche != null) this.recherche = recherche;
    notifyListeners();
  }

  void reinitialiserFiltres() {
    filtreCategorie = null;
    filtreStatut = null;
    recherche = '';
    notifyListeners();
  }

  Future<bool> creerEvent({
    required String groupId,
    required String lien,
    required String description,
    String? imageUrl,
    required CategorieEvent categorie,
  }) async {
    errorMessage = null;
    try {
      final event = await _eventService.creerEvent(
        groupId: groupId,
        lien: lien,
        description: description,
        imageUrl: imageUrl,
        categorie: categorie,
      );
      events = [event, ...events];
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changerStatut(String eventId, StatutPersonnel statut) async {
    try {
      await _eventService.changerStatut(eventId, statut);
      events = events.map((e) => e.id == eventId ? e.copyWith(monStatut: statut) : e).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> supprimerEvent(String eventId) async {
    try {
      await _eventService.supprimerEvent(eventId);
      events = events.where((e) => e.id != eventId).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> chargerCommentaires(String eventId) async {
    chargementCommentaires = true;
    notifyListeners();
    try {
      commentaires = await _eventService.listerCommentaires(eventId);
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      chargementCommentaires = false;
      notifyListeners();
    }
  }

  Future<bool> ajouterCommentaire(String eventId, String texte) async {
    try {
      final commentaire = await _eventService.ajouterCommentaire(eventId, texte);
      commentaires = [...commentaires, commentaire];
      events = events
          .map((e) => e.id == eventId
              ? EventModel(
                  id: e.id,
                  groupId: e.groupId,
                  lien: e.lien,
                  description: e.description,
                  imageUrl: e.imageUrl,
                  categorie: e.categorie,
                  auteur: e.auteur,
                  createdAt: e.createdAt,
                  monStatut: e.monStatut,
                  nombreCommentaires: e.nombreCommentaires + 1,
                )
              : e)
          .toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
