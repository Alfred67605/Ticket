import 'package:flutter/material.dart';
import '../data/repositories/storage_repository.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageRepository _storage;
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeProvider(this._storage) {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void _loadTheme() {
    final mode = _storage.getThemeMode();
    _themeMode = mode == 'light' ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
      await _storage.saveThemeMode('light');
    } else {
      _themeMode = ThemeMode.dark;
      await _storage.saveThemeMode('dark');
    }
    notifyListeners();
  }
}
