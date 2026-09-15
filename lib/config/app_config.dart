/// Configuration temporaire de l'application.
///
/// Les options ici permettent d'activer certains comportements de démonstration
/// sans modifier le fonctionnement normal d'EventLink.
class AppConfig {
  AppConfig._();

  /// Lorsque true, l'onboarding est affiché à chaque démarrage
  /// afin de faciliter les démonstrations.
  ///
  /// Remettre à false après la démonstration.
  static const bool demoOnboarding = false;
}