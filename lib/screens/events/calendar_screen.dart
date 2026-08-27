import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../config/theme.dart';
import '../../providers/event_provider.dart';
import '../../routes/app_routes.dart';

/// Vue calendrier des événements du groupe courant, organisés par jour de création.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _jourFocus = DateTime.now();
  DateTime? _jourSelectionne;

  @override
  void initState() {
    super.initState();
    _jourSelectionne = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final events = context.watch<EventProvider>().events;

    final evenementsParJour = <DateTime, int>{};
    for (final e in events) {
      final jour = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      evenementsParJour[jour] = (evenementsParJour[jour] ?? 0) + 1;
    }

    final evenementsDuJour = events.where((e) {
      if (_jourSelectionne == null) return false;
      return e.createdAt.year == _jourSelectionne!.year &&
          e.createdAt.month == _jourSelectionne!.month &&
          e.createdAt.day == _jourSelectionne!.day;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Calendrier')),
      body: Column(
        children: [
          TableCalendar(
            locale: 'fr_FR',
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _jourFocus,
            selectedDayPredicate: (day) => isSameDay(_jourSelectionne, day),
            onDaySelected: (selectionne, focus) {
              setState(() {
                _jourSelectionne = selectionne;
                _jourFocus = focus;
              });
            },
            eventLoader: (day) {
              final jour = DateTime(day.year, day.month, day.day);
              final count = evenementsParJour[jour] ?? 0;
              return List.filled(count, null);
            },
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              markerDecoration: BoxDecoration(color: AppColors.primaryDark, shape: BoxShape.circle),
            ),
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
          ),
          const Divider(height: 1),
          Expanded(
            child: evenementsDuJour.isEmpty
                ? Center(
                    child: Text('Aucun événement ce jour-là', style: Theme.of(context).textTheme.bodyMedium),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: evenementsDuJour.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final e = evenementsDuJour[index];
                      return Card(
                        child: ListTile(
                          leading: Text(e.categorie.emoji, style: const TextStyle(fontSize: 22)),
                          title: Text(e.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(e.auteur.nomComplet),
                          onTap: () => Navigator.of(context).pushNamed(AppRoutes.eventDetail, arguments: e.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
