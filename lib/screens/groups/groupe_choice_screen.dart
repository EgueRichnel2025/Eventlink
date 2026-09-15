import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../routes/app_routes.dart';
import 'widgets/creer_groupe_sheet.dart';
import 'widgets/rejoindre_groupe_sheet.dart';

class GroupeChoiceScreen extends StatefulWidget {
  /// true si l'utilisateur arrive ici depuis GroupesScreen (bouton retour visible),
  /// false si c'est l'étape obligatoire après ProfilSetup (pas de retour possible).
  final bool depuisGroupesScreen;

  const GroupeChoiceScreen({
    super.key,
    this.depuisGroupesScreen = false,
  });

  @override
  State<GroupeChoiceScreen> createState() => _GroupeChoiceScreenState();
}

class _GroupeChoiceScreenState extends State<GroupeChoiceScreen> {
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (!widget.depuisGroupesScreen) {
      _checkIfHasGroups();
    }
  }

  Future<void> _checkIfHasGroups() async {
    final auth = context.read<AuthProvider>();
    final hasProfile = await auth.hasProfile();

    if (!mounted) return;

    if (hasProfile) {
      final groupProvider = context.read<GroupProvider>();

      await groupProvider.chargerMesGroupes();

      if (!mounted) return;

      if (groupProvider.groupes.isNotEmpty) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.groupesScreen,
        );
      }
    }
  }

  Future<void> _ouvrirCreerGroupe(BuildContext context) async {
    final groupeCree = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreerGroupeSheet(),
    );

    if (!context.mounted) return;

    if (groupeCree == true) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.groupesScreen,
      );
    }
  }

  Future<void> _ouvrirRejoindreGroupe(BuildContext context) async {
    final rejoint = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RejoindreGroupeSheet(),
    );

    if (!context.mounted) return;

    if (rejoint == true) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.groupesScreen,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/images/backgrounds/group_choice_background.jpeg',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Container(
              color: Colors.black.withValues(alpha: 0.1),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    if (widget.depuisGroupesScreen)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Retour',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Colors.black.withValues(alpha: 0.25),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                          ),
                        ),
                      ),

                    const Spacer(),

                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.primaryDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.groups_3_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    Text(
                      'Que souhaitez-vous faire ?',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'Créez un groupe pour votre communauté, ou rejoignez-en un avec un code d\'invitation.',
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () => _ouvrirCreerGroupe(context),
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                            ),
                            label: const Text('Créer un groupe'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () => _ouvrirRejoindreGroupe(context),
                            icon: const Icon(Icons.qr_code_rounded),
                            label: const Text('Rejoindre un groupe'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    if (widget.depuisGroupesScreen)
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Retour',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}