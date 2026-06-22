import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/study_summary.dart';
import '../providers/summary_provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../services/api_service.dart';
import 'add_summary_screen.dart';
import 'detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _subjects = [
    'הכל', 'מתמטיקה', 'פיזיקה', 'היסטוריה', 'אנגלית', 'מדעים', 'אחר'
  ];

  // ציטוט יומי מה-API - Future נשמר כדי שלא יטען מחדש בכל rebuild
  late final Future<DailyQuote> _quoteFuture;

  @override
  void initState() {
    super.initState();
    _quoteFuture = ApiService().fetchDailyQuote();
    // טעינת המועדפים מה-SQLite בעת פתיחת המסך
    Provider.of<SummaryProvider>(context, listen: false).loadBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    final summaryProvider = Provider.of<SummaryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('סיכומי לימוד'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                Provider.of<app_auth.AuthProvider>(context, listen: false)
                    .signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ---- ציטוט יומי מה-API ----
          _QuoteWidget(quoteFuture: _quoteFuture),

          // ---- פילטר נושאים ----
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                final subject = _subjects[index];
                final isSelected = summaryProvider.selectedSubject == subject;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: FilterChip(
                    label: Text(subject),
                    selected: isSelected,
                    onSelected: (_) =>
                        summaryProvider.setSubjectFilter(subject),
                  ),
                );
              },
            ),
          ),

          // ---- פיד מ-Firestore ----
          Expanded(
            child: StreamBuilder<List<StudySummary>>(
              stream: summaryProvider.summariesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // שגיאה (כולל חוסר אינטרנט) - מציגים מועדפים מ-SQLite
                if (snapshot.hasError) {
                  final bookmarks = summaryProvider.bookmarks;
                  return bookmarks.isEmpty
                      ? const Center(child: Text('אין חיבור ואין מועדפים שמורים'))
                      : Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                '📴 מצב אופליין - מוצגים מועדפים שמורים',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                            Expanded(child: _SummaryList(summaries: bookmarks)),
                          ],
                        );
                }

                // עדכון הרשימה המקומית רק אם השתנתה - מניעת לולאה אינסופית
                final allSummaries = snapshot.data ?? [];
                if (summaryProvider.allSummaries.length != allSummaries.length) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    summaryProvider.updateSummaries(allSummaries);
                  });
                }

                final summaries = summaryProvider.summaries;

                if (summaries.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('אין סיכומים עדיין',
                            style:
                                TextStyle(fontSize: 18, color: Colors.grey)),
                        SizedBox(height: 8),
                        Text('לחץ על + כדי להוסיף סיכום ראשון!',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return _SummaryList(summaries: summaries);
              },
            ),
          ),
        ],
      ),

      // ---- FAB - פותח מסך הוספת סיכום (תוקן!) ----
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AddSummaryScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---- ויג'ט ציטוט יומי ----
class _QuoteWidget extends StatelessWidget {
  final Future<DailyQuote> quoteFuture;
  const _QuoteWidget({required this.quoteFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DailyQuote>(
      future: quoteFuture,
      builder: (context, snapshot) {
        // בטעינה - רצועה דקה
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        // שגיאה או אין אינטרנט - לא מציגים כלום
        if (!snapshot.hasData) return const SizedBox.shrink();

        final quote = snapshot.data!;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('"${quote.text}"',
                  style: const TextStyle(fontStyle: FontStyle.italic)),
              const SizedBox(height: 4),
              Text('— ${quote.author}',
                  style: TextStyle(
                      color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }
}

// ---- רשימת סיכומים (בשימוש גם לאופליין) ----
class _SummaryList extends StatelessWidget {
  final List<StudySummary> summaries;
  const _SummaryList({required this.summaries});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: summaries.length,
      itemBuilder: (context, index) => _SummaryCard(summary: summaries[index]),
    );
  }
}

// ---- כרטיסיית סיכום מותאמת אישית ----
class _SummaryCard extends StatelessWidget {
  final StudySummary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => DetailScreen(summary: summary))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(summary.subject,
                        style: TextStyle(
                            color: Colors.blue.shade800, fontSize: 12)),
                  ),
                  Text(summary.authorName,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              // תמונה - מוצגת רק אם קיימת
              if (summary.imageUrl.isNotEmpty) ...
                [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      summary.imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      // אייקון חלופי אם התמונה לא נטענת
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              Text(summary.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(summary.description,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.favorite_border,
                      size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text('${summary.likesCount}',
                      style: const TextStyle(fontSize: 12)),
                  const Spacer(),
                  Text(
                    '${summary.createdAt.day}/${summary.createdAt.month}/${summary.createdAt.year}',
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
