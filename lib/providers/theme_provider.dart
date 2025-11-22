import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadTheme() async {
    final savedTheme = StorageService.getThemeMode();
    if (savedTheme != null) {
      _themeMode = savedTheme;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await StorageService.saveThemeMode(mode);
      notifyListeners();
    }
  }

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
}

