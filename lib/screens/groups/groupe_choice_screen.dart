import 'package:flutter/material.dart';

import '../../config/theme.dart';
import 'widgets/creer_groupe_sheet.dart';
import 'widgets/rejoindre_groupe_sheet.dart';

class GroupeChoiceScreen extends StatelessWidget {
  /// true si l'utilisateur arrive ici depuis GroupesScreen (bouton retour visible),
  /// false si c'est l'étape obligatoire après ProfilSetup (pas de retour possible).
  final bool depuisGroupesScreen;

  const GroupeChoiceScreen({super.key, this.depuisGroupesScreen = false});

  Future<void> _ouvrirCreerGroupe(BuildContext context) async {
    final groupeCree = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreerGroupeSheet(),
    );
    if (groupeCree == true && context.mounted) {
      Navigator.of(context).pushReplacementNamed('/groupes');
    }
  }

  Future<void> _ouvrirRejoindreGroupe(BuildContext context) async {
    final rejoint = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RejoindreGroupeSheet(),
    );
    if (rejoint == true && context.mounted) {
      Navigator.of(context).pushReplacementNamed('/groupes');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: depuisGroupesScreen ? AppBar(title: const Text('Ajouter un groupe')) : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.groups_2_rounded, color: AppColors.primary, size: 56),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Que souhaitez-vous faire ?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Créez un groupe pour votre communauté, ou rejoignez-en un avec un code d\'invitation.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: () => _ouvrirCreerGroupe(context),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Créer un groupe'),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => _ouvrirRejoindreGroupe(context),
                icon: const Icon(Icons.qr_code_rounded),
                label: const Text('Rejoindre un groupe'),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
