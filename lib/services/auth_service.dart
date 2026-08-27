import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _api;
  final StorageService _storage;

  AuthService({ApiService? api, StorageService? storage})
      : _api = api ?? ApiService(),
        _storage = storage ?? StorageService();

  /// Crée le profil (première utilisation) et persiste la session.
  Future<UserModel> creerProfil({required String prenom, required String nom}) async {
    final data = await _api.post(
      '/auth/profil',
      body: {'prenom': prenom, 'nom': nom},
      auth: false,
    ) as Map<String, dynamic>;

    await _storage.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );

    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<UserModel> monProfil() async {
    final data = await _api.get('/auth/moi') as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<UserModel> modifierProfil({String? prenom, String? nom, String? photoUrl}) async {
    final data = await _api.put(
      '/auth/moi',
      body: {
        if (prenom != null) 'prenom': prenom,
        if (nom != null) 'nom': nom,
        if (photoUrl != null) 'photo_url': photoUrl,
      },
    ) as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<bool> aUneSessionLocale() => _storage.hasSession();

  Future<void> deconnexion() => _storage.clear();
}
