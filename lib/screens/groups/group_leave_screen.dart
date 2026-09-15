import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/group_provider.dart';
import '../../routes/app_routes.dart';

class GroupLeaveScreen extends StatelessWidget {
  const GroupLeaveScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final groupe =
        context.watch<GroupProvider>().groupeCourant;

    final estProprietaire =
        groupe?.estProprietaire ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          tooltip: 'Retour',
        ),
        title: const Text(
          'Quitter le groupe',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(
          AppSpacing.lg,
        ),
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: 36,
            ),
          ),

          const SizedBox(
            height: AppSpacing.xl,
          ),

          const Text(
            'Quitter ce groupe ?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          Text(
            groupe == null
                ? 'Vous êtes sur le point de quitter ce groupe.'
                : 'Vous êtes sur le point de quitter « ${groupe.nom} ». '
                    'Vous ne pourrez plus accéder à ses événements et à ses membres.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),

          if (estProprietaire) ...[
            const SizedBox(
              height: AppSpacing.lg,
            ),
            Container(
              padding: const EdgeInsets.all(
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(
                  14,
                ),
              ),
              child: const Text(
                'Vous êtes le propriétaire de ce groupe. '
                'Le transfert de propriété doit être effectué '
                'avant de pouvoir le quitter.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],

          const SizedBox(
            height: AppSpacing.xl,
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: estProprietaire
                  ? null
                  : () {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'La fonction de sortie du groupe sera reliée au serveur.',
                          ),
                        ),
                      );
                    },
              icon: const Icon(
                Icons.logout_rounded,
              ),
              label: const Text(
                'Quitter le groupe',
              ),
            ),
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context)
                      .pushReplacementNamed(
                    AppRoutes.groupMembers,
                  );
                }
              },
              child: const Text(
                'Annuler',
              ),
            ),
          ),
        ],
      ),
    );
  }
}