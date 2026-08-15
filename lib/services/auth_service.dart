// auth_service.dart
// Rôle : gérer la connexion et la session utilisateur côté app.
//
// Responsable suggéré : Juste-Baudouin

class AuthService {
  Future<bool> login(String email, String motDePasse) async {
    // TODO:
    // - appeler le endpoint /login du backend via ApiService
    // - si succès, sauvegarder les infos utilisateur (localement)
    // - retourner true/false selon le résultat
    throw UnimplementedError();
  }

  Future<void> logout() async {
    // TODO:
    // - effacer les infos de session stockées localement
    throw UnimplementedError();
  }

  Future<bool> estConnecte() async {
    // TODO:
    // - vérifier si une session utilisateur existe déjà (au démarrage de l'app)
    // - retourner true/false
    throw UnimplementedError();
  }
}
