import 'package:flutter/foundation.dart';

import '../models/groupe_model.dart';
import '../services/api_exception.dart';
import '../services/group_service.dart';

class GroupProvider extends ChangeNotifier {
  final GroupService _groupService;

  GroupProvider({GroupService? groupService}) : _groupService = groupService ?? GroupService();

  List<GroupeModel> groupes = [];
  bool isLoading = false;
  String? errorMessage;

  /// Le groupe actuellement consulté (contexte de navigation uniquement —
  /// jamais un "groupe actif" permanent qui limiterait l'utilisateur).
  GroupeModel? groupeCourant;

  List<MembreGroupeModel> membresDuGroupeCourant = [];

  Future<void> chargerMesGroupes() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      groupes = await _groupService.mesGroupes();
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<GroupeModel?> creerGroupe(String nom) async {
    errorMessage = null;
    try {
      final groupe = await _groupService.creerGroupe(nom);
      groupes = [groupe, ...groupes];
      notifyListeners();
      return groupe;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<GroupeModel?> rejoindreGroupe(String code) async {
    errorMessage = null;
    try {
      final groupe = await _groupService.rejoindreGroupe(code);
      final dejaPresent = groupes.any((g) => g.id == groupe.id);
      if (!dejaPresent) {
        groupes = [groupe, ...groupes];
      }
      notifyListeners();
      return groupe;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }

  void ouvrirGroupe(GroupeModel groupe) {
    groupeCourant = groupe;
    membresDuGroupeCourant = [];
    notifyListeners();
  }

  Future<void> chargerMembresDuGroupeCourant() async {
    if (groupeCourant == null) return;
    try {
      membresDuGroupeCourant = await _groupService.lisMembres(groupeCourant!.id);
      notifyListeners();
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<bool> retirerMembre(String userId) async {
    if (groupeCourant == null) return false;
    try {
      await _groupService.retirerMembre(groupeCourant!.id, userId);
      membresDuGroupeCourant = membresDuGroupeCourant.where((m) => m.userId != userId).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
