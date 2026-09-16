import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/group_provider.dart';
import '../../services/group_service.dart';

class GroupAdministratorsScreen
    extends StatefulWidget {
  const GroupAdministratorsScreen({
    super.key,
  });

  @override
  State<GroupAdministratorsScreen> createState() =>
      _GroupAdministratorsScreenState();
}

class _GroupAdministratorsScreenState
    extends State<GroupAdministratorsScreen> {
  bool _promotionEnCours = false;
  bool _demotionEnCours = false;

  String? _adminAPromouvoirId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<GroupProvider>()
          .chargerMembresDuGroupeCourant();
    });
  }

  Future<void> _promouvoirAdmin(
    String userId,
  ) async {
    final provider = context.read<GroupProvider>();
    final groupe = provider.groupeCourant;

    if (groupe == null) return;

    setState(() {
      _promotionEnCours = true;
    });

    try {
      await GroupService().promouvoirAdmin(
        groupe.id,
        userId,
      );

      await provider.chargerMembresDuGroupeCourant();

      if (!mounted) return;

      setState(() {
        _adminAPromouvoirId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Administrateur promu avec succès',
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
    } finally {
      if (mounted) {
        setState(() {
          _promotionEnCours = false;
        });
      }
    }
  }

  Future<void> _retrocederAdmin(
    String userId,
  ) async {
    final provider = context.read<GroupProvider>();
    final groupe = provider.groupeCourant;

    if (groupe == null) return;

    setState(() {
      _demotionEnCours = true;
    });

    try {
      await GroupService().retrocederAdmin(
        groupe.id,
        userId,
      );

      await provider.chargerMembresDuGroupeCourant();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Administrateur rétrogradé avec succès',
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
    } finally {
      if (mounted) {
        setState(() {
          _demotionEnCours = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GroupProvider>();
    final groupe = provider.groupeCourant;

    if (groupe == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () =>
                Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
          ),
          title: const Text(
            'Administrateurs',
          ),
        ),
        body: const Center(
          child: Text(
            'Groupe introuvable',
          ),
        ),
      );
    }

    final membres =
        provider.membresDuGroupeCourant;

    final administrateurs = membres
        .where((m) => m.role == 'admin')
        .toList();

    final membresSimples = membres
        .where((m) => m.role == 'member')
        .toList();

    final estProprietaire =
        groupe.estProprietaire;

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
          'Administrateurs',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(
          AppSpacing.lg,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(
                16,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppColors.primaryDark,
                  size: 28,
                ),
                SizedBox(
                  width: AppSpacing.md,
                ),
                Expanded(
                  child: Text(
                    'Les administrateurs peuvent participer à la gestion du groupe.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: AppSpacing.xl,
          ),

          const Text(
            'Administrateurs actuels',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          if (administrateurs.isEmpty)
            const Text(
              'Aucun administrateur supplémentaire.',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...administrateurs.map(
              (membre) => Card(
                margin: const EdgeInsets.only(
                  bottom: AppSpacing.sm,
                ),
                color: Colors.white,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor:
                        AppColors.primarySurface,
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  title: Text(
                    membre.nomComplet,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'Administrateur',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: estProprietaire
                      ? IconButton(
                          onPressed:
                              _demotionEnCours
                                  ? null
                                  : () =>
                                      _retrocederAdmin(
                                        membre.userId,
                                      ),
                          icon: const Icon(
                            Icons
                                .remove_moderator_rounded,
                            color: AppColors.error,
                          ),
                          tooltip:
                              'Rétrograder',
                        )
                      : null,
                ),
              ),
            ),

          if (estProprietaire &&
              membresSimples.isNotEmpty) ...[
            const SizedBox(
              height: AppSpacing.xl,
            ),
            const Text(
              'Promouvoir un membre',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(
              height: AppSpacing.md,
            ),
            DropdownButtonFormField<String>(
              initialValue:
                  _adminAPromouvoirId,
              decoration:
                  const InputDecoration(
                labelText:
                    'Sélectionner un membre',
                border:
                    OutlineInputBorder(),
              ),
              items: membresSimples
                  .map(
                    (membre) =>
                        DropdownMenuItem<String>(
                      value: membre.userId,
                      child: Text(
                        membre.nomComplet,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _promotionEnCours
                  ? null
                  : (value) {
                      setState(() {
                        _adminAPromouvoirId =
                            value;
                      });
                    },
            ),
            const SizedBox(
              height: AppSpacing.md,
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _promotionEnCours ||
                            _adminAPromouvoirId ==
                                null
                        ? null
                        : () =>
                            _promouvoirAdmin(
                              _adminAPromouvoirId!,
                            ),
                icon: _promotionEnCours
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons
                            .add_moderator_rounded,
                      ),
                label: const Text(
                  'Promouvoir administrateur',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
