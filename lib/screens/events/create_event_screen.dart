import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../providers/group_provider.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lienController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  CategorieEvent _categorie = CategorieEvent.autre;
  bool _enCours = false;

  @override
  void dispose() {
    _lienController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _publier() async {
    if (!_formKey.currentState!.validate()) return;

    final groupId = context.read<GroupProvider>().groupeCourant?.id;
    if (groupId == null) return;

    setState(() => _enCours = true);
    final events = context.read<EventProvider>();
    final succes = await events.creerEvent(
      groupId: groupId,
      lien: _lienController.text.trim(),
      description: _descriptionController.text.trim(),
      imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      categorie: _categorie,
    );
    setState(() => _enCours = false);

    if (!mounted) return;

    if (succes) {
      Navigator.of(context).pop();
    } else if (events.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(events.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un événement')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text('Catégorie', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CategorieEvent.values.map((c) {
                  final selectionne = _categorie == c;
                  return ChoiceChip(
                    label: Text('${c.emoji} ${c.label}'),
                    selected: selectionne,
                    onSelected: (_) => setState(() => _categorie = c),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _lienController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'Lien', hintText: 'https://...'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Le lien est obligatoire';
                  final uri = Uri.tryParse(v.trim());
                  if (uri == null || !uri.hasScheme) return 'Lien invalide (doit commencer par http/https)';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'De quoi s\'agit-il ? Pourquoi est-ce intéressant ?',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'La description est obligatoire' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _imageUrlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Image (optionnel)',
                  hintText: 'URL d\'une image',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _enCours ? null : _publier,
                child: _enCours
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Publier'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
