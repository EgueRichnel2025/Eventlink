import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _modifierProfil(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final prenomController = TextEditingController(text: auth.currentUser?.prenom);
    final nomController = TextEditingController(text: auth.currentUser?.nom);

    final resultat = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Modifier le profil', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              TextField(controller: prenomController, decoration: const InputDecoration(labelText: 'Prénom')),
              const SizedBox(height: AppSpacing.md),
              TextField(controller: nomController, decoration: const InputDecoration(labelText: 'Nom')),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () async {
                  final succes = await context.read<AuthProvider>().modifierProfil(
                        prenom: prenomController.text.trim(),
                        nom: nomController.text.trim(),
                      );
                  if (context.mounted) Navigator.of(context).pop(succes);
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );

    if (resultat == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil mis à jour')));
    }
  }

  Future<void> _deconnexion(BuildContext context) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous devrez vous reconnecter pour retrouver vos groupes.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Se déconnecter')),
        ],
      ),
    );

    if (confirme == true && context.mounted) {
      await context.read<AuthProvider>().deconnexion();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.splash, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primarySurface,
                        backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                        child: user.photoUrl == null
                            ? Text(
                                user.initiales,
                                style: const TextStyle(fontSize: 28, color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                              )
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(user.nomComplet, style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                    title: const Text('Modifier le profil'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _modifierProfil(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                    title: const Text('Notifications'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                OutlinedButton.icon(
                  onPressed: () => _deconnexion(context),
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: const Text('Se déconnecter', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                ),
              ],
            ),
    );
  }
}
