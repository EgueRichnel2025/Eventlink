// api_service.dart
// Rôle : centraliser tous les appels HTTP vers le backend FastAPI,
// pour que les écrans n'aient pas à gérer les requêtes eux-mêmes.
//
// Responsable suggéré : Juste-Baudouin

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class ApiService {
  // ---- EVENTS ----

  Future<List<dynamic>> getEvents(String groupeId) async {
    // TODO:
    // - faire un GET vers ${AppConstants.baseUrl}/events?groupe_id=$groupeId
    // - décoder la réponse JSON
    // - retourner la liste des events
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>> creerEvent({
    required String lien,
    required String description,
    String? imageUrl,
  }) async {
    // TODO:
    // - faire un POST vers ${AppConstants.baseUrl}/events
    // - envoyer lien, description, imageUrl dans le body (en JSON)
    // - retourner l'event créé
    throw UnimplementedError();
  }

  Future<void> changerStatut(String eventId, String nouveauStatut) async {
    // TODO:
    // - faire un PATCH vers ${AppConstants.baseUrl}/events/$eventId/statut
    // - envoyer le nouveau statut dans le body
    throw UnimplementedError();
  }

  Future<void> ajouterCommentaire(String eventId, String texte) async {
    // TODO:
    // - faire un POST vers ${AppConstants.baseUrl}/events/$eventId/commentaires
    // - envoyer le texte du commentaire dans le body
    throw UnimplementedError();
  }

  // ---- GROUPE ----

  Future<Map<String, dynamic>> rejoindreGroupe(String codeInvitation) async {
    // TODO:
    // - faire un POST vers ${AppConstants.baseUrl}/groupes/rejoindre
    // - envoyer le code_invitation dans le body
    // - retourner le groupe rejoint
    throw UnimplementedError();
  }
}
