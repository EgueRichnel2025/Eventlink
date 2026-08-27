/// Configuration de connexion à l'API EventLink.
///
/// En développement local :
/// - Émulateur Android -> http://10.0.2.2:8000
/// - iOS simulator / web / desktop -> http://localhost:8000
/// - Appareil physique -> remplacer par l'IP locale de la machine hôte
///
/// En production, définir cette valeur via `--dart-define=API_BASE_URL=...`.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const Duration timeout = Duration(seconds: 15);
}
