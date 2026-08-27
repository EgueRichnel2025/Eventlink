import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/groupe_model.dart';

class GroupCard extends StatelessWidget {
  final GroupeModel groupe;
  final VoidCallback onTap;

  const GroupCard({super.key, required this.groupe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  groupe.nom.isNotEmpty ? groupe.nom[0].toUpperCase() : '👥',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(groupe.nom, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                       const Icon(Icons.people_alt_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${groupe.nombreMembres} membre${groupe.nombreMembres > 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (groupe.nombreEvenements > 0) ...[
                          const SizedBox(width: AppSpacing.sm),
                          const Text('·', style: TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${groupe.nombreEvenements} événement${groupe.nombreEvenements > 1 ? 's' : ''}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
