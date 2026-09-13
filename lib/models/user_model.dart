class UserModel {
  final String id;
  final String prenom;
  final String nom;
  final String? photoUrl;
  final String? avatarId;

  UserModel({
    required this.id,
    required this.prenom,
    required this.nom,
    this.photoUrl,
    this.avatarId,
  });

  String get nomComplet => '$prenom $nom';

  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    return '$p$n'.toUpperCase();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String,
      prenom: json['prenom'] as String,
      nom: json['nom'] as String,
      photoUrl: json['photo_url'] as String?,
      avatarId: json['avatar_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'prenom': prenom,
        'nom': nom,
        'photo_url': photoUrl,
        'avatar_id': avatarId,
      };

  UserModel copyWith({
    String? prenom,
    String? nom,
    String? photoUrl,
    String? avatarId,
  }) {
    return UserModel(
      id: id,
      prenom: prenom ?? this.prenom,
      nom: nom ?? this.nom,
      photoUrl: photoUrl ?? this.photoUrl,
      avatarId: avatarId ?? this.avatarId,
    );
  }
}