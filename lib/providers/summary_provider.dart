import 'package:flutter/material.dart';
import '../models/study_summary.dart';
import '../services/firestore_service.dart';
import '../services/database_service.dart'; // מסד נתונים מקומי למועדפים

class SummaryProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final DatabaseService _dbService = DatabaseService(); // SQLite

  List<StudySummary> _summaries = [];
  List<StudySummary> _bookmarks = []; // רשימת המועדפים המקומית
  bool _isLoading = false;
  String _selectedSubject = 'הכל';

  bool get isLoading => _isLoading;
  String get selectedSubject => _selectedSubject;
  List<StudySummary> get bookmarks => _bookmarks; // חשיפה לממשק

  // כל הסיכומים ללא פילטור (לשימוש במסך הפרופיל)
  List<StudySummary> get allSummaries => _summaries;

  // רשימת הסיכומים לאחר פילטור
  List<StudySummary> get summaries {
    if (_selectedSubject == 'הכל') return _summaries;
    return _summaries
        .where((s) => s.subject == _selectedSubject)
        .toList();
  }

  // זרם לפיד - מאזין לשינויים ב-Firestore
  Stream<List<StudySummary>> get summariesStream =>
      _firestoreService.getSummariesStream();

  // שינוי פילטר נושא
  void setSubjectFilter(String subject) {
    _selectedSubject = subject;
    notifyListeners();
  }

  // עדכון הרשימה המקומית
  void updateSummaries(List<StudySummary> summaries) {
    _summaries = summaries;
    notifyListeners();
  }

  // טעינת המועדפים מהמסד המקומי - נקרא בעת אתחול
  Future<void> loadBookmarks() async {
    _bookmarks = await _dbService.getBookmarks();
    notifyListeners();
  }

  // הוספה/הסרה של מועדף - toggle
  Future<void> toggleBookmark(StudySummary summary) async {
    final isBookmarked = await _dbService.isBookmarked(summary.id);
    if (isBookmarked) {
      await _dbService.deleteBookmark(summary.id);
      _bookmarks.removeWhere((s) => s.id == summary.id);
    } else {
      await _dbService.insertBookmark(summary);
      _bookmarks.add(summary);
    }
    notifyListeners(); // עדכון מיידי של ה-UI
  }

  // בדיקה האם סיכום מסוים במועדפים (לכפתור הלב)
  Future<bool> isBookmarked(String id) => _dbService.isBookmarked(id);

  // הוספת סיכום חדש
  Future<void> addSummary(StudySummary summary) async {
    _isLoading = true;
    notifyListeners();
    await _firestoreService.addSummary(summary);
    _isLoading = false;
    notifyListeners();
  }

  // עדכון לייקים
  Future<void> updateLikes(String summaryId, int newCount) async {
    await _firestoreService.updateLikes(summaryId, newCount);
  }
}