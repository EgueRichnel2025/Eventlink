import 'package:flutter/material.dart';

import '../config/theme.dart';

enum CategorieEvent {
  formation,
  opportunite,
  hackathon,
  bourse,
  evenement,
  ressource,
  autre;

  static CategorieEvent fromString(String value) {
    return CategorieEvent.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CategorieEvent.autre,
    );
  }

  String get label {
    switch (this) {
      case CategorieEvent.formation:
        return 'Formation';
      case CategorieEvent.opportunite:
        return 'Opportunité';
      case CategorieEvent.hackathon:
        return 'Hackathon';
      case CategorieEvent.bourse:
        return 'Bourse';
      case CategorieEvent.evenement:
        return 'Événement';
      case CategorieEvent.ressource:
        return 'Ressource';
      case CategorieEvent.autre:
        return 'Autre';
    }
  }

  String get emoji {
    switch (this) {
      case CategorieEvent.formation:
        return '🎓';
      case CategorieEvent.opportunite:
        return '💼';
      case CategorieEvent.hackathon:
        return '🏆';
      case CategorieEvent.bourse:
        return '💰';
      case CategorieEvent.evenement:
        return '🎉';
      case CategorieEvent.ressource:
        return '📚';
      case CategorieEvent.autre:
        return '🌐';
    }
  }

  Color get couleur {
    switch (this) {
      case CategorieEvent.formation:
        return AppColors.catFormation;
      case CategorieEvent.opportunite:
        return AppColors.catOpportunite;
      case CategorieEvent.hackathon:
        return AppColors.catHackathon;
      case CategorieEvent.bourse:
        return AppColors.catBourse;
      case CategorieEvent.evenement:
        return AppColors.catEvenement;
      case CategorieEvent.ressource:
        return AppColors.catRessource;
      case CategorieEvent.autre:
        return AppColors.catAutre;
    }
  }
}

enum StatutPersonnel {
  aVoir,
  inscrit,
  passe;

  static StatutPersonnel? fromString(String? value) {
    switch (value) {
      case 'a_voir':
        return StatutPersonnel.aVoir;
      case 'inscrit':
        return StatutPersonnel.inscrit;
      case 'passe':
        return StatutPersonnel.passe;
      default:
        return null;
    }
  }

  String get apiValue {
    switch (this) {
      case StatutPersonnel.aVoir:
        return 'a_voir';
      case StatutPersonnel.inscrit:
        return 'inscrit';
      case StatutPersonnel.passe:
        return 'passe';
    }
  }

  String get label {
    switch (this) {
      case StatutPersonnel.aVoir:
        return 'À voir';
      case StatutPersonnel.inscrit:
        return 'Inscrit';
      case StatutPersonnel.passe:
        return 'Passé';
    }
  }

  String get emoji {
    switch (this) {
      case StatutPersonnel.aVoir:
        return '👀';
      case StatutPersonnel.inscrit:
        return '📝';
      case StatutPersonnel.passe:
        return '✅';
    }
  }
}

class AuteurEvent {
  final String userId;
  final String prenom;
  final String nom;
  final String? photoUrl;

  AuteurEvent({required this.userId, required this.prenom, required this.nom, this.photoUrl});

  String get nomComplet => '$prenom $nom';

  factory AuteurEvent.fromJson(Map<String, dynamic> json) {
    return AuteurEvent(
      userId: json['user_id'] as String,
      prenom: json['prenom'] as String,
      nom: json['nom'] as String,
      photoUrl: json['photo_url'] as String?,
    );
  }
}

class EventModel {
  final String id;
  final String groupId;
  final String lien;
  final String description;
  final String? imageUrl;
  final CategorieEvent categorie;
  final AuteurEvent auteur;
  final DateTime createdAt;
  final StatutPersonnel? monStatut;
  final int nombreCommentaires;

  EventModel({
    required this.id,
    required this.groupId,
    required this.lien,
    required this.description,
    this.imageUrl,
    required this.categorie,
    required this.auteur,
    required this.createdAt,
    this.monStatut,
    required this.nombreCommentaires,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['_id'] as String,
      groupId: json['group_id'] as String,
      lien: json['lien'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String?,
      categorie: CategorieEvent.fromString(json['categorie'] as String),
      auteur: AuteurEvent.fromJson(json['auteur'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      monStatut: StatutPersonnel.fromString(json['mon_statut'] as String?),
      nombreCommentaires: json['nombre_commentaires'] as int? ?? 0,
    );
  }

  EventModel copyWith({StatutPersonnel? monStatut}) {
    return EventModel(
      id: id,
      groupId: groupId,
      lien: lien,
      description: description,
      imageUrl: imageUrl,
      categorie: categorie,
      auteur: auteur,
      createdAt: createdAt,
      monStatut: monStatut ?? this.monStatut,
      nombreCommentaires: nombreCommentaires,
    );
  }
}
