class UserModel {
  final String id;
  final String prenom;
  final String nom;
  final String? photoUrl;
  final String? avatarId;
  final String accountCode;
  final String? email;

  UserModel({
    required this.id,
    required this.prenom,
    required this.nom,
    this.photoUrl,
    this.avatarId,
    required this.accountCode,
    this.email,
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
      accountCode: json['account_code'] as String,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'prenom': prenom,
        'nom': nom,
        'photo_url': photoUrl,
        'avatar_id': avatarId,
        'account_code': accountCode,
        'email': email,
      };

  UserModel copyWith({
    String? prenom,
    String? nom,
    String? photoUrl,
    String? avatarId,
    String? accountCode,
    String? email,
  }) {
    return UserModel(
      id: id,
      prenom: prenom ?? this.prenom,
      nom: nom ?? this.nom,
      photoUrl: photoUrl ?? this.photoUrl,
      avatarId: avatarId ?? this.avatarId,
      accountCode: accountCode ?? this.accountCode,
      email: email ?? this.email,
    );
  }
}
