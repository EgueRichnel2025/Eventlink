import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/stored_account.dart';
import '../models/user_model.dart';

/// Stockage local sécurisé de la session, des comptes connus
/// et des préférences utilisateur.
///
/// Utilise flutter_secure_storage (Keychain/Keystore) pour les données sensibles
/// (tokens) et des préférences non sensibles.
class StorageService {
  final FlutterSecureStorage _storage;

  /// Creates a [StorageService] with an optional [FlutterSecureStorage] instance.
  /// If [storage] is null, a new FlutterSecureStorage instance will be created.
  StorageService({FlutterSecureStorage? storage})
      : _storage =
            storage ?? const FlutterSecureStorage();

  // Clés pour les tokens de la session active
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';

  // Clé des comptes connus sur l'appareil
  static const _keyStoredAccounts = 'stored_accounts';

  // Nombre maximum de comptes connus sur l'appareil
  static const int maxStoredAccounts = 3;

  // Clés pour les préférences (non sensibles)
  static const _keyHasCompletedOnboarding =
      'has_completed_onboarding';

  static const _keyThemePreference =
      'theme_preference'; // 'light', 'dark', 'system'

  static const _keyLanguageCode =
      'language_code'; // ex: 'fr', 'en'

  static const _keyNotificationsEnabled =
      'notifications_enabled';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(
      key: _keyAccessToken,
      value: accessToken,
    );

    await _storage.write(
      key: _keyRefreshToken,
      value: refreshToken,
    );
  }

  Future<void> saveAccessToken(
    String accessToken,
  ) async {
    await _storage.write(
      key: _keyAccessToken,
      value: accessToken,
    );
  }

  Future<String?> getAccessToken() =>
      _storage.read(
        key: _keyAccessToken,
      );

  Future<String?> getRefreshToken() =>
      _storage.read(
        key: _keyRefreshToken,
      );

  /// Indique si un nouveau compte peut être enregistré
  /// sur l'appareil.
  Future<bool> peutAjouterCompte() async {
    final accounts = await getStoredAccounts();

    return accounts.length < maxStoredAccounts;
  }

  /// Enregistre ou met à jour un compte connu sur l'appareil.
  ///
  /// La limite de 3 comptes concerne uniquement les nouveaux comptes.
  /// La mise à jour d'un compte déjà présent reste toujours autorisée.
  Future<void> saveAccount({
    required UserModel user,
    required String accessToken,
    required String refreshToken,
  }) async {
    final accounts = await getStoredAccounts();

    final account = StoredAccount(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    final index = accounts.indexWhere(
      (existing) => existing.user.id == user.id,
    );

    if (index >= 0) {
      accounts[index] = account;
    } else {
      if (accounts.length >= maxStoredAccounts) {
        throw StateError(
          'Impossible d\'ajouter un quatrième compte. '
          'Un appareil peut contenir au maximum '
          '$maxStoredAccounts comptes.',
        );
      }

      accounts.add(account);
    }

    await _storage.write(
      key: _keyStoredAccounts,
      value: jsonEncode(
        accounts
            .map(
              (account) => account.toJson(),
            )
            .toList(),
      ),
    );
  }

  /// Retourne tous les comptes connus sur l'appareil.
  Future<List<StoredAccount>> getStoredAccounts() async {
    final raw = await _storage.read(
      key: _keyStoredAccounts,
    );

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(
            StoredAccount.fromJson,
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Active la session d'un compte déjà connu.
  Future<void> activateAccount(
    StoredAccount account,
  ) async {
    await saveTokens(
      accessToken: account.accessToken,
      refreshToken: account.refreshToken,
    );
  }

  /// Supprime uniquement la session active.
  ///
  /// Les comptes connus restent conservés afin de permettre
  /// une reconnexion ultérieure.
  Future<void> clear() async {
    await _storage.delete(
      key: _keyAccessToken,
    );

    await _storage.delete(
      key: _keyRefreshToken,
    );
  }

  Future<bool> hasSession() async {
    final token = await getAccessToken();

    return token != null && token.isNotEmpty;
  }

  // Onboarding tracking

  Future<bool> hasCompletedOnboarding() async {
    final value = await _storage.read(
      key: _keyHasCompletedOnboarding,
    );

    return value == 'true';
  }

  Future<void> markOnboardingCompleted() async {
    await _storage.write(
      key: _keyHasCompletedOnboarding,
      value: 'true',
    );
  }

  // Theme preference

  Future<String?> getThemePreference() =>
      _storage.read(
        key: _keyThemePreference,
      );

  Future<void> saveThemePreference(
    String preference,
  ) async {
    await _storage.write(
      key: _keyThemePreference,
      value: preference,
    );
  }

  // Language preference

  Future<String?> getLanguageCode() =>
      _storage.read(
        key: _keyLanguageCode,
      );

  Future<void> saveLanguageCode(
    String languageCode,
  ) async {
    await _storage.write(
      key: _keyLanguageCode,
      value: languageCode,
    );
  }

  // Notifications preference

  Future<bool> getNotificationsEnabled() async {
    final value = await _storage.read(
      key: _keyNotificationsEnabled,
    );

    if (value == null) {
      return true;
    }

    return value == 'true';
  }

  Future<void> saveNotificationsEnabled(
    bool enabled,
  ) async {
    await _storage.write(
      key: _keyNotificationsEnabled,
      value: enabled.toString(),
    );
  }

  /// Upload un fichier vers le backend
  ///
  /// [endpoint] : L'endpoint API (ex: '/events/upload')
  /// [file] : Le fichier à uploader
  /// [fieldName] : Le nom du champ dans le formulaire (défaut: 'file')
  /// Retourne la réponse décodée du serveur
  Future<dynamic> uploadFile(
    String endpoint, {
    required File file,
    String fieldName = 'file',
  }) async {
    final token = await getAccessToken();

    if (token == null) {
      throw Exception(
        'Utilisateur non authentifié',
      );
    }

    final uri = Uri.parse(
      '${_getBaseUrl()}$endpoint',
    );

    final request =
        http.MultipartRequest(
      'POST',
      uri,
    )
      ..headers['Authorization'] =
          'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath(
        fieldName,
        file.path,
      ),
    );

    final response =
        await request.send();

    final responseBody =
        await response.stream.bytesToString();

    final responseData =
        json.decode(responseBody);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return responseData;
    } else {
      final message =
          responseData is Map<String, dynamic>
              ? (responseData['detail'] ??
                  responseData['message'] ??
                  'Erreur lors de l\'upload')
              : 'Erreur lors de l\'upload';

      throw Exception(message);
    }
  }

  String _getBaseUrl() {
    // En développement, utilise l'IP locale
    // En production, utilise l'URL du serveur
    return ApiConfig.baseUrl;
  }
}
