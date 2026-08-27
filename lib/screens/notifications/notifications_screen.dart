import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_retry_view.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().chargerNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.notifications.isEmpty) {
            return ErrorRetryView(message: provider.errorMessage!, onRetry: provider.chargerNotifications);
          }

          if (provider.notifications.isEmpty) {
            return const EmptyState(
              emoji: '🔔',
              titre: 'Aucune notification',
              sousTitre: 'Vous serez averti des nouveaux événements et commentaires de vos groupes ici.',
            );
          }

          return RefreshIndicator(
            onRefresh: provider.chargerNotifications,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: provider.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final n = provider.notifications[index];
                return Card(
                  color: n.lu ? AppColors.surface : AppColors.primarySurface,
                  child: ListTile(
                    leading: const Icon(Icons.notifications_rounded, color: AppColors.primary),
                    title: Text(n.titre, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(n.corps),
                    trailing: Text(
                      DateFormat('d MMM · HH:mm', 'fr_FR').format(n.createdAt.toLocal()),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    onTap: () {
                      if (!n.lu) provider.marquerCommeLue(n.id);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
