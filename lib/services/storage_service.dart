import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

// שירות להעלאת תמונות ל-Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // מעלה תמונה ומחזירה את ה-URL הציבורי שלה
  // [imageFile] - הקובץ המקומי שנבחר מהגלריה
  // [userId] - לשמירה בתיקיית המשתמש (כל משתמש בתיקיה שלו)
  Future<String> uploadSummaryImage(File imageFile, String userId) async {
    // שם ייחודי לתמונה לפי זמן - מונע דריסה של תמונות קודמות
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('summaries/$userId/$fileName');

    // העלאה בפועל
    await ref.putFile(imageFile);

    // קבלת URL להצגה באפליקציה
    return await ref.getDownloadURL();
  }
}
