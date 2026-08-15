// add_link_screen.dart
// Rôle : formulaire d'ajout d'un event : lien + description + image
// optionnelle. C'est l'écran déclenché par le bouton "Ajouter".
//
// Responsable suggéré : Juste-Baudouin

import 'package:flutter/material.dart';

class AddLinkScreen extends StatefulWidget {
  const AddLinkScreen({super.key});

  @override
  State<AddLinkScreen> createState() => _AddLinkScreenState();
}

class _AddLinkScreenState extends State<AddLinkScreen> {
  // TODO: ajouter des TextEditingController pour lien et description
  // TODO: ajouter une variable pour stocker l'image sélectionnée (nullable)

  void _choisirImage() {
    // TODO:
    // - utiliser image_picker pour sélectionner une image depuis la galerie
    // - stocker le fichier choisi dans la variable d'état
  }

  void _valider() {
    // TODO:
    // - vérifier que lien et description sont bien remplis (champs obligatoires)
    // - si une image est choisie, l'uploader d'abord pour obtenir une URL
    // - appeler EventProvider.ajouterEvent(lien, description, imageUrl)
    // - si succès, revenir à l'écran précédent (EventListScreen)
  }

  @override
  Widget build(BuildContext context) {
    // TODO: construire le formulaire :
    // - champ texte pour le lien
    // - champ texte (multiligne) pour la description
    // - bouton pour choisir une image + aperçu si sélectionnée
    // - bouton "Valider"
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter un event")),
      body: const Center(child: Text("TODO: formulaire lien/description/image")),
    );
  }
}
