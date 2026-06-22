import 'package:shared_preferences/shared_preferences.dart';

// שירות לשמירת הגדרות אפליקציה באחסון מקומי קבוע
// SharedPreferences שומר זוגות key-value על המכשיר גם אחרי סגירת האפליקציה
class PreferencesService {
  // מפתחות קבועים - כך נמנעים מטעויות כתיב
  static const String _darkModeKey = 'dark_mode';
  static const String _fontSizeKey = 'font_size';

  // קריאת מצב כהה/בהיר (ברירת מחדל: בהיר)
  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  // שמירת מצב כהה/בהיר
  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  // קריאת גודל גופן (ברירת מחדל: 16.0)
  Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeKey) ?? 16.0;
  }

  // שמירת גודל גופן
  Future<void> setFontSize(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, value);
  }
}
