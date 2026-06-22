import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;

  // גטרים - המסכים יכולים לקרוא אבל לא לשנות ישירות
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // האזנה אוטומטית לשינויים במצב החיבור מ-Firebase
    _authService.authStateChanges.listen((User? newUser) {
      _user = newUser;
      notifyListeners();
    });
  }

  // הרשמה - מקבלת אימייל, סיסמה, ושם
  Future<bool> signUp(String email, String password, String name) async {
    _setLoading(true);
    User? newUser = await _authService.signUpWithEmailAndPassword(
        email, password, name);

    // מחכים קצת כדי לתת ל-Firestore לשמור את הנתונים לפני המעבר למסך
    await Future.delayed(const Duration(seconds: 1));

    _setLoading(false);
    return newUser != null;
  }

  // התחברות
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    User? loggedInUser =
    await _authService.signInWithEmailAndPassword(email, password);
    _setLoading(false);
    return loggedInUser != null;
  }

  // התנתקות
  Future<void> signOut() async {
    _setLoading(true);
    await _authService.signOut();
    _setLoading(false);
  }

  // עדכון מצב טעינה פנימי
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}