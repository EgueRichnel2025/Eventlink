class CommentMentionModel {
  final String userId;

  const CommentMentionModel({
    required this.userId,
  });

  factory CommentMentionModel.fromJson(Map<String, dynamic> json) {
    return CommentMentionModel(
      userId: json['user_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
      };
}

class CommentModel {
  final String id;

  final String eventId;

  final String userId;

  final String prenom;

  final String nom;

  final String? photoUrl;

  final String? avatarId;

  final String texte;

  final DateTime createdAt;

  final String? parentCommentId;

  final bool epingle;

  final List<CommentMentionModel> mentions;

  final Map<String, int> reactions;

  final String? userReaction;

  CommentModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.prenom,
    required this.nom,
    this.photoUrl,
    this.avatarId,
    required this.texte,
    required this.createdAt,
    this.parentCommentId,
    this.epingle = false,
    this.mentions = const [],
    this.reactions = const {},
    this.userReaction,
  });

  String get nomComplet => '$prenom $nom';

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final reactionsJson =
        json['reactions'] as Map<String, dynamic>? ?? {};

    final reactions = reactionsJson.map(
      (key, value) => MapEntry(
        key,
        (value as num).toInt(),
      ),
    );

    return CommentModel(
      id: json['_id'] as String,
      eventId: json['event_id'] as String,
      userId: json['user_id'] as String,
      prenom: json['prenom'] as String,
      nom: json['nom'] as String,
      photoUrl: json['photo_url'] as String?,
      avatarId: json['avatar_id'] as String?,
      texte: json['texte'] as String,
      createdAt: DateTime.parse(
        json['created_at'] as String,
      ),
      parentCommentId: json['parent_comment_id'] as String?,
      epingle: json['epingle'] as bool? ?? false,
      mentions: (json['mentions'] as List<dynamic>? ?? [])
          .map(
            (mention) => CommentMentionModel.fromJson(
              mention as Map<String, dynamic>,
            ),
          )
          .toList(),
      reactions: reactions,
      userReaction: json['user_reaction'] as String?,
    );
  }

  CommentModel copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? prenom,
    String? nom,
    String? photoUrl,
    String? avatarId,
    String? texte,
    DateTime? createdAt,
    String? parentCommentId,
    bool? epingle,
    List<CommentMentionModel>? mentions,
    Map<String, int>? reactions,
    String? userReaction,
    bool clearUserReaction = false,
  }) {
    return CommentModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      prenom: prenom ?? this.prenom,
      nom: nom ?? this.nom,
      photoUrl: photoUrl ?? this.photoUrl,
      avatarId: avatarId ?? this.avatarId,
      texte: texte ?? this.texte,
      createdAt: createdAt ?? this.createdAt,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      epingle: epingle ?? this.epingle,
      mentions: mentions ?? this.mentions,
      reactions: reactions ?? this.reactions,
      userReaction:
          clearUserReaction ? null : userReaction ?? this.userReaction,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'event_id': eventId,
        'user_id': userId,
        'prenom': prenom,
        'nom': nom,
        'photo_url': photoUrl,
        'avatar_id': avatarId,
        'texte': texte,
        'created_at': createdAt.toIso8601String(),
        'parent_comment_id': parentCommentId,
        'epingle': epingle,
        'mentions': mentions.map((mention) => mention.toJson()).toList(),
        'reactions': reactions,
        'user_reaction': userReaction,
      };
}
