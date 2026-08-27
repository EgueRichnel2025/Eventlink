import '../models/comment_model.dart';
import '../models/event_model.dart';
import 'api_service.dart';

class EventService {
  final ApiService _api;

  EventService({ApiService? api}) : _api = api ?? ApiService();

  Future<EventModel> creerEvent({
    required String groupId,
    required String lien,
    required String description,
    String? imageUrl,
    required CategorieEvent categorie,
  }) async {
    final data = await _api.post(
      '/events',
      query: {'groupe_id': groupId},
      body: {
        'lien': lien,
        'description': description,
        'image_url': imageUrl,
        'categorie': categorie.name,
      },
    ) as Map<String, dynamic>;
    return EventModel.fromJson(data);
  }

  Future<List<EventModel>> listerEvents({
    required String groupId,
    CategorieEvent? categorie,
    StatutPersonnel? statut,
    String? recherche,
  }) async {
    final data = await _api.get(
      '/events',
      query: {
        'groupe_id': groupId,
        if (categorie != null) 'categorie': categorie.name,
        if (statut != null) 'statut': statut.apiValue,
        if (recherche != null && recherche.isNotEmpty) 'q': recherche,
      },
    ) as List<dynamic>;
    return data.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<EventModel> obtenirEvent(String eventId) async {
    final data = await _api.get('/events/$eventId') as Map<String, dynamic>;
    return EventModel.fromJson(data);
  }

  Future<void> modifierEvent(
    String eventId, {
    String? lien,
    String? description,
    String? imageUrl,
    CategorieEvent? categorie,
  }) async {
    await _api.put(
      '/events/$eventId',
      body: {
        if (lien != null) 'lien': lien,
        if (description != null) 'description': description,
        if (imageUrl != null) 'image_url': imageUrl,
        if (categorie != null) 'categorie': categorie.name,
      },
    );
  }

  Future<void> supprimerEvent(String eventId) async {
    await _api.delete('/events/$eventId');
  }

  Future<void> changerStatut(String eventId, StatutPersonnel statut) async {
    await _api.patch('/events/$eventId/statut', body: {'statut': statut.apiValue});
  }

  Future<List<CommentModel>> listerCommentaires(String eventId) async {
    final data = await _api.get('/events/$eventId/commentaires') as List<dynamic>;
    return data.map((c) => CommentModel.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<CommentModel> ajouterCommentaire(String eventId, String texte) async {
    final data = await _api.post(
      '/events/$eventId/commentaires',
      body: {'texte': texte},
    ) as Map<String, dynamic>;
    return CommentModel.fromJson(data);
  }
}
