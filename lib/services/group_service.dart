import '../models/groupe_model.dart';
import 'api_service.dart';

class GroupService {
  final ApiService _api;

  GroupService({ApiService? api}) : _api = api ?? ApiService();

  Future<GroupeModel> creerGroupe(String nom) async {
    final data = await _api.post('/groupes/creer', body: {'nom': nom}) as Map<String, dynamic>;
    return GroupeModel.fromJson(data);
  }

  Future<GroupeModel> rejoindreGroupe(String codeInvitation) async {
    final data = await _api.post(
      '/groupes/rejoindre',
      body: {'code_invitation': codeInvitation.trim().toUpperCase()},
    ) as Map<String, dynamic>;
    return GroupeModel.fromJson(data);
  }

  /// Retourne TOUS les groupes de l'utilisateur — jamais un seul groupe actif.
  Future<List<GroupeModel>> mesGroupes() async {
    final data = await _api.get('/groupes/mes-groupes') as List<dynamic>;
    return data.map((g) => GroupeModel.fromJson(g as Map<String, dynamic>)).toList();
  }

  Future<GroupeModel> obtenirGroupe(String groupId) async {
    final data = await _api.get('/groupes/$groupId') as Map<String, dynamic>;
    return GroupeModel.fromJson(data);
  }

  Future<List<MembreGroupeModel>> lisMembres(String groupId) async {
    final data = await _api.get('/groupes/$groupId/membres') as List<dynamic>;
    return data.map((m) => MembreGroupeModel.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<void> modifierGroupe(String groupId, {String? nom, String? photoUrl}) async {
    await _api.put(
      '/groupes/$groupId',
      body: {
        if (nom != null) 'nom': nom,
        if (photoUrl != null) 'photo_url': photoUrl,
      },
    );
  }

  Future<void> retirerMembre(String groupId, String userId) async {
    await _api.delete('/groupes/$groupId/membres/$userId');
  }
}
