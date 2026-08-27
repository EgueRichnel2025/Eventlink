import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/event_provider.dart';
import '../../providers/group_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_retry_view.dart';
import '../../widgets/event_card.dart';
import 'widgets/filtres_sheet.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final _rechercheController = TextEditingController();
  bool _rechercheOuverte = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  void _charger() {
    final groupId = context.read<GroupProvider>().groupeCourant?.id;
    if (groupId != null) {
      context.read<EventProvider>().chargerEvents(groupId);
    }
  }

  Future<void> _ouvrirFiltres() async {
    final events = context.read<EventProvider>();
    final resultat = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FiltresSheet(categorieInitiale: events.filtreCategorie, statutInitial: events.filtreStatut),
    );
    if (resultat != null) {
      events.definirFiltres(categorie: resultat['categorie'], statut: resultat['statut']);
      _charger();
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupe = context.watch<GroupProvider>().groupeCourant;

    return Scaffold(
      appBar: AppBar(
        title: _rechercheOuverte
            ? TextField(
                controller: _rechercheController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un événement...',
                  border: InputBorder.none,
                ),
                onChanged: (v) {
                  context.read<EventProvider>().definirFiltres(recherche: v);
                  _charger();
                },
              )
            : Text(groupe?.nom ?? 'Événements'),
        actions: [
          IconButton(
            icon: Icon(_rechercheOuverte ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () => setState(() {
              _rechercheOuverte = !_rechercheOuverte;
              if (!_rechercheOuverte) {
                _rechercheController.clear();
                context.read<EventProvider>().definirFiltres(recherche: '');
                _charger();
              }
            }),
          ),
          IconButton(icon: const Icon(Icons.tune_rounded), onPressed: _ouvrirFiltres),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Calendrier',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.calendar),
          ),
          IconButton(
            icon: const Icon(Icons.groups_2_outlined),
            tooltip: 'Membres',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.groupMembers),
          ),
        ],
      ),
      body: Consumer<EventProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.events.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.events.isEmpty) {
            return ErrorRetryView(message: provider.errorMessage!, onRetry: _charger);
          }

          if (provider.events.isEmpty) {
            final filtresActifs = provider.filtreCategorie != null ||
                provider.filtreStatut != null ||
                provider.recherche.isNotEmpty;

            return EmptyState(
              emoji: filtresActifs ? '🔍' : '🔗',
              titre: filtresActifs ? 'Aucun résultat' : 'Aucun événement pour l\'instant',
              sousTitre: filtresActifs
                  ? 'Essayez d\'autres filtres ou une autre recherche.'
                  : 'Partagez une opportunité ou ajoutez votre premier événement.',
              action: filtresActifs
                  ? OutlinedButton(
                      onPressed: () {
                        provider.reinitialiserFiltres();
                        _rechercheController.clear();
                        _charger();
                      },
                      child: const Text('Réinitialiser les filtres'),
                    )
                  : null,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _charger(),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: provider.events.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final event = provider.events[index];
                return EventCard(
                  event: event,
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.eventDetail, arguments: event.id),
                  onChangerStatut: (statut) => provider.changerStatut(event.id, statut),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.createEvent),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
