import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';

enum AuthStatus { inconnu, nonConnecte, connecte }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider({AuthService? authService}) : _authService = authService ?? AuthService();

  AuthStatus status = AuthStatus.inconnu;
  UserModel? currentUser;
  bool isLoading = false;
  String? errorMessage;

  bool get estConnecte => status == AuthStatus.connecte && currentUser != null;

  /// Appelé par le Splash : vérifie s'il existe une session locale valide.
  Future<void> verifierSessionAuDemarrage() async {
    final aSession = await _authService.aUneSessionLocale();
    if (!aSession) {
      status = AuthStatus.nonConnecte;
      notifyListeners();
      return;
    }

    try {
      currentUser = await _authService.monProfil();
      status = AuthStatus.connecte;
    } on ApiException {
      // Session invalide/expirée et non rafraîchissable : on repart de zéro.
      await _authService.deconnexion();
      status = AuthStatus.nonConnecte;
    }
    notifyListeners();
  }

  /// Vérifie si l'utilisateur possède déjà un profil (prénom/nom)
  Future<bool> hasProfile() async {
    // Si nous avons déjà un utilisateur en mémoire, retourner true
    if (currentUser != null) {
      return true;
    }

    // Sinon, essayer de récupérer le profil depuis le service
    try {
      final user = await _authService.monProfil();
      currentUser = user;
      status = AuthStatus.connecte;
      notifyListeners();
      return true;
    } on ApiException {
      // Si une erreur se produit, l'utilisateur n'a pas de profil valide
      return false;
    }
  }

  Future<bool> creerProfil({required String prenom, required String nom, String? avatarId}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await _authService.creerProfil(
        prenom: prenom,
        nom: nom,
        avatarId: avatarId,
      );
      status = AuthStatus.connecte;
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> modifierProfil({String? prenom, String? nom, String? photoUrl, String? avatarId}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await _authService.modifierProfil(
        prenom: prenom,
        nom: nom,
        photoUrl: photoUrl,
        avatarId: avatarId,
      );
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deconnexion() async {
    await _authService.deconnexion();
    currentUser = null;
    status = AuthStatus.nonConnecte;
    notifyListeners();
  }
}
