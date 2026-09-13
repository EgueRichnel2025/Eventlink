import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/error_retry_view.dart';

class GroupMembersScreen extends StatefulWidget {
  const GroupMembersScreen({super.key});

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  final _rechercheController = TextEditingController();
  bool _rechercheOuverte = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GroupProvider>().chargerMembresDuGroupeCourant();
    });
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _retirer(
    BuildContext context,
    String userId,
    String nom,
  ) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer ce membre ?'),
        content: Text(
          '$nom ne pourra plus voir les événements de ce groupe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirme != true || !context.mounted) return;

    final groupProvider = context.read<GroupProvider>();

    await groupProvider.retirerMembre(userId);

    if (!context.mounted) return;

    await groupProvider.chargerMembresDuGroupeCourant();
  }

  @override
  Widget build(BuildContext context) {
    final groupe = context.watch<GroupProvider>().groupeCourant;
    final moi = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: _rechercheOuverte
            ? TextField(
                controller: _rechercheController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un membre...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  final provider = context.read<GroupProvider>();
                  provider.definirRechercheMembres(value);
                  provider.chargerMembresDuGroupeCourant();
                },
              )
            : const Text('Membres'),
        actions: [
          IconButton(
            icon: Icon(
              _rechercheOuverte
                  ? Icons.close_rounded
                  : Icons.search_rounded,
            ),
            onPressed: () {
              setState(() {
                _rechercheOuverte = !_rechercheOuverte;

                if (!_rechercheOuverte) {
                  _rechercheController.clear();

                  final provider = context.read<GroupProvider>();
                  provider.definirRechercheMembres('');
                  provider.chargerMembresDuGroupeCourant();
                }
              });
            },
          ),
          if (groupe?.estAdmin == true)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(context).pushNamed(
                AppRoutes.groupSettings,
              ),
            ),
        ],
      ),
      body: Consumer<GroupProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading &&
              provider.membresDuGroupeCourant.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.errorMessage != null &&
              provider.membresDuGroupeCourant.isEmpty) {
            return ErrorRetryView(
              message: provider.errorMessage!,
              onRetry: provider.chargerMembresDuGroupeCourant,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: provider.membresDuGroupeCourant.length,
            separatorBuilder: (_, __) => const SizedBox(
              height: AppSpacing.sm,
            ),
            itemBuilder: (context, index) {
              final membre =
                  provider.membresDuGroupeCourant[index];
              final estMoi = membre.userId == moi?.id;

              return Card(
                child: ListTile(
                  leading: membre.avatarId != null &&
                          membre.avatarId!.isNotEmpty
                      ? CircleAvatar(
                          radius: 14,
                          backgroundImage: AssetImage(
                            'assets/images/avatars/${membre.avatarId}.jpeg',
                          ),
                        )
                      : membre.photoUrl != null &&
                              membre.photoUrl!.isNotEmpty
                          ? CircleAvatar(
                              radius: 14,
                              backgroundImage: NetworkImage(
                                membre.photoUrl!,
                              ),
                            )
                          : CircleAvatar(
                              radius: 14,
                              backgroundColor:
                                  AppColors.primarySurface,
                              child: Text(
                                membre.prenom.isNotEmpty
                                    ? membre.prenom[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                  title: Text(
                    estMoi
                        ? '${membre.nomComplet} (moi)'
                        : membre.nomComplet,
                  ),
                  subtitle: Text(
                    _labelRole(membre.role),
                  ),
                  trailing: groupe?.estAdmin == true &&
                          !estMoi &&
                          membre.role == 'member'
                      ? IconButton(
                          icon: const Icon(
                            Icons.person_remove_outlined,
                            color: AppColors.error,
                          ),
                          onPressed: () => _retirer(
                            context,
                            membre.userId,
                            membre.nomComplet,
                          ),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _labelRole(String role) {
    switch (role) {
      case 'owner':
        return 'Propriétaire';
      case 'admin':
        return 'Administrateur';
      default:
        return 'Membre';
    }
  }
}