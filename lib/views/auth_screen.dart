import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoginMode = true; // true = כניסה, false = הרשמה

  @override
  void dispose() {
    // שחרור זיכרון כשהמסך נסגר
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    // בדיקת תקינות הטופס
    if (!_formKey.currentState!.validate()) return;

    final authProvider =
    Provider.of<app_auth.AuthProvider>(context, listen: false);
    bool success;

    if (_isLoginMode) {
      // מצב כניסה
      success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } else {
      // מצב הרשמה - שולחים גם שם
      success = await authProvider.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );
    }

    if (!mounted) return;

    if (!success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('הפעולה נכשלה. אנא בדוק את הפרטים ונסה שוב.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoginMode ? 'התחברות' : 'הרשמה'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // שדה שם - מופיע רק בהרשמה
                if (!_isLoginMode) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'שם מלא',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) =>
                    value!.isEmpty ? 'אנא הזן שם' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // שדה אימייל
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'אימייל',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? 'אנא הזן אימייל' : null,
                ),
                const SizedBox(height: 16),

                // שדה סיסמה
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'סיסמה',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) => value!.length < 6
                      ? 'סיסמה חייבת להיות לפחות 6 תווים'
                      : null,
                ),
                const SizedBox(height: 24),

                // כפתור שליחה או עיגול טעינה
                authProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _submitForm,
                  child: Text(_isLoginMode ? 'התחבר' : 'הירשם'),
                ),

                // מעבר בין כניסה להרשמה
                TextButton(
                  onPressed: () =>
                      setState(() => _isLoginMode = !_isLoginMode),
                  child: Text(_isLoginMode
                      ? 'אין חשבון? הירשם'
                      : 'יש חשבון? התחבר'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}