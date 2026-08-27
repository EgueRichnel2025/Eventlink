import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';
import 'storage_service.dart';

/// Centralise TOUS les appels HTTP vers le backend.
///
/// Gère : l'ajout automatique du token d'accès, le rafraîchissement
/// transparent en cas de 401, et la conversion des erreurs réseau/HTTP en
/// [ApiException] avec un message compréhensible pour l'utilisateur.
class ApiService {
  final StorageService _storage;
  final http.Client _client;

  ApiService({StorageService? storage, http.Client? client})
      : _storage = storage ?? StorageService(),
        _client = client ?? http.Client();

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleanQuery = query?.map((k, v) => MapEntry(k, v?.toString())) ?? {};
    cleanQuery.removeWhere((k, v) => v == null);
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: cleanQuery.isEmpty ? null : cleanQuery);
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _storage.getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ---------------------------------------------------------------------
  // Méthodes HTTP génériques, avec gestion d'erreurs et retry sur 401
  // ---------------------------------------------------------------------

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) {
    return _request('GET', path, query: query, auth: auth);
  }

  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? query, bool auth = true}) {
    return _request('POST', path, body: body, query: query, auth: auth);
  }

  Future<dynamic> put(String path, {Object? body, bool auth = true}) {
    return _request('PUT', path, body: body, auth: auth);
  }

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) {
    return _request('PATCH', path, body: body, auth: auth);
  }

  Future<dynamic> delete(String path, {bool auth = true}) {
    return _request('DELETE', path, auth: auth);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
    bool isRetry = false,
  }) async {
    final uri = _uri(path, query);
    final headers = await _headers(auth: auth);

    try {
      final http.Response response;
      final encodedBody = body != null ? jsonEncode(body) : null;

      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers).timeout(ApiConfig.timeout);
          break;
        case 'POST':
          response = await _client.post(uri, headers: headers, body: encodedBody).timeout(ApiConfig.timeout);
          break;
        case 'PUT':
          response = await _client.put(uri, headers: headers, body: encodedBody).timeout(ApiConfig.timeout);
          break;
        case 'PATCH':
          response = await _client.patch(uri, headers: headers, body: encodedBody).timeout(ApiConfig.timeout);
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: headers).timeout(ApiConfig.timeout);
          break;
        default:
          throw ApiException('Méthode HTTP non supportée');
      }

      return await _handleResponse(response, method, path, body: body, query: query, auth: auth, isRetry: isRetry);
    } on SocketException {
      throw ApiException('Impossible de joindre le serveur. Vérifiez votre connexion internet.');
    } on HttpException {
      throw ApiException('Le serveur est indisponible pour le moment. Réessayez plus tard.');
    } on FormatException {
      throw ApiException('Réponse du serveur invalide.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Une erreur de connexion est survenue. Réessayez.');
    }
  }

  Future<dynamic> _handleResponse(
    http.Response response,
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    required bool auth,
    required bool isRetry,
  }) async {
    if (response.statusCode == 401 && auth && !isRetry) {
      final renouvele = await _tryRefreshToken();
      if (renouvele) {
        return _request(method, path, body: body, query: query, auth: auth, isRetry: true);
      }
      throw ApiException('Votre session a expiré. Merci de vous reconnecter.', statusCode: 401);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    throw ApiException(_messagePourErreur(response), statusCode: response.statusCode);
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await _client
          .post(
            _uri('/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _storage.saveAccessToken(data['access_token'] as String);
        return true;
      }
    } catch (_) {
      // Silencieux : on retombe sur l'échec de rafraîchissement ci-dessous.
    }
    return false;
  }

  String _messagePourErreur(http.Response response) {
    switch (response.statusCode) {
      case 400:
        return _extraireDetail(response) ?? 'Requête invalide.';
      case 403:
        return _extraireDetail(response) ?? "Vous n'avez pas accès à cette ressource.";
      case 404:
        return _extraireDetail(response) ?? 'Ressource introuvable.';
      case 422:
        return 'Certaines informations saisies sont invalides.';
      case 500:
      case 502:
      case 503:
        return 'Le serveur rencontre un problème. Réessayez dans un instant.';
      default:
        return _extraireDetail(response) ?? 'Une erreur est survenue (${response.statusCode}).';
    }
  }

  String? _extraireDetail(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['detail'] is String) return data['detail'] as String;
    } catch (_) {}
    return null;
  }
}
