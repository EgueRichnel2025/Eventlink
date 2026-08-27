import 'package:flutter/material.dart';

import '../screens/events/calendar_screen.dart';
import '../screens/events/create_event_screen.dart';
import '../screens/events/event_detail_screen.dart';
import '../screens/events/event_list_screen.dart';
import '../screens/groups/group_members_screen.dart';
import '../screens/groups/group_settings_screen.dart';
import '../screens/groups/groupe_choice_screen.dart';
import '../screens/groups/groupes_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/profil_setup_screen.dart';
import 'app_routes.dart';

/// Génère les routes nommées de l'application.
///
/// La logique de retour (back button) suit naturellement la pile de
/// Navigator standard : EventListScreen -> GroupesScreen -> GroupeChoice,
/// sans jamais de pushReplacement qui casserait cette pile.
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _page(const SplashScreen());
      case AppRoutes.profilSetup:
        return _page(const ProfilSetupScreen());
      case AppRoutes.groupeChoice:
        final depuisGroupes = settings.arguments as bool? ?? false;
        return _page(GroupeChoiceScreen(depuisGroupesScreen: depuisGroupes));
      case AppRoutes.groupesScreen:
        return _page(const GroupesScreen());
      case AppRoutes.eventList:
        return _page(const EventListScreen());
      case AppRoutes.eventDetail:
        final eventId = settings.arguments as String;
        return _page(EventDetailScreen(eventId: eventId));
      case AppRoutes.createEvent:
        return _page(const CreateEventScreen());
      case AppRoutes.profile:
        return _page(const ProfileScreen());
      case AppRoutes.notifications:
        return _page(const NotificationsScreen());
      case AppRoutes.groupMembers:
        return _page(const GroupMembersScreen());
      case AppRoutes.groupSettings:
        return _page(const GroupSettingsScreen());
      case AppRoutes.calendar:
        return _page(const CalendarScreen());
      default:
        return _page(Scaffold(body: Center(child: Text('Route inconnue : ${settings.name}'))));
    }
  }

  static MaterialPageRoute _page(Widget child) {
    return MaterialPageRoute(builder: (_) => child);
  }
}
