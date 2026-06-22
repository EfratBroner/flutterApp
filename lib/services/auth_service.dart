import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // קבלת המשתמש הנוכחי
  User? get currentUser => _auth.currentUser;

  // זרם שמקשיב לשינויים במצב החיבור
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // הרשמה עם אימייל, סיסמה, ושם מלא
  Future<User?> signUpWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      // יצירת חשבון חדש ב-Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // שמירת השם ב-Firebase Auth
      await result.user?.updateDisplayName(name);

      // שמירת פרטי המשתמש גם ב-Firestore (אמין יותר)
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await result.user?.reload();
      return _auth.currentUser;
    } catch (e) {
      print("Error in signUp: ${e.toString()}");
      return null;
    }
  }

  // התחברות עם אימייל וסיסמה
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print("Error in signIn: ${e.toString()}");
      return null;
    }
  }

  // התנתקות
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Error in signOut: ${e.toString()}");
    }
  }
}