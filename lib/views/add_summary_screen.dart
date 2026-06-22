import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/study_summary.dart';
import '../providers/summary_provider.dart';
import '../services/storage_service.dart';

class AddSummaryScreen extends StatefulWidget {
  const AddSummaryScreen({super.key});

  @override
  State<AddSummaryScreen> createState() => _AddSummaryScreenState();
}

class _AddSummaryScreenState extends State<AddSummaryScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedSubject = 'מתמטיקה';
  File? _selectedImage; // התמונה שנבחרה מהגלריה (null = לא נבחרה)
  bool _isUploading = false;

  final List<String> _subjects = [
    'מתמטיקה', 'פיזיקה', 'היסטוריה', 'אנגלית', 'מדעים', 'אחר'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // פתיחת מקור תמונה - גלריה או מצלמה
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  // הצגת תפריט בחירה - גלריה או מצלמה
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('בחר מהגלריה'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('צלם תמונה'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('אנא מלא כותרת ותוכן')),
      );
      return;
    }

    setState(() => _isUploading = true);

    final user = FirebaseAuth.instance.currentUser;
    String imageUrl = '';

    // אם נבחרה תמונה - מעלים ל-Firebase Storage לפני שמירת הסיכום
    if (_selectedImage != null) {
      try {
        imageUrl = await StorageService()
            .uploadSummaryImage(_selectedImage!, user?.uid ?? 'unknown');
      } catch (e) {
        // Storage לא מופעל או שגיאת רשת - ממשיכים בלי תמונה
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('העלאת התמונה נכשלה, הסיכום יפורסם ללא תמונה')),
          );
        }
      }
    }

    final summary = StudySummary(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      content: _contentController.text.trim(),
      subject: _selectedSubject,
      authorName: user?.displayName ?? 'אנונימי',
      authorId: user?.uid ?? '',
      imageUrl: imageUrl, // URL מ-Storage (או ריק אם לא הועלתה תמונה)
      createdAt: DateTime.now(),
    );

    await Provider.of<SummaryProvider>(context, listen: false)
        .addSummary(summary);

    if (!mounted) return;
    setState(() => _isUploading = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('הסיכום נוסף בהצלחה! 🎉')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        Provider.of<SummaryProvider>(context).isLoading || _isUploading;

    return Scaffold(
      appBar: AppBar(title: const Text('סיכום חדש'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ---- בחירת תמונה ----
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  // אם נבחרה תמונה - מציגים אותה, אחרת אייקון
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('הוסף תמונה (אופציונלי)',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // בחירת נושא
            DropdownButtonFormField<String>(
              value: _selectedSubject,
              decoration: const InputDecoration(
                  labelText: 'נושא', border: OutlineInputBorder()),
              items: _subjects
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSubject = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                  labelText: 'כותרת', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                  labelText: 'תיאור קצר', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                  labelText: 'תוכן הסיכום', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),

            // כפתור שליחה - מציג טעינה בזמן העלאה
            isLoading
                ? const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('מעלה תמונה...', style: TextStyle(color: Colors.grey)),
                    ],
                  )
                : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48)),
                    child: const Text('פרסם סיכום'),
                  ),
          ],
        ),
      ),
    );
  }
}
