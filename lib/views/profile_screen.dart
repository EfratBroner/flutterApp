import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/summary_provider.dart';
import '../providers/settings_provider.dart';
import 'add_summary_screen.dart';
import 'detail_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // קריאת פרטי המשתמש ישירות מ-Firebase - לא תלוי בניווט
    final user = FirebaseAuth.instance.currentUser;
    final summaryProvider = Provider.of<SummaryProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    // סיכומים של המשתמש הנוכחי בלבד - מכל הסיכומים (ללא פילטר נושא)
    final mySummaries = summaryProvider.allSummaries
        .where((s) => s.authorId == user?.uid)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('הפרופיל שלי'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- כרטיס פרטי משתמש ----
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue.shade100,
                      // האות הראשונה מהשם שב-Firebase Auth
                      child: Text(
                        (user?.displayName ?? 'א')[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'משתמש',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(user?.email ?? '',
                            style: const TextStyle(color: Colors.grey)),
                        Text('${mySummaries.length} סיכומים',
                            style:
                                TextStyle(color: Colors.blue.shade700)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ---- הגדרות (Shared Preferences) ----
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('הגדרות',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    // מצב כהה/בהיר - נשמר ב-SharedPreferences
                    SwitchListTile(
                      title: const Text('מצב כהה'),
                      value: settings.isDarkMode,
                      onChanged: (_) => settings.toggleDarkMode(),
                      contentPadding: EdgeInsets.zero,
                    ),

                    // גודל גופן - Slider נשמר ב-SharedPreferences
                    const Text('גודל גופן לקריאה:'),
                    Slider(
                      value: settings.fontSize,
                      min: 12,
                      max: 22,
                      divisions: 5,
                      label: settings.fontSize.toStringAsFixed(0),
                      onChanged: (v) => settings.setFontSize(v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ---- כפתור הוספת סיכום ----
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddSummaryScreen())),
              icon: const Icon(Icons.add),
              label: const Text('הוסף סיכום חדש'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48)),
            ),
            const SizedBox(height: 24),

            // ---- הסיכומים שלי ----
            const Text('הסיכומים שלי',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            mySummaries.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('עדיין לא העלית סיכומים',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: mySummaries.length,
                    itemBuilder: (context, index) {
                      final summary = mySummaries[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(summary.title),
                          subtitle: Text(summary.subject),
                          trailing: Text('${summary.likesCount} ❤️'),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      DetailScreen(summary: summary))),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
