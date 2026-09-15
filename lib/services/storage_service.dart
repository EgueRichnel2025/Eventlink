import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Stockage local sécurisé de la session (tokens) et préférences utilisateur.
///
/// Utilise flutter_secure_storage (Keychain/Keystore) pour les données sensibles
/// (tokens) et des préférences non sensibles.
class StorageService {
  final FlutterSecureStorage _storage;

  /// Creates a [StorageService] with an optional [FlutterSecureStorage] instance.
  /// If [storage] is null, a new FlutterSecureStorage instance will be created.
  StorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // Clés pour les tokens (sécurisé)
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';

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

  Future<void> saveAccessToken(String accessToken) async {
    await _storage.write(
      key: _keyAccessToken,
      value: accessToken,
    );
  }

  Future<String?> getAccessToken() =>
      _storage.read(key: _keyAccessToken);

  Future<String?> getRefreshToken() =>
      _storage.read(key: _keyRefreshToken);

  Future<void> clear() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
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
      _storage.read(key: _keyThemePreference);

  Future<void> saveThemePreference(String preference) async {
    await _storage.write(
      key: _keyThemePreference,
      value: preference,
    );
  }

  // Language preference
  Future<String?> getLanguageCode() =>
      _storage.read(key: _keyLanguageCode);

  Future<void> saveLanguageCode(String languageCode) async {
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

  Future<void> saveNotificationsEnabled(bool enabled) async {
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
      throw Exception('Utilisateur non authentifié');
    }

    final uri = Uri.parse('${_getBaseUrl()}$endpoint');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath(
        fieldName,
        file.path,
      ),
    );

    final response = await request.send();
    final responseBody =
        await response.stream.bytesToString();
    final responseData = json.decode(responseBody);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return responseData;
    } else {
      final message = responseData is Map<String, dynamic>
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