import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../services/storage_service.dart';

/// Fournisseur pour gérer le thème de l'application (clair/sombre/système).
class ThemeProvider extends ChangeNotifier {
  final StorageService _storageService;

  ThemeProvider(this._storageService) {
    _loadThemePreference();
  }

  ThemeMode _themeMode = ThemeMode.system; // Par défaut,
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    // Pour ThemeMode.system, vérifier la préférence du système
    return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  Future<void> _loadThemePreference() async {
    final preference = await _storageService.getThemePreference();
    if (preference == null) {
      // Préférence non définie, utiliser le système par défaut
      _themeMode = ThemeMode.system;
    } else {
      switch (preference) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'system':
        default:
          _themeMode = ThemeMode.system;
          break;
      }
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    
    // Sauvegarder la préférence
    String preference;
    switch (mode) {
      case ThemeMode.light:
        preference = 'light';
        break;
      case ThemeMode.dark:
        preference = 'dark';
        break;
      case ThemeMode.system:
        preference = 'system';
        break;
    }
    await _storageService.saveThemePreference(preference);
    
    notifyListeners();
  }

  ThemeData get themeData {
    switch (_themeMode) {
      case ThemeMode.light:
        return AppTheme.light;
      case ThemeMode.dark:
        return AppTheme.dark;
      case ThemeMode.system:
        final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        return brightness == Brightness.dark ? AppTheme.dark : AppTheme.light;
    }
  }
}