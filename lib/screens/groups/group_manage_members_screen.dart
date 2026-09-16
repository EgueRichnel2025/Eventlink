import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/group_provider.dart';


class GroupManageMembersScreen extends StatefulWidget {
  const GroupManageMembersScreen({
    super.key,
  });

  @override
  State<GroupManageMembersScreen> createState() =>
      _GroupManageMembersScreenState();
}

class _GroupManageMembersScreenState
    extends State<GroupManageMembersScreen> {
  final TextEditingController _rechercheController =
      TextEditingController();

  bool _rechercheOuverte = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chargerMembres();
    });
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _chargerMembres() async {
    final provider = context.read<GroupProvider>();

    await provider.chargerMembresDuGroupeCourant(
      recherche: _rechercheController.text.trim(),
    );
  }

  Future<void> _rechercher(String value) async {
    final provider = context.read<GroupProvider>();

    provider.definirRechercheMembres(
      value,
    );

    await provider.chargerMembresDuGroupeCourant(
      recherche: value.trim(),
    );
  }

  Future<void> _retirerMembre(
    String userId,
    String nomComplet,
  ) async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Retirer le membre',
          ),
          content: Text(
            'Voulez-vous vraiment retirer $nomComplet du groupe ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text(
                'Annuler',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text(
                'Retirer',
              ),
            ),
          ],
        );
      },
    );

    if (confirmer != true || !mounted) {
      return;
    }

    final provider = context.read<GroupProvider>();

    try {
      await provider.retirerMembre(
        userId,
      );

      await _chargerMembres();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Membre retiré du groupe',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur : $e',
          ),
        ),
      );
    }
  }

  Widget _avatar(
    String prenom,
    String nom,
    String? photoUrl,
  ) {
    final initiales =
        '${prenom.isNotEmpty ? prenom[0] : ''}'
        '${nom.isNotEmpty ? nom[0] : ''}'
            .toUpperCase();

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(
          photoUrl,
        ),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primarySurface,
      child: Text(
        initiales,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _roleBadge(String role) {
    String texte;
    IconData icon;

    switch (role) {
      case 'owner':
        texte = 'Propriétaire';
        icon = Icons.workspace_premium_rounded;
        break;

      case 'admin':
        texte = 'Administrateur';
        icon = Icons.admin_panel_settings_rounded;
        break;

      default:
        texte = 'Membre';
        icon = Icons.person_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: 5),
          Text(
            texte,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GroupProvider>();

    final membres =
        provider.membresDuGroupeCourant;

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
          'Gérer les membres',
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _rechercheOuverte =
                    !_rechercheOuverte;

                if (!_rechercheOuverte) {
                  _rechercheController.clear();
                  _rechercher('');
                }
              });
            },
            icon: Icon(
              _rechercheOuverte
                  ? Icons.close_rounded
                  : Icons.search_rounded,
            ),
            tooltip: _rechercheOuverte
                ? 'Fermer la recherche'
                : 'Rechercher',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_rechercheOuverte)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: TextField(
                controller: _rechercheController,
                autofocus: true,
                onChanged: _rechercher,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Rechercher un membre...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _rechercheController.clear();
                      _rechercher('');
                    },
                    icon: const Icon(
                      Icons.clear_rounded,
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _chargerMembres,
              child: membres.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(
                          height: 140,
                        ),
                        Center(
                          child: Text(
                            'Aucun membre trouvé.',
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(
                        AppSpacing.md,
                      ),
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      itemCount: membres.length,
                      separatorBuilder:
                          (_, __) => const SizedBox(
                        height: AppSpacing.sm,
                      ),
                      itemBuilder: (
                        context,
                        index,
                      ) {
                        final membre =
                            membres[index];

                        final groupe =
                            provider.groupeCourant;

                        final peutRetirer =
                            groupe != null &&
                            (
                              (groupe.estProprietaire &&
                                  membre.role != 'owner') ||
                              (groupe.monRole == 'admin' &&
                                  membre.role == 'member')
                            );

                        return Card(
                          margin: EdgeInsets.zero,
                          elevation: 1,
                          color: Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.all(
                              AppSpacing.md,
                            ),
                            child: Row(
                              children: [
                                _avatar(
                                  membre.prenom,
                                  membre.nom,
                                  membre.photoUrl,
                                ),
                                const SizedBox(
                                  width: AppSpacing.md,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        membre.nomComplet,
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow
                                                .ellipsis,
                                        style:
                                            const TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                              FontWeight.w700,
                                          color:
                                              AppColors
                                                  .textPrimary,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 6,
                                      ),
                                      _roleBadge(
                                        membre.role,
                                      ),
                                    ],
                                  ),
                                ),
                                if (peutRetirer)
                                  IconButton(
                                    onPressed: () =>
                                        _retirerMembre(
                                      membre.userId,
                                      membre.nomComplet,
                                    ),
                                    icon:
                                        const Icon(
                                      Icons
                                          .person_remove_rounded,
                                      color:
                                          AppColors.error,
                                    ),
                                    tooltip:
                                        'Retirer du groupe',
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}