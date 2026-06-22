import 'dart:convert';
import 'package:http/http.dart' as http;

// מודל לציטוט יומי שמגיע מה-API
class DailyQuote {
  final String text;
  final String author;

  DailyQuote({required this.text, required this.author});
}

// שירות לקריאת API חיצוני
// משתמשים ב-ZenQuotes API - חינמי, ללא מפתח, מחזיר ציטוט השראה
class ApiService {
  static const String _baseUrl = 'https://zenquotes.io/api/random';

  // קריאה אסינכרונית - מחזירה ציטוט יומי
  // אם הקריאה נכשלת (אין אינטרנט) - זורקת Exception
  Future<DailyQuote> fetchDailyQuote() async {
    final response = await http
        .get(Uri.parse(_baseUrl))
        .timeout(const Duration(seconds: 10)); // timeout למניעת תקיעות

    if (response.statusCode == 200) {
      // ה-API מחזיר רשימה עם אלמנט אחד
      final List<dynamic> data = json.decode(response.body);
      return DailyQuote(
        text: data[0]['q'] ?? '',   // q = quote
        author: data[0]['a'] ?? '', // a = author
      );
    } else {
      throw Exception('שגיאה בטעינת הציטוט: ${response.statusCode}');
    }
  }
}
