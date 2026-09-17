import 'package:flutter/foundation.dart';

import '../models/stored_account.dart';
import '../models/user_model.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

enum AuthStatus {
  inconnu,
  nonConnecte,
  connecte,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;

  AuthProvider({
    AuthService? authService,
    StorageService? storageService,
  })  : _authService = authService ?? AuthService(),
        _storageService = storageService ?? StorageService();

  AuthStatus status = AuthStatus.inconnu;
  UserModel? currentUser;

  bool isLoading = false;
  String? errorMessage;

  List<StoredAccount> comptesConnus = [];

  bool get estConnecte =>
      status == AuthStatus.connecte &&
      currentUser != null;

  /// Nombre maximum de comptes pouvant être enregistrés
  /// sur un appareil.
  static const int maxComptes = 3;

  bool get peutAjouterCompte =>
      comptesConnus.length < maxComptes;

  /// Charge les comptes déjà connus sur l'appareil.
  Future<void> chargerComptesConnus() async {
    comptesConnus =
        await _storageService.getStoredAccounts();

    notifyListeners();
  }

  /// Appelé par le Splash : vérifie s'il existe une session locale valide.
  Future<void> verifierSessionAuDemarrage() async {
    final aSession =
        await _authService.aUneSessionLocale();

    if (!aSession) {
      status = AuthStatus.nonConnecte;

      await chargerComptesConnus();

      return;
    }

    try {
      currentUser =
          await _authService.monProfil();

      status = AuthStatus.connecte;

      await chargerComptesConnus();
    } on ApiException {
      // Session invalide/expirée et non rafraîchissable :
      // on supprime uniquement la session active.
      await _authService.deconnexion();

      currentUser = null;
      status = AuthStatus.nonConnecte;

      await chargerComptesConnus();
    }

    notifyListeners();
  }

  /// Vérifie si l'utilisateur possède déjà un profil.
  Future<bool> hasProfile() async {
    if (currentUser != null) {
      return true;
    }

    try {
      final user =
          await _authService.monProfil();

      currentUser = user;
      status = AuthStatus.connecte;

      await chargerComptesConnus();

      return true;
    } on ApiException {
      return false;
    }
  }

  /// Crée un nouveau profil et l'ajoute aux comptes connus.
  Future<bool> creerProfil({
    required String prenom,
    required String nom,
    required String email,
    required String password,
    String? avatarId,
  }) async {
    if (!peutAjouterCompte) {
      errorMessage =
          'Vous pouvez enregistrer au maximum 3 comptes sur cet appareil.';

      notifyListeners();

      return false;
    }

    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      currentUser =
          await _authService.creerProfil(
        prenom: prenom,
        nom: nom,
        email: email,
        password: password,
        avatarId: avatarId,
      );

      status = AuthStatus.connecte;

      await chargerComptesConnus();

      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;

      return false;
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }

  /// Connecte un compte déjà enregistré sur l'appareil
  /// avec son mot de passe.
  Future<bool> connecterCompte({
    required String userId,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      currentUser =
          await _authService.connecterCompte(
        userId: userId,
        password: password,
      );

      status = AuthStatus.connecte;

      await chargerComptesConnus();

      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;

      return false;
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }

  /// Recherche un compte avec son code EventLink.
  ///
  /// Cette opération ne connecte pas l'utilisateur.
  Future<UserModel?> trouverCompteAvecCode(
    String accountCode,
  ) async {
    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      return await _authService.trouverCompteAvecCode(
        accountCode,
      );
    } on ApiException catch (e) {
      errorMessage = e.message;

      return null;
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }

  /// Demande l'envoi du code de récupération.

  /// Connecte un compte avec son adresse email
  /// et son mot de passe.
  Future<bool> connecterAvecEmail({
    required String email,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      currentUser =
          await _authService.connecterAvecEmail(
        email: email,
        password: password,
      );

      status = AuthStatus.connecte;

      await chargerComptesConnus();

      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;

      return false;
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }

  Future<bool> demanderCodeRecuperation(
    String email,
  ) async {
    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      await _authService.demanderCodeRecuperation(
        email,
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

  /// Vérifie le code de récupération.
  ///
  /// Retourne le reset token si le code est valide.
  Future<String?> verifierCodeRecuperation({
    required String email,
    required String code,
  }) async {
    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      return await _authService.verifierCodeRecuperation(
        email: email,
        code: code,
      );
    } on ApiException catch (e) {
      errorMessage = e.message;

      return null;
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }

  /// Réinitialise le mot de passe.
  Future<bool> reinitialiserMotDePasse({
    required String resetToken,
    required String newPassword,
  }) async {
    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      currentUser =
          await _authService.reinitialiserMotDePasse(
        resetToken: resetToken,
        newPassword: newPassword,
      );

      status = AuthStatus.connecte;

      await chargerComptesConnus();

      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;

      return false;
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }

  Future<bool> modifierProfil({
    String? prenom,
    String? nom,
    String? photoUrl,
    String? avatarId,
  }) async {
    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      currentUser =
          await _authService.modifierProfil(
        prenom: prenom,
        nom: nom,
        photoUrl: photoUrl,
        avatarId: avatarId,
      );

      await chargerComptesConnus();

      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;

      return false;
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }

  /// Déconnecte uniquement la session active.
  ///
  /// Les autres comptes connus restent enregistrés
  /// sur l'appareil.
  Future<void> deconnexion() async {
    await _authService.deconnexion();

    currentUser = null;
    status = AuthStatus.nonConnecte;

    await chargerComptesConnus();

    notifyListeners();
  }
}