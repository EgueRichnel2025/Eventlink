class CommentModel {
  final String id;
  final String eventId;
  final String userId;
  final String prenom;
  final String nom;
  final String? photoUrl;
  final String texte;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.prenom,
    required this.nom,
    this.photoUrl,
    required this.texte,
    required this.createdAt,
  });

  String get nomComplet => '$prenom $nom';

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['_id'] as String,
      eventId: json['event_id'] as String,
      userId: json['user_id'] as String,
      prenom: json['prenom'] as String,
      nom: json['nom'] as String,
      photoUrl: json['photo_url'] as String?,
      texte: json['texte'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
