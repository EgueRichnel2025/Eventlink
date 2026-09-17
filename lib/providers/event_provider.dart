import 'package:flutter/foundation.dart';

import '../models/comment_model.dart';
import '../models/event_model.dart';
import '../services/api_exception.dart';
import '../services/event_service.dart';

class EventProvider extends ChangeNotifier {
  final EventService _eventService;

  EventProvider({EventService? eventService})
      : _eventService = eventService ?? EventService();

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

  void definirFiltres({
    CategorieEvent? categorie,
    StatutPersonnel? statut,
    String? recherche,
  }) {
    filtreCategorie = categorie;
    filtreStatut = statut;

    if (recherche != null) {
      this.recherche = recherche;
    }

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

      events = [
        event,
        ...events,
      ];

      notifyListeners();

      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changerStatut(
    String eventId,
    StatutPersonnel statut,
  ) async {
    try {
      await _eventService.changerStatut(
        eventId,
        statut,
      );

      events = events
          .map(
            (e) => e.id == eventId
                ? e.copyWith(
                    monStatut: statut,
                  )
                : e,
          )
          .toList();

      notifyListeners();

      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> supprimerEvent(
    String eventId, {
    String? raison,
  }) async {
    errorMessage = null;

    try {
      await _eventService.supprimerEvent(
        eventId,
        raison: raison,
      );

      events = events
          .where((e) => e.id != eventId)
          .toList();

      notifyListeners();

      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> chargerCommentaires(
    String eventId,
  ) async {
    chargementCommentaires = true;
    notifyListeners();

    try {
      commentaires = await _eventService.listerCommentaires(
        eventId,
      );
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      chargementCommentaires = false;
      notifyListeners();
    }
  }

  Future<bool> ajouterCommentaire(
    String eventId,
    String texte, {
    String? parentCommentId,
  }) async {
    try {
      final commentaire =
          await _eventService.ajouterCommentaire(
        eventId,
        texte,
        parentCommentId: parentCommentId,
      );

      commentaires = [
        ...commentaires,
        commentaire,
      ];

      events = events
          .map(
            (e) => e.id == eventId
                ? e.copyWith(
                    nombreCommentaires:
                        e.nombreCommentaires + 1,
                  )
                : e,
          )
          .toList();

      notifyListeners();

      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> modifierCommentaire({
    required String eventId,
    required String commentId,
    required String texte,
  }) async {
    try {
      final commentaire =
          await _eventService.modifierCommentaire(
        eventId,
        commentId,
        texte,
      );

      commentaires = commentaires
          .map(
            (commentaireExistant) =>
                commentaireExistant.id == commentId
                    ? commentaire
                    : commentaireExistant,
          )
          .toList();

      notifyListeners();

      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> supprimerCommentaire({
    required String eventId,
    required String commentId,
  }) async {
    try {
      await _eventService.supprimerCommentaire(
        eventId,
        commentId,
      );

      commentaires = commentaires
          .where(
            (commentaire) => commentaire.id != commentId,
          )
          .toList();

      events = events
          .map(
            (e) => e.id == eventId
                ? e.copyWith(
                    nombreCommentaires:
                        e.nombreCommentaires > 0
                            ? e.nombreCommentaires - 1
                            : 0,
                  )
                : e,
          )
          .toList();

      notifyListeners();

      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleCommentEpingle({
    required String eventId,
    required String commentId,
  }) async {
    try {
      final commentaire =
          await _eventService.toggleCommentEpingle(
        eventId,
        commentId,
      );

      commentaires = commentaires
          .map(
            (commentaireExistant) =>
                commentaireExistant.id == commentId
                    ? commentaire
                    : commentaireExistant,
          )
          .toList();

      notifyListeners();

      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleCommentReaction({
    required String eventId,
    required String commentId,
    required String reactionType,
  }) async {
    try {
      final commentaire =
          await _eventService.toggleCommentReaction(
        eventId,
        commentId,
        reactionType,
      );

      commentaires = commentaires
          .map(
            (commentaireExistant) =>
                commentaireExistant.id == commentId
                    ? commentaire
                    : commentaireExistant,
          )
          .toList();

      notifyListeners();

      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> incrVues(String eventId) async {
    try {
      await _eventService.incrVues(eventId);

      events = events
          .map(
            (e) => e.id == eventId
                ? e.copyWith(
                    vues: e.vues + 1,
                  )
                : e,
          )
          .toList();

      notifyListeners();

      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleReaction(
    String eventId,
    String reactionType,
  ) async {
    try {
      await _eventService.toggleReaction(
        eventId,
        reactionType,
      );

      events = events
          .map(
            (e) {
              if (e.id != eventId) {
                return e;
              }

              final anciennesReactions =
                  Map<String, int>.from(
                e.reactions,
              );

              final ancienneReaction =
                  e.userReaction;

              if (ancienneReaction == reactionType) {
                if (anciennesReactions
                    .containsKey(reactionType)) {
                  final nouveauNombre =
                      anciennesReactions[
                              reactionType]! -
                          1;

                  if (nouveauNombre <= 0) {
                    anciennesReactions
                        .remove(reactionType);
                  } else {
                    anciennesReactions[
                            reactionType] =
                        nouveauNombre;
                  }
                }

                return e.copyWith(
                  reactions: anciennesReactions,
                  userReaction: null,
                );
              }

              if (ancienneReaction != null) {
                final ancienNombre =
                    (anciennesReactions[
                                ancienneReaction] ??
                            1) -
                        1;

                if (ancienNombre <= 0) {
                  anciennesReactions
                      .remove(ancienneReaction);
                } else {
                  anciennesReactions[
                          ancienneReaction] =
                      ancienNombre;
                }
              }

              anciennesReactions[reactionType] =
                  (anciennesReactions[
                              reactionType] ??
                          0) +
                      1;

              return e.copyWith(
                reactions: anciennesReactions,
                userReaction: reactionType,
              );
            },
          )
          .toList();

      notifyListeners();

      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<EventModel?> obtenirEvent(
    String eventId,
  ) async {
    try {
      final event =
          await _eventService.obtenirEvent(eventId);

      final existeDeja =
          events.any((e) => e.id == event.id);

      if (existeDeja) {
        events = events
            .map(
              (e) => e.id == event.id
                  ? event
                  : e,
            )
            .toList();
      } else {
        events = [
          event,
          ...events,
        ];
      }

      notifyListeners();

      return event;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }
}
