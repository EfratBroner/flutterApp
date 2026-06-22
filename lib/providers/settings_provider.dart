import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

// Provider לניהול הגדרות האפליקציה
// כשמשתמש משנה הגדרה - כל ה-UI מתעדכן אוטומטית דרך notifyListeners
class SettingsProvider with ChangeNotifier {
  final PreferencesService _prefsService = PreferencesService();

  bool _isDarkMode = false;
  double _fontSize = 16.0;

  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;

  // טעינת ההגדרות השמורות בעת אתחול האפליקציה
  Future<void> loadSettings() async {
    _isDarkMode = await _prefsService.getDarkMode();
    _fontSize = await _prefsService.getFontSize();
    notifyListeners(); // עדכון ה-UI אחרי טעינה
  }

  // שינוי מצב כהה/בהיר - שומר מיד לדיסק
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _prefsService.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  // שינוי גודל גופן - שומר מיד לדיסק
  Future<void> setFontSize(double size) async {
    _fontSize = size;
    await _prefsService.setFontSize(size);
    notifyListeners();
  }
}
