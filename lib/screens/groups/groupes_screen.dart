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
      context.read<GroupProvider>().chargerMesGroupes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes groupes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profil',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profile),
          ),
        ],
      ),
      body: Consumer<GroupProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.groupes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.groupes.isEmpty) {
            return ErrorRetryView(
              message: provider.errorMessage!,
              onRetry: () => provider.chargerMesGroupes(),
            );
          }

          if (provider.groupes.isEmpty) {
            return EmptyState(
              emoji: '👥',
              titre: 'Aucun groupe pour l\'instant',
              sousTitre: 'Créez votre premier groupe ou rejoignez-en un avec un code d\'invitation.',
              action: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.groupeChoice, arguments: true),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Ajouter / rejoindre un groupe'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.chargerMesGroupes,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: provider.groupes.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                if (index == provider.groupes.length) {
                  return OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.groupeChoice, arguments: true),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Ajouter / rejoindre un groupe'),
                  );
                }
                final groupe = provider.groupes[index];
                return GroupCard(
                  groupe: groupe,
                  onTap: () {
                    provider.ouvrirGroupe(groupe);
                    Navigator.of(context).pushNamed(AppRoutes.eventList);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
