import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/group_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_retry_view.dart';
import '../../widgets/group_card.dart';

class GroupesScreen extends StatefulWidget {
  const GroupesScreen({super.key});

  @override
  State<GroupesScreen> createState() => _GroupesScreenState();
}

class _GroupesScreenState extends State<GroupesScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GroupProvider>().chargerMesGroupes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/images/backgrounds/groups_background.jpeg',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Container(
              color: Colors.black.withValues(alpha: 0.05),
            ),
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    title: const Text('Mes groupes'),
                    floating: true,
                    snap: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.person_outline_rounded),
                        tooltip: 'Profil',
                        onPressed: () => Navigator.of(context).pushNamed(
                          AppRoutes.profile,
                        ),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Consumer<GroupProvider>(
                      builder: (context, provider, _) {
                        if (provider.isLoading &&
                            provider.groupes.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.lg),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (provider.errorMessage != null &&
                            provider.groupes.isEmpty) {
                          return ErrorRetryView(
                            message: provider.errorMessage!,
                            onRetry: () =>
                                provider.chargerMesGroupes(),
                          );
                        }

                        if (provider.groupes.isEmpty) {
                          return Padding(
                            padding:
                                const EdgeInsets.all(AppSpacing.lg),
                            child: EmptyState(
                              emoji: '👥',
                              titre: 'Aucun groupe pour l\'instant',
                              sousTitre:
                                  'Créez votre premier groupe ou rejoignez-en un avec un code d\'invitation.',
                              action: ElevatedButton.icon(
                                onPressed: () =>
                                    Navigator.of(context).pushNamed(
                                  AppRoutes.groupeChoice,
                                  arguments: true,
                                ),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text(
                                  'Ajouter / rejoindre un groupe',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                    vertical: AppSpacing.md,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: [
                            ListView.separated(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: provider.groupes.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(
                                height: AppSpacing.md,
                              ),
                              itemBuilder: (context, index) {
                                final groupe =
                                    provider.groupes[index];

                                return GroupCard(
                                  groupe: groupe,
                                  onTap: () {
                                    provider.ouvrirGroupe(groupe);
                                    Navigator.of(context).pushNamed(
                                      AppRoutes.eventList,
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Padding(
                              padding:
                                  const EdgeInsets.all(AppSpacing.lg),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      Navigator.of(context).pushNamed(
                                    AppRoutes.groupeChoice,
                                    arguments: true,
                                  ),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text(
                                    'Ajouter / rejoindre un groupe',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding:
                                        const EdgeInsets.symmetric(
                                      vertical: AppSpacing.lg,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}