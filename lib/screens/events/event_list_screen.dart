import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../config/theme.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../providers/group_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_retry_view.dart';
import '../../widgets/event_card.dart';
import 'widgets/filtres_sheet.dart';

enum ViewMode { list, grid, calendar }

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final _rechercheController = TextEditingController();

  bool _rechercheOuverte = false;

  ViewMode _viewMode = ViewMode.list;

  // Vue utilisée avant d'entrer dans le calendrier.
  ViewMode _viewModeAvantCalendrier = ViewMode.list;

  DateTime _jourSelectionne = DateTime.now();
  DateTime _moisAffiche = DateTime.now();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _charger();
    });
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
      builder: (_) => FiltresSheet(
        categorieInitiale: events.filtreCategorie,
        statutInitial: events.filtreStatut,
      ),
    );

    if (!mounted) return;

    if (resultat != null) {
      events.definirFiltres(
        categorie: resultat['categorie'],
        statut: resultat['statut'],
      );

      _charger();
    }
  }

  // Bouton d'action avec icône + texte sur les grands écrans,
  // et icône seule sur les petits écrans.
  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    String? tooltip,
    bool compact = false,
  }) {
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: IconButton(
          onPressed: onPressed,
          tooltip: tooltip ?? label,
          icon: Icon(
            icon,
            color: AppColors.primaryDark,
            size: 20,
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primarySurface,
            foregroundColor: AppColors.primaryDark,
            minimumSize: const Size(42, 42),
            maximumSize: const Size(42, 42),
            padding: const EdgeInsets.all(9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.65),
              ),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 4,
                  offset: Offset(0, 2),
                  color: Color(0x18000000),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primaryDark,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _labelVue(ViewMode mode) {
    switch (mode) {
      case ViewMode.list:
        return 'Liste';
      case ViewMode.grid:
        return 'Grille';
      case ViewMode.calendar:
        return 'Calendrier';
    }
  }

  IconData _iconeVue(ViewMode mode) {
    switch (mode) {
      case ViewMode.list:
        return Icons.view_list_rounded;
      case ViewMode.grid:
        return Icons.grid_view_rounded;
      case ViewMode.calendar:
        return Icons.calendar_month_rounded;
    }
  }

  Widget _viewModeButton({bool compact = false}) {
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: PopupMenuButton<ViewMode>(
          tooltip: 'Changer la vue',
          padding: EdgeInsets.zero,
          offset: const Offset(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _iconeVue(_viewMode),
              color: AppColors.primaryDark,
              size: 20,
            ),
          ),
          onSelected: (ViewMode mode) {
            if (mode == ViewMode.calendar) {
              setState(() {
                _viewModeAvantCalendrier = _viewMode;
                _viewMode = ViewMode.calendar;
                _jourSelectionne = DateTime.now();
                _moisAffiche = DateTime.now();
              });
            } else {
              setState(() {
                _viewMode = mode;
              });
            }
          },
          itemBuilder: (BuildContext context) =>
              <PopupMenuEntry<ViewMode>>[
            PopupMenuItem<ViewMode>(
              value: ViewMode.list,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.view_list_rounded,
                      color: AppColors.primaryDark,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Liste'),
                ],
              ),
            ),
            PopupMenuItem<ViewMode>(
              value: ViewMode.grid,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: AppColors.primaryDark,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Grille'),
                ],
              ),
            ),
            PopupMenuItem<ViewMode>(
              value: ViewMode.calendar,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.primaryDark,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Calendrier'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: PopupMenuButton<ViewMode>(
        tooltip: 'Changer la vue',
        padding: EdgeInsets.zero,
        offset: const Offset(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.65),
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 4,
                offset: Offset(0, 2),
                color: Color(0x18000000),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _iconeVue(_viewMode),
                  color: AppColors.primaryDark,
                  size: 16,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                _labelVue(_viewMode),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
        onSelected: (ViewMode mode) {
          if (mode == ViewMode.calendar) {
            setState(() {
              _viewModeAvantCalendrier = _viewMode;
              _viewMode = ViewMode.calendar;
              _jourSelectionne = DateTime.now();
              _moisAffiche = DateTime.now();
            });
          } else {
            setState(() {
              _viewMode = mode;
            });
          }
        },
        itemBuilder: (BuildContext context) =>
            <PopupMenuEntry<ViewMode>>[
          PopupMenuItem<ViewMode>(
            value: ViewMode.list,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.view_list_rounded,
                    color: AppColors.primaryDark,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Liste'),
              ],
            ),
          ),
          PopupMenuItem<ViewMode>(
            value: ViewMode.grid,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: AppColors.primaryDark,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Grille'),
              ],
            ),
          ),
          PopupMenuItem<ViewMode>(
            value: ViewMode.calendar,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primaryDark,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Calendrier'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _quitterCalendrier() {
    setState(() {
      _viewMode = _viewModeAvantCalendrier;
    });
  }

  List<EventModel> _evenementsDuJour(
    EventProvider provider,
    DateTime jour,
  ) {
    return provider.events.where((event) {
      final date = event.createdAt;

      return date.year == jour.year &&
          date.month == jour.month &&
          date.day == jour.day;
    }).toList();
  }

  Widget _buildCalendarView(EventProvider provider) {
    final evenementsJour = _evenementsDuJour(
      provider,
      _jourSelectionne,
    );

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 8,
                        offset: Offset(0, 3),
                        color: Color(0x14000000),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: TableCalendar<EventModel>(
                    locale: 'fr_FR',
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2100),
                    focusedDay: _moisAffiche,
                    selectedDayPredicate: (day) {
                      return isSameDay(
                        _jourSelectionne,
                        day,
                      );
                    },
                    eventLoader: (day) {
                      return _evenementsDuJour(
                        provider,
                        day,
                      );
                    },
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Mois',
                    },
                    headerStyle: const HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      leftChevronIcon: Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.textPrimary,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      todayDecoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      markerSize: 7,
                      markersMaxCount: 3,
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _jourSelectionne = selectedDay;
                        _moisAffiche = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _moisAffiche = focusedDay;
                      });
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Icon(
                      Icons.event_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Événements du '
                        '${_jourSelectionne.day.toString().padLeft(2, '0')}/'
                        '${_jourSelectionne.month.toString().padLeft(2, '0')}/'
                        '${_jourSelectionne.year}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (evenementsJour.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '📅',
                          style: TextStyle(fontSize: 38),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Aucun événement ce jour',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sélectionnez une autre date pour voir ses événements.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  )
                else
                  ...evenementsJour.map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.md,
                      ),
                      child: EventCard(
                        event: event,
                        onTap: () async {
                          final navigator = Navigator.of(context);

                          await provider.incrVues(event.id);

                          if (!mounted) return;

                          navigator.pushNamed(
                            AppRoutes.eventDetail,
                            arguments: event.id,
                          );
                        },
                        onChangerStatut: (statut) =>
                            provider.changerStatut(
                          event.id,
                          statut,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAppBarActions({
    required bool compact,
  }) {
    if (_rechercheOuverte) {
      return [
        _actionButton(
          icon: Icons.close_rounded,
          label: 'Fermer',
          tooltip: 'Fermer la recherche',
          compact: compact,
          onPressed: () {
            setState(() {
              _rechercheOuverte = false;
              _rechercheController.clear();

              context.read<EventProvider>().definirFiltres(
                    recherche: '',
                  );

              _charger();
            });
          },
        ),
        if (!compact)
          _actionButton(
            icon: Icons.tune_rounded,
            label: 'Filtres',
            tooltip: 'Filtrer les événements',
            onPressed: _ouvrirFiltres,
          )
        else
          _actionButton(
            icon: Icons.tune_rounded,
            label: 'Filtres',
            tooltip: 'Filtrer les événements',
            compact: true,
            onPressed: _ouvrirFiltres,
          ),
        _viewModeButton(compact: compact),
        _actionButton(
          icon: Icons.groups_2_rounded,
          label: 'Membres',
          tooltip: 'Voir les membres du groupe',
          compact: compact,
          onPressed: () => Navigator.of(context).pushNamed(
            AppRoutes.groupMembers,
          ),
        ),
        const SizedBox(width: 6),
      ];
    }

    return [
      _actionButton(
        icon: Icons.search_rounded,
        label: 'Rechercher',
        tooltip: 'Rechercher un événement',
        compact: compact,
        onPressed: () {
          setState(() {
            _rechercheOuverte = true;
          });
        },
      ),
      _actionButton(
        icon: Icons.tune_rounded,
        label: 'Filtres',
        tooltip: 'Filtrer les événements',
        compact: compact,
        onPressed: _ouvrirFiltres,
      ),
      _viewModeButton(compact: compact),
      _actionButton(
        icon: Icons.groups_2_rounded,
        label: 'Membres',
        tooltip: 'Voir les membres du groupe',
        compact: compact,
        onPressed: () => Navigator.of(context).pushNamed(
          AppRoutes.groupMembers,
        ),
      ),
      const SizedBox(width: 6),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final groupe = context.watch<GroupProvider>().groupeCourant;

    final bool calendrierActif =
        _viewMode == ViewMode.calendar;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.98),
        foregroundColor: AppColors.textPrimary,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,

        leading: Padding(
          padding: const EdgeInsets.only(left: 6),
          child: IconButton(
            onPressed: calendrierActif
                ? _quitterCalendrier
                : () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
            tooltip: calendrierActif
                ? 'Quitter le calendrier'
                : 'Retour aux groupes',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primarySurface,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.all(9),
              minimumSize: const Size(42, 42),
              maximumSize: const Size(42, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        title: calendrierActif
            ? const Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primary,
                    size: 23,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Calendrier',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            : _rechercheOuverte
                ? TextField(
                    controller: _rechercheController,
                    autofocus: true,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un événement...',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (v) {
                      context.read<EventProvider>().definirFiltres(
                            recherche: v,
                          );
                      _charger();
                    },
                  )
                : Text(
                    groupe?.nom ?? 'Événements',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

        actions: calendrierActif
            ? [
                Builder(
                  builder: (context) {
                    final largeur =
                        MediaQuery.sizeOf(context).width;

                    if (largeur < 500) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          onPressed: () {
                            final aujourdHui =
                                DateTime.now();

                            setState(() {
                              _jourSelectionne = aujourdHui;
                              _moisAffiche = aujourdHui;
                            });
                          },
                          tooltip: 'Aujourd’hui',
                          icon: const Icon(
                            Icons.today_rounded,
                            size: 20,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                AppColors.primarySurface,
                            foregroundColor:
                                AppColors.textPrimary,
                            minimumSize:
                                const Size(42, 42),
                            maximumSize:
                                const Size(42, 42),
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding:
                          const EdgeInsets.only(right: 8),
                      child: TextButton.icon(
                        onPressed: () {
                          final aujourdHui =
                              DateTime.now();

                          setState(() {
                            _jourSelectionne = aujourdHui;
                            _moisAffiche = aujourdHui;
                          });
                        },
                        icon: const Icon(
                          Icons.today_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Aujourd’hui',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              AppColors.textPrimary,
                          backgroundColor:
                              AppColors.primarySurface,
                        ),
                      ),
                    );
                  },
                ),
              ]
            : [
                Builder(
                  builder: (context) {
                    final largeur =
                        MediaQuery.sizeOf(context).width;

                    final compact = largeur < 700;

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _buildAppBarActions(
                        compact: compact,
                      ),
                    );
                  },
                ),
              ],
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.03),
              AppColors.primary.withValues(alpha: 0.01),
            ],
          ),
        ),
        child: Consumer<EventProvider>(
          builder: (context, provider, _) {
            if (_viewMode == ViewMode.calendar) {
              return _buildCalendarView(provider);
            }

            if (provider.isLoading &&
                provider.events.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (provider.errorMessage != null &&
                provider.events.isEmpty) {
              return ErrorRetryView(
                message: provider.errorMessage!,
                onRetry: _charger,
              );
            }

            if (provider.events.isEmpty) {
              final filtresActifs =
                  provider.filtreCategorie != null ||
                      provider.filtreStatut != null ||
                      provider.recherche.isNotEmpty;

              return EmptyState(
                emoji: filtresActifs ? '🔍' : '🔗',
                titre: filtresActifs
                    ? 'Aucun résultat'
                    : 'Aucun événement pour l\'instant',
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
                        child: const Text(
                          'Réinitialiser les filtres',
                        ),
                      )
                    : null,
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _charger(),
              child: _buildView(provider),
            );
          },
        ),
      ),

      floatingActionButton: calendrierActif
          ? null
          : FloatingActionButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(
                AppRoutes.createEvent,
              ),
              child: const Icon(Icons.add_rounded),
            ),
    );
  }

  Widget _buildView(EventProvider provider) {
    switch (_viewMode) {
      case ViewMode.list:
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          itemCount: provider.events.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final event = provider.events[index];

            return EventCard(
              event: event,
              onTap: () async {
                final navigator = Navigator.of(context);

                await provider.incrVues(event.id);

                if (!mounted) return;

                navigator.pushNamed(
                  AppRoutes.eventDetail,
                  arguments: event.id,
                );
              },
              onChangerStatut: (statut) =>
                  provider.changerStatut(
                event.id,
                statut,
              ),
            );
          },
        );

      case ViewMode.grid:
        return LayoutBuilder(
          builder: (context, constraints) {
            final largeur = constraints.maxWidth;

            final int colonnes;
            if (largeur < 600) {
              colonnes = 1;
            } else if (largeur < 1000) {
              colonnes = 2;
            } else {
              colonnes = 3;
            }

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: colonnes,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio:
                    colonnes == 1 ? 1.35 : 0.82,
              ),
              itemCount: provider.events.length,
              itemBuilder: (context, index) {
                final event = provider.events[index];

                return EventCard(
                  event: event,
                  onTap: () async {
                    final navigator =
                        Navigator.of(context);

                    await provider.incrVues(event.id);

                    if (!mounted) return;

                    navigator.pushNamed(
                      AppRoutes.eventDetail,
                      arguments: event.id,
                    );
                  },
                  onChangerStatut: (statut) =>
                      provider.changerStatut(
                    event.id,
                    statut,
                  ),
                );
              },
            );
          },
        );

      case ViewMode.calendar:
        return _buildCalendarView(provider);
    }
  }
}