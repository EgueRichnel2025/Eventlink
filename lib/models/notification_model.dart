class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String titre;
  final String corps;
  final Map<String, dynamic> data;
  final bool lu;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.titre,
    required this.corps,
    required this.data,
    required this.lu,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      titre: json['titre'] as String,
      corps: json['corps'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      lu: json['lu'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
