class GroupeModel {
  final String id;
  final String nom;
  final String? photoUrl;
  final String codeInvitation;
  final String ownerId;
  final DateTime createdAt;
  final int nombreMembres;
  final int nombreEvenements;
  final String? monRole; // "owner" | "admin" | "member"

  GroupeModel({
    required this.id,
    required this.nom,
    this.photoUrl,
    required this.codeInvitation,
    required this.ownerId,
    required this.createdAt,
    required this.nombreMembres,
    required this.nombreEvenements,
    this.monRole,
  });

  bool get estProprietaire => monRole == 'owner';
  bool get estAdmin => monRole == 'owner' || monRole == 'admin';

  factory GroupeModel.fromJson(Map<String, dynamic> json) {
    return GroupeModel(
      id: json['_id'] as String,
      nom: json['nom'] as String,
      photoUrl: json['photo_url'] as String?,
      codeInvitation: json['code_invitation'] as String,
      ownerId: json['owner_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      nombreMembres: json['nombre_membres'] as int? ?? 0,
      nombreEvenements: json['nombre_evenements'] as int? ?? 0,
      monRole: json['mon_role'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'nom': nom,
        'photo_url': photoUrl,
        'code_invitation': codeInvitation,
        'owner_id': ownerId,
        'created_at': createdAt.toIso8601String(),
        'nombre_membres': nombreMembres,
        'nombre_evenements': nombreEvenements,
        'mon_role': monRole,
      };

  GroupeModel copyWith({
    String? id,
    String? nom,
    String? photoUrl,
    String? codeInvitation,
    String? ownerId,
    DateTime? createdAt,
    int? nombreMembres,
    int? nombreEvenements,
    String? monRole,
  }) {
    return GroupeModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      photoUrl: photoUrl ?? this.photoUrl,
      codeInvitation: codeInvitation ?? this.codeInvitation,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      nombreMembres: nombreMembres ?? this.nombreMembres,
      nombreEvenements: nombreEvenements ?? this.nombreEvenements,
      monRole: monRole ?? this.monRole,
    );
  }
}

class MembreGroupeModel {
  final String userId;
  final String prenom;
  final String nom;
  final String? photoUrl;
  final String? avatarId;
  final String role;
  final DateTime joinedAt;

  MembreGroupeModel({
    required this.userId,
    required this.prenom,
    required this.nom,
    this.photoUrl,
    this.avatarId,
    required this.role,
    required this.joinedAt,
  });

  String get nomComplet => '$prenom $nom';

  factory MembreGroupeModel.fromJson(Map<String, dynamic> json) {
    return MembreGroupeModel(
      userId: json['user_id'] as String,
      prenom: json['prenom'] as String,
      nom: json['nom'] as String,
      photoUrl: json['photo_url'] as String?,
      avatarId: json['avatar_id'] as String?,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'prenom': prenom,
        'nom': nom,
        'photo_url': photoUrl,
        'avatar_id': avatarId,
        'role': role,
        'joined_at': joinedAt.toIso8601String(),
      };
}
