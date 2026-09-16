import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _api;
  final StorageService _storage;

  AuthService({
    ApiService? api,
    StorageService? storage,
  })  : _api = api ?? ApiService(),
        _storage = storage ?? StorageService();

  /// Crée le profil (première utilisation) et persiste la session.
  Future<UserModel> creerProfil({
    required String prenom,
    required String nom,
    required String email,
    required String password,
    String? avatarId,
  }) async {
    final data = await _api.post(
      '/auth/profil',
      body: {
        'prenom': prenom,
        'nom': nom,
        'email': email,
        'password': password,
        if (avatarId != null) 'avatar_id': avatarId,
      },
      auth: false,
    ) as Map<String, dynamic>;

    final accessToken = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String;

    await _storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    final user = UserModel.fromJson(
      data['user'] as Map<String, dynamic>,
    );

    await _storage.saveAccount(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    return user;
  }

  /// Connecte un compte déjà enregistré sur l'appareil
  /// avec son mot de passe.
  Future<UserModel> connecterCompte({
    required String userId,
    required String password,
  }) async {
    final data = await _api.post(
      '/auth/connexion',
      body: {
        'user_id': userId,
        'password': password,
      },
      auth: false,
    ) as Map<String, dynamic>;

    return _enregistrerSessionDepuisReponse(data);
  }

  /// Recherche un compte avec son code EventLink.
  ///
  /// Cette méthode ne crée aucune session.
  /// Le mot de passe doit ensuite être demandé.
  Future<UserModel> trouverCompteAvecCode(
    String accountCode,
  ) async {
    final data = await _api.post(
      '/auth/connexion-code',
      body: {
        'account_code': accountCode,
      },
      auth: false,
    ) as Map<String, dynamic>;

    return UserModel.fromJson(data);
  }

  /// Demande l'envoi d'un code de récupération par email.
  Future<void> demanderCodeRecuperation(
    String email,
  ) async {
    await _api.post(
      '/auth/email/demander-code',
      body: {
        'email': email,
      },
      auth: false,
    );
  }

  /// Vérifie le code reçu par email.
  ///
  /// Retourne un token temporaire de réinitialisation.
  /// Aucun JWT de session n'est créé à cette étape.
  Future<String> verifierCodeRecuperation({
    required String email,
    required String code,
  }) async {
    final data = await _api.post(
      '/auth/email/verifier-code',
      body: {
        'email': email,
        'code': code,
      },
      auth: false,
    ) as Map<String, dynamic>;

    return data['reset_token'] as String;
  }

  /// Définit un nouveau mot de passe après vérification du code.
  ///
  /// Le backend renvoie directement une nouvelle session.
  Future<UserModel> reinitialiserMotDePasse({
    required String resetToken,
    required String newPassword,
  }) async {
    final data = await _api.post(
      '/auth/mot-de-passe/reinitialiser',
      body: {
        'reset_token': resetToken,
        'new_password': newPassword,
      },
      auth: false,
    ) as Map<String, dynamic>;

    return _enregistrerSessionDepuisReponse(data);
  }

  Future<UserModel> _enregistrerSessionDepuisReponse(
    Map<String, dynamic> data,
  ) async {
    final accessToken = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String;

    await _storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    final user = UserModel.fromJson(
      data['user'] as Map<String, dynamic>,
    );

    await _storage.saveAccount(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    return user;
  }

  Future<UserModel> monProfil() async {
    final data = await _api.get(
      '/auth/moi',
    ) as Map<String, dynamic>;

    return UserModel.fromJson(data);
  }

  Future<UserModel> modifierProfil({
    String? prenom,
    String? nom,
    String? photoUrl,
    String? avatarId,
  }) async {
    final data = await _api.put(
      '/auth/moi',
      body: {
        if (prenom != null) 'prenom': prenom,
        if (nom != null) 'nom': nom,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (avatarId != null) 'avatar_id': avatarId,
      },
    ) as Map<String, dynamic>;

    final user = UserModel.fromJson(data);

    final accessToken = await _storage.getAccessToken();
    final refreshToken = await _storage.getRefreshToken();

    if (accessToken != null &&
        refreshToken != null) {
      await _storage.saveAccount(
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }

    return user;
  }

  Future<bool> aUneSessionLocale() =>
      _storage.hasSession();

  Future<void> deconnexion() =>
      _storage.clear();
}