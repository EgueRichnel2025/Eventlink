// user_model.dart
// Rôle : représenter un utilisateur côté app, avec la conversion
// depuis/vers le JSON reçu du backend.
//
// Responsable suggéré : Juste-Baudouin

class UserModel {
  // TODO: définir les champs (miroir du backend) : id, nom, email

  // TODO: ajouter les paramètres nommés une fois les champs définis ci-dessus
  // Exemple : UserModel({required this.id, required this.nom, required this.email});
  UserModel();

  // Convertit un JSON reçu du backend en objet UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // TODO: lire chaque champ depuis json["..."] et construire l'objet
    throw UnimplementedError();
  }

  // Convertit l'objet en JSON pour l'envoyer au backend
  Map<String, dynamic> toJson() {
    // TODO: retourner un Map avec les champs de l'objet
    throw UnimplementedError();
  }
}