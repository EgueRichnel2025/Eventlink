import 'package:flutter_test/flutter_test.dart';

import 'package:eventlink/models/event_model.dart';
import 'package:eventlink/models/groupe_model.dart';
import 'package:eventlink/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson/toJson round-trip', () {
      final json = {'_id': 'u1', 'prenom': 'Richnel', 'nom': 'EGUE', 'photo_url': null};
      final user = UserModel.fromJson(json);

      expect(user.id, 'u1');
      expect(user.nomComplet, 'Richnel EGUE');
      expect(user.initiales, 'RE');
      expect(user.toJson()['prenom'], 'Richnel');
    });
  });

  group('GroupeModel', () {
    test('calcule correctement les rôles', () {
      final json = {
        '_id': 'g1',
        'nom': 'Groupe INSPEI',
        'photo_url': null,
        'code_invitation': 'ABC123',
        'owner_id': 'u1',
        'created_at': '2026-01-01T10:00:00Z',
        'nombre_membres': 24,
        'nombre_evenements': 3,
        'mon_role': 'owner',
      };
      final groupe = GroupeModel.fromJson(json);

      expect(groupe.estProprietaire, true);
      expect(groupe.estAdmin, true);
      expect(groupe.nombreMembres, 24);
    });

    test('un simple membre n\'est pas admin', () {
      final json = {
        '_id': 'g1',
        'nom': 'Groupe INSPEI',
        'photo_url': null,
        'code_invitation': 'ABC123',
        'owner_id': 'u1',
        'created_at': '2026-01-01T10:00:00Z',
        'nombre_membres': 24,
        'nombre_evenements': 3,
        'mon_role': 'member',
      };
      final groupe = GroupeModel.fromJson(json);

      expect(groupe.estProprietaire, false);
      expect(groupe.estAdmin, false);
    });
  });

  group('CategorieEvent', () {
    test('fromString retombe sur "autre" si inconnu', () {
      expect(CategorieEvent.fromString('valeur_inexistante'), CategorieEvent.autre);
      expect(CategorieEvent.fromString('hackathon'), CategorieEvent.hackathon);
    });
  });

  group('StatutPersonnel', () {
    test('fromString gère null et valeurs valides', () {
      expect(StatutPersonnel.fromString(null), null);
      expect(StatutPersonnel.fromString('inscrit'), StatutPersonnel.inscrit);
      expect(StatutPersonnel.fromString('a_voir'), StatutPersonnel.aVoir);
    });
  });

  group('EventModel', () {
    test('fromJson construit correctement un événement complet', () {
      final json = {
        '_id': 'e1',
        'group_id': 'g1',
        'lien': 'https://example.com',
        'description': 'Un hackathon génial',
        'image_url': null,
        'categorie': 'hackathon',
        'auteur': {'user_id': 'u1', 'prenom': 'Richnel', 'nom': 'EGUE', 'photo_url': null},
        'created_at': '2026-01-01T10:00:00Z',
        'mon_statut': 'inscrit',
        'nombre_commentaires': 2,
      };
      final event = EventModel.fromJson(json);

      expect(event.categorie, CategorieEvent.hackathon);
      expect(event.monStatut, StatutPersonnel.inscrit);
      expect(event.auteur.nomComplet, 'Richnel EGUE');
    });

    test('copyWith met à jour uniquement le statut', () {
      final json = {
        '_id': 'e1',
        'group_id': 'g1',
        'lien': 'https://example.com',
        'description': 'Un hackathon génial',
        'image_url': null,
        'categorie': 'hackathon',
        'auteur': {'user_id': 'u1', 'prenom': 'Richnel', 'nom': 'EGUE', 'photo_url': null},
        'created_at': '2026-01-01T10:00:00Z',
        'mon_statut': null,
        'nombre_commentaires': 0,
      };
      final event = EventModel.fromJson(json);
      final misAJour = event.copyWith(monStatut: StatutPersonnel.passe);

      expect(misAJour.monStatut, StatutPersonnel.passe);
      expect(misAJour.id, event.id);
      expect(misAJour.description, event.description);
    });
  });
}
