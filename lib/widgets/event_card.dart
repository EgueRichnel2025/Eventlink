import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final ValueChanged<StatutPersonnel> onChangerStatut;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onChangerStatut,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatee = DateFormat('d MMM · HH:mm', 'fr_FR').format(event.createdAt.toLocal());

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CategorieChip(categorie: event.categorie),
                  const Spacer(),
                  Text(dateFormatee, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (event.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  child: Image.network(
                    event.imageUrl!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(
                event.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      event.auteur.prenom.isNotEmpty ? event.auteur.prenom[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.auteur.nomComplet,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  if (event.nombreCommentaires > 0) ...[
                    const Icon(Icons.mode_comment_outlined, size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${event.nombreCommentaires}', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  _StatutSelector(statutActuel: event.monStatut, onChanger: onChangerStatut),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorieChip extends StatelessWidget {
  final CategorieEvent categorie;
  const _CategorieChip({required this.categorie});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: categorie.couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        '${categorie.emoji} ${categorie.label}',
        style: TextStyle(color: categorie.couleur, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _StatutSelector extends StatelessWidget {
  final StatutPersonnel? statutActuel;
  final ValueChanged<StatutPersonnel> onChanger;

  const _StatutSelector({required this.statutActuel, required this.onChanger});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<StatutPersonnel>(
      onSelected: onChanger,
      itemBuilder: (context) => StatutPersonnel.values
          .map((s) => PopupMenuItem(value: s, child: Text('${s.emoji} ${s.label}')))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          statutActuel != null ? '${statutActuel!.emoji} ${statutActuel!.label}' : '👀 Statut',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
