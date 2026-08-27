import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Empty state générique, réutilisé pour groupes/événements/commentaires/
/// notifications/recherche — jamais un simple texte "Aucun ...".
class EmptyState extends StatelessWidget {
  final String emoji;
  final String titre;
  final String sousTitre;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.emoji,
    required this.titre,
    required this.sousTitre,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              titre,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              sousTitre,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
