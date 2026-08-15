// widget_test.dart
// Test de base généré par Flutter, adapté à notre app EventLinkApp.
//
// Pour l'instant ce test est un simple test de fumée (vérifie que
// l'app démarre sans planter). À enrichir plus tard avec de vrais
// tests une fois les écrans terminés.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eventlink/main.dart';

void main() {
  testWidgets('EventLinkApp se lance sans erreur', (WidgetTester tester) async {
    // Construit notre app et déclenche une frame.
    await tester.pumpWidget(const EventLinkApp());

    // TODO: une fois les écrans terminés, remplacer ce test basique
    // par de vrais tests (ex: vérifier que le bouton "Ajouter" est présent
    // sur l'écran liste, etc.)
  });
}