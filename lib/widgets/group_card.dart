import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/groupe_model.dart';

class GroupCard extends StatelessWidget {
  final GroupeModel groupe;
  final VoidCallback onTap;
  final int index;

  const GroupCard({
    super.key,
    required this.groupe,
    required this.onTap,
    required this.index,
  });

  static const List<Color> _couleursGroupes = [
    AppColors.primary,
    AppColors.primaryDark,
    Color(0xFFFFA726),
    Color(0xFFFF8A65),
    Color(0xFFFFB74D),
    Color(0xFFFF7043),
  ];

  @override
  Widget build(BuildContext context) {
    final couleur = _couleursGroupes[index % _couleursGroupes.length];

    final couleurFond = couleur.withValues(alpha: 0.10);

    return Card(
      elevation: 2,
      shadowColor: couleur.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: couleur.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Avatar du groupe
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: couleurFond,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: couleur.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  groupe.nom.isNotEmpty
                      ? groupe.nom[0].toUpperCase()
                      : '👥',
                  style: TextStyle(
                    color: couleur,
                    fontWeight: FontWeight.w800,
                    fontSize: 21,
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Informations du groupe
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom complet du groupe
                    Text(
                      groupe.nom,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),

                    const SizedBox(height: 6),

                    // Membres + événements
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_alt_rounded,
                              size: 15,
                              color: couleur,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${groupe.nombreMembres} membre${groupe.nombreMembres > 1 ? 's' : ''}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),

                        if (groupe.nombreEvenements > 0) ...[
                          const Text(
                            '·',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_rounded,
                                size: 15,
                                color: couleur,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${groupe.nombreEvenements} événement${groupe.nombreEvenements > 1 ? 's' : ''}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // Flèche
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: couleur,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}