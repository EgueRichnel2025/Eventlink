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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().chargerMembresDuGroupeCourant();
    });
  }

  Future<void> _retirer(BuildContext context, String userId, String nom) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer ce membre ?'),
        content: Text('$nom ne pourra plus voir les événements de ce groupe.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Retirer')),
        ],
      ),
    );
    if (confirme == true && context.mounted) {
      await context.read<GroupProvider>().retirerMembre(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupe = context.watch<GroupProvider>().groupeCourant;
    final moi = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Membres'),
        actions: [
          if (groupe?.estAdmin == true)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.groupSettings),
            ),
        ],
      ),
      body: Consumer<GroupProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.membresDuGroupeCourant.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null && provider.membresDuGroupeCourant.isEmpty) {
            return ErrorRetryView(
              message: provider.errorMessage!,
              onRetry: provider.chargerMembresDuGroupeCourant,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: provider.membresDuGroupeCourant.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final membre = provider.membresDuGroupeCourant[index];
              final estMoi = membre.userId == moi?.id;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      membre.prenom.isNotEmpty ? membre.prenom[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(estMoi ? '${membre.nomComplet} (moi)' : membre.nomComplet),
                  subtitle: Text(_labelRole(membre.role)),
                  trailing: (groupe?.estAdmin == true && !estMoi && membre.role == 'member')
                      ? IconButton(
                          icon: const Icon(Icons.person_remove_outlined, color: AppColors.error),
                          onPressed: () => _retirer(context, membre.userId, membre.nomComplet),
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
