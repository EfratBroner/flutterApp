import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/study_summary.dart';
import '../providers/summary_provider.dart';
import '../providers/settings_provider.dart';
import '../services/firestore_service.dart';

class DetailScreen extends StatefulWidget {
  final StudySummary summary;
  const DetailScreen({super.key, required this.summary});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late int _likesCount;
  bool _isLiked = false;
  bool _isBookmarked = false;
  final _commentController = TextEditingController(); // שדה כתיבת תגובה
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _likesCount = widget.summary.likesCount;
    _loadBookmarkState(); // בדיקה האם כבר מועדף
  }

  // בדיקה אסינכרונית מול SQLite
  Future<void> _loadBookmarkState() async {
    final bookmarked = await Provider.of<SummaryProvider>(context, listen: false)
        .isBookmarked(widget.summary.id);
    if (mounted) setState(() => _isBookmarked = bookmarked);
  }

  void _toggleLike() {
    setState(() {
      _isLiked ? _likesCount-- : _likesCount++;
      _isLiked = !_isLiked;
    });
    Provider.of<SummaryProvider>(context, listen: false)
        .updateLikes(widget.summary.id, _likesCount);
  }

  // שמירה/הסרה מ-SQLite דרך ה-Provider
  Future<void> _toggleBookmark() async {
    await Provider.of<SummaryProvider>(context, listen: false)
        .toggleBookmark(widget.summary);
    setState(() => _isBookmarked = !_isBookmarked);
  }

  // שליחת תגובה חדשה ל-Firestore
  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final comment = Comment(
      id: '',
      text: text,
      authorName: user?.displayName ?? 'אנונימי',
      authorId: user?.uid ?? '',
      createdAt: DateTime.now(),
    );

    await _firestoreService.addComment(widget.summary.id, comment);
    _commentController.clear(); // ניקוי השדה אחרי שליחה
  }

  @override
  Widget build(BuildContext context) {
    // גודל הגופן מגיע מ-SettingsProvider - משתנה בזמן אמת
    final fontSize = Provider.of<SettingsProvider>(context).fontSize;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.summary.subject),
        centerTitle: true,
        actions: [
          // כפתור מועדף ב-AppBar
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? Colors.amber : null,
            ),
            onPressed: _toggleBookmark,
            tooltip: _isBookmarked ? 'הסר ממועדפים' : 'הוסף למועדפים',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // תמונה מורחבת - מוצגת רק אם קיימת URL
            if (widget.summary.imageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.summary.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // תג נושא
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(widget.summary.subject,
                  style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),

            // כותרת - גודל גופן מ-SettingsProvider
            Text(widget.summary.title,
                style: TextStyle(
                    fontSize: fontSize + 8, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // מחבר ותאריך
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(widget.summary.authorName,
                    style: const TextStyle(color: Colors.grey)),
                const Spacer(),
                Text(
                  '${widget.summary.createdAt.day}/${widget.summary.createdAt.month}/${widget.summary.createdAt.year}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 24),

            // תיאור
            Text(widget.summary.description,
                style: TextStyle(
                    fontSize: fontSize,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),

            // תוכן מלא - גודל גופן דינמי מ-SharedPreferences
            Text(widget.summary.content,
                style: TextStyle(fontSize: fontSize, height: 1.6)),
            const SizedBox(height: 32),

            // כפתור לייק עם אנימציה
            Center(
              child: GestureDetector(
                onTap: _toggleLike,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isLiked
                        ? Colors.red.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: _isLiked ? Colors.red : Colors.grey),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text('$_likesCount לייקים',
                          style: TextStyle(
                              color: _isLiked ? Colors.red : Colors.grey,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ---- אזור תגובות ----
            const Divider(),
            const Text(
              'תגובות',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // שדה כתיבת תגובה
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'כתוב תגובה...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                // כפתור שליחה
                IconButton(
                  onPressed: _submitComment,
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // רשימת התגובות - מאזינה ל-Firestore בזמן אמת
            StreamBuilder<List<Comment>>(
              stream: _firestoreService.getCommentsStream(widget.summary.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('אין תגובות עדיין. היי הראשון!',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                // תגובות - shrinkWrap כי אנחנו בתוך SingleChildScrollView
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // אווטאר קטן עם אות ראשונה של המתגיב
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              comment.authorName.isNotEmpty
                                  ? comment.authorName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment.authorName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(comment.text),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
