import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/study_summary.dart';

// שירות לניהול מסד נתונים מקומי (SQLite)
// כל הפוסטים שהמשתמש מסמן כמועדף נשמרים כאן - זמינים גם ללא אינטרנט
class DatabaseService {
  static Database? _db;

  // Singleton - מסד נתונים אחד לכל האפליקציה
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    // נתיב לקובץ ה-SQLite במכשיר
    final path = join(await getDatabasesPath(), 'bookmarks.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        // יצירת הטבלה בפעם הראשונה שהאפליקציה רצה
        return db.execute('''
          CREATE TABLE bookmarks (
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            content TEXT,
            subject TEXT,
            authorName TEXT,
            authorId TEXT,
            imageUrl TEXT,
            createdAt INTEGER,
            likesCount INTEGER
          )
        ''');
      },
    );
  }

  // הוספת סיכום למועדפים
  Future<void> insertBookmark(StudySummary summary) async {
    final db = await database;
    await db.insert(
      'bookmarks',
      {
        'id': summary.id,
        'title': summary.title,
        'description': summary.description,
        'content': summary.content,
        'subject': summary.subject,
        'authorName': summary.authorName,
        'authorId': summary.authorId,
        'imageUrl': summary.imageUrl,
        // שמירת תאריך כמספר (milliseconds) כי SQLite לא מכיר DateTime
        'createdAt': summary.createdAt.millisecondsSinceEpoch,
        'likesCount': summary.likesCount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace, // אם כבר קיים - עדכן
    );
  }

  // מחיקת סיכום מהמועדפים
  Future<void> deleteBookmark(String id) async {
    final db = await database;
    await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  // קריאת כל המועדפים השמורים
  Future<List<StudySummary>> getBookmarks() async {
    final db = await database;
    final maps = await db.query('bookmarks', orderBy: 'createdAt DESC');
    return maps
        .map((map) => StudySummary(
              id: map['id'] as String,
              title: map['title'] as String,
              description: map['description'] as String,
              content: map['content'] as String,
              subject: map['subject'] as String,
              authorName: map['authorName'] as String,
              authorId: map['authorId'] as String,
              imageUrl: map['imageUrl'] as String,
              // המרה חזרה מ-milliseconds ל-DateTime
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                  map['createdAt'] as int),
              likesCount: map['likesCount'] as int,
            ))
        .toList();
  }

  // בדיקה האם סיכום מסוים כבר במועדפים
  Future<bool> isBookmarked(String id) async {
    final db = await database;
    final result =
        await db.query('bookmarks', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty;
  }
}
