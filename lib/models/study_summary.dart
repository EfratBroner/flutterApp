import 'package:cloud_firestore/cloud_firestore.dart';

class StudySummary {
  final String id;
  final String title;
  final String description;
  final String content;
  final String subject;
  final String authorName;
  final String authorId;
  final String imageUrl;
  final DateTime createdAt;
  final int likesCount;

  StudySummary({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.subject,
    required this.authorName,
    required this.authorId,
    required this.imageUrl,
    required this.createdAt,
    this.likesCount = 0,
  });

  // יצירת אובייקט מתוך נתוני Firestore
  factory StudySummary.fromJson(Map<String, dynamic> json, String documentId) {
    DateTime parsedDate;
    final dynamic timestamp = json['createdAt'];

    if (timestamp is Timestamp) {
      parsedDate = timestamp.toDate();
    } else {
      parsedDate = DateTime.now();
    }

    return StudySummary(
      id: documentId,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      content: json['content'] ?? '',
      subject: json['subject'] ?? '',
      authorName: json['authorName'] ?? '',
      authorId: json['authorId'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      createdAt: parsedDate,
      likesCount: json['likesCount'] ?? 0,
    );
  }

  // המרה לפורמט שמירה ב-Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'subject': subject,
      'authorName': authorName,
      'authorId': authorId,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': likesCount,
    };
  }
}