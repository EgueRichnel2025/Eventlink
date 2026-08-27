import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../models/event_model.dart';

class FiltresSheet extends StatefulWidget {
  final CategorieEvent? categorieInitiale;
  final StatutPersonnel? statutInitial;

  const FiltresSheet({super.key, this.categorieInitiale, this.statutInitial});

  @override
  State<FiltresSheet> createState() => _FiltresSheetState();
}

class _FiltresSheetState extends State<FiltresSheet> {
  CategorieEvent? _categorie;
  StatutPersonnel? _statut;

  @override
  void initState() {
    super.initState();
    _categorie = widget.categorieInitiale;
    _statut = widget.statutInitial;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Filtrer les événements', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
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
                onSelected: (_) => setState(() => _categorie = selectionne ? null : c),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Statut', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: StatutPersonnel.values.map((s) {
              final selectionne = _statut == s;
              return ChoiceChip(
                label: Text('${s.emoji} ${s.label}'),
                selected: selectionne,
                onSelected: (_) => setState(() => _statut = selectionne ? null : s),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _categorie = null;
                    _statut = null;
                  }),
                  child: const Text('Réinitialiser'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop({'categorie': _categorie, 'statut': _statut}),
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
