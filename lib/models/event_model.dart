// event_model.dart
// Rôle : représenter un event côté app, avec ses commentaires.
// C'est le modèle le plus important du frontend.
//
// Responsable suggéré : Juste-Baudouin

class CommentaireModel {
  // TODO: définir les champs : userId, texte, date

  // TODO: ajouter les paramètres nommés une fois les champs définis ci-dessus
  // Exemple : CommentaireModel({required this.userId, required this.texte, required this.date});
  CommentaireModel();

  factory CommentaireModel.fromJson(Map<String, dynamic> json) {
    // TODO: construire l'objet depuis le JSON
    throw UnimplementedError();
  }
}

class EventModel {
  // TODO: définir les champs :
  // id, lien, description, imageUrl (nullable), ajoutePar, dateAjout,
  // statutMembres (Map<String, String>), commentaires (List<CommentaireModel>)

  // TODO: ajouter les paramètres nommés une fois les champs définis ci-dessus
  // Exemple : EventModel({required this.id, required this.lien, required this.description, ...});
  EventModel();

  factory EventModel.fromJson(Map<String, dynamic> json) {
    // TODO: construire l'objet depuis le JSON reçu du backend
    // Attention à bien parser la liste de commentaires avec
    // CommentaireModel.fromJson pour chaque élément
    throw UnimplementedError();
  }

  Map<String, dynamic> toJson() {
    // TODO: convertir l'objet en JSON pour l'envoyer au backend
    throw UnimplementedError();
  }
}