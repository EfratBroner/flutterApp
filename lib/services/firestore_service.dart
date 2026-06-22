import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_summary.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // זרם (Stream) שמחזיר את כל הסיכומים בזמן אמת
  // כל פעם שמישהו מוסיף סיכום - הפיד מתעדכן אוטומטית!
  Stream<List<StudySummary>> getSummariesStream() {
    return _firestore
        .collection('summaries')
        .orderBy('createdAt', descending: true) // הכי חדש למעלה
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return StudySummary.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }

  // הוספת סיכום חדש ל-Firestore
  Future<void> addSummary(StudySummary summary) async {
    await _firestore.collection('summaries').add(summary.toJson());
  }

  // עדכון מספר הלייקים של סיכום
  Future<void> updateLikes(String summaryId, int newCount) async {
    await _firestore
        .collection('summaries')
        .doc(summaryId)
        .update({'likesCount': newCount});
  }

  // זרם של תגובות לסיכום מסוים - תת-קולקציה בתוך כל סיכום
  Stream<List<Comment>> getCommentsStream(String summaryId) {
    return _firestore
        .collection('summaries')
        .doc(summaryId)
        .collection('comments')
        .orderBy('createdAt', descending: false) // ישן למעלה, חדש למטה
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comment.fromJson(doc.data(), doc.id))
            .toList());
  }

  // הוספת תגובה חדשה לסיכום
  Future<void> addComment(String summaryId, Comment comment) async {
    await _firestore
        .collection('summaries')
        .doc(summaryId)
        .collection('comments')
        .add(comment.toJson());
  }
}

// מודל תגובה - מוגדר כאן כי הוא קשור ישירות לשירות ה-Firestore
class Comment {
  final String id;
  final String text;
  final String authorName;
  final String authorId;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.text,
    required this.authorName,
    required this.authorId,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json, String id) {
    return Comment(
      id: id,
      text: json['text'] ?? '',
      authorName: json['authorName'] ?? '',
      authorId: json['authorId'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'authorName': authorName,
        'authorId': authorId,
        'createdAt': FieldValue.serverTimestamp(),
      };
}