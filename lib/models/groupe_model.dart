// groupe_model.dart
// Rôle : représenter un groupe côté app.
//
// Responsable suggéré : Juste-Baudouin

class GroupeModel {
  // TODO: définir les champs : id, nom, codeInvitation, membres (List<String>)

  // TODO: ajouter les paramètres nommés une fois les champs définis ci-dessus
  // Exemple : GroupeModel({required this.id, required this.nom, required this.codeInvitation});
  GroupeModel();

  factory GroupeModel.fromJson(Map<String, dynamic> json) {
    // TODO: construire l'objet depuis le JSON reçu du backend
    throw UnimplementedError();
  }

  Map<String, dynamic> toJson() {
    // TODO: convertir l'objet en JSON
    throw UnimplementedError();
  }
}