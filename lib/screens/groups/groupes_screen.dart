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
  final TextEditingController _rechercheController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GroupProvider>().chargerMesGroupes();
    });
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  void _ouvrirProfil() {
    Navigator.of(context).pushNamed(
      AppRoutes.profile,
    );
  }

  void _ouvrirGroupeChoice() {
    Navigator.of(context).pushNamed(
      AppRoutes.groupeChoice,
      arguments: true,
    );
  }

  void _retour() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  List<dynamic> _filtrerGroupes(List<dynamic> groupes) {
    final recherche =
        _rechercheController.text.trim().toLowerCase();

    if (recherche.isEmpty) {
      return groupes;
    }

    return groupes.where((groupe) {
      return groupe.nom.toString().toLowerCase().contains(recherche);
    }).toList();
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
                    leading: Navigator.of(context).canPop()
                        ? IconButton(
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                            tooltip: 'Retour',
                            onPressed: _retour,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.black.withValues(alpha: 0.25),
                            ),
                          )
                        : null,
                    title: const Text(
                      'Mes groupes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    floating: true,
                    snap: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(
                          right: AppSpacing.sm,
                        ),
                        child: TextButton.icon(
                          onPressed: _ouvrirProfil,
                          icon: const Icon(
                            Icons.person_outline_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          label: const Text(
                            'Profil',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor:
                                Colors.black.withValues(alpha: 0.35),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.button,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Barre de recherche
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: TextField(
                        controller: _rechercheController,
                        onChanged: (_) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Rechercher un groupe...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.primary,
                          ),
                          suffixIcon:
                              _rechercheController.text.isNotEmpty
                                  ? IconButton(
                                      onPressed: () {
                                        _rechercheController.clear();
                                        setState(() {});
                                      },
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                      ),
                                      tooltip: 'Effacer',
                                    )
                                  : null,
                          filled: true,
                          fillColor: Colors.white.withValues(
                            alpha: 0.95,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.card,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.card,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.card,
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
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
                                onPressed: _ouvrirGroupeChoice,
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

                        final groupesFiltres =
                            _filtrerGroupes(provider.groupes);

                        if (groupesFiltres.isEmpty) {
                          return Padding(
                            padding:
                                const EdgeInsets.all(AppSpacing.lg),
                            child: EmptyState(
                              emoji: '🔍',
                              titre: 'Aucun groupe trouvé',
                              sousTitre:
                                  'Aucun groupe ne correspond à « ${_rechercheController.text.trim()} ». Essayez avec un autre mot-clé.',
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
                              itemCount: groupesFiltres.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(
                                height: AppSpacing.md,
                              ),
                              itemBuilder: (context, index) {
                                final groupe =
                                    groupesFiltres[index];

                                return GroupCard(
                                  groupe: groupe,
                                  index: index,
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
                                  onPressed: _ouvrirGroupeChoice,
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