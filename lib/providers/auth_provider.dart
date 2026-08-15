// auth_provider.dart
// Rôle : garder en mémoire l'état de connexion de l'utilisateur,
// accessible depuis n'importe quel écran de l'app.
//
// Responsable suggéré : Juste-Baudouin

import 'package:flutter/foundation.dart';
// TODO: importer UserModel une fois que ses champs sont complétés

class AuthProvider extends ChangeNotifier {
  // TODO: ajouter une variable pour stocker l'utilisateur connecté (nullable)

  bool get estConnecte {
    // TODO: retourner true si un utilisateur est bien stocké
    throw UnimplementedError();
  }

  Future<void> connecter(String email, String motDePasse) async {
    // TODO:
    // - appeler AuthService.login()
    // - si succès, stocker l'utilisateur
    // - appeler notifyListeners() pour prévenir les écrans du changement
    throw UnimplementedError();
  }

  Future<void> deconnecter() async {
    // TODO:
    // - appeler AuthService.logout()
    // - vider l'utilisateur stocké
    // - appeler notifyListeners()
    throw UnimplementedError();
  }
}
