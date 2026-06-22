import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'providers/summary_provider.dart';
import 'providers/settings_provider.dart'; // הגדרות אפליקציה
import 'views/auth_screen.dart';
import 'views/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // טוענים את ההגדרות השמורות לפני הרצת האפליקציה
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  runApp(MyApp(settingsProvider: settingsProvider));
}

class MyApp extends StatelessWidget {
  final SettingsProvider settingsProvider;
  const MyApp({super.key, required this.settingsProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => SummaryProvider()),
        // מעבירים את ה-instance שכבר טען את ההגדרות ב-main
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      // Consumer מאזין לשינויים ב-SettingsProvider ומבנה מחדש רק את MaterialApp
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: 'סיכומי לימוד',
          debugShowCheckedModeBanner: false,
          // themeMode מחובר ל-SettingsProvider - כשמשתמש מחליף מצב, כל האפליקציה מתעדכנת
          theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasData) {
                return const HomeScreen();
              }
              return const AuthScreen();
            },
          ),
        ),
      ),
    );
  }
}