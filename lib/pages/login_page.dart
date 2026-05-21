import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../services/user_role_service.dart';
import '../widgets/drivo_auth_scaffold.dart';
// Navigate using named routes to avoid circular imports with admin/customer pages.
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  bool _resetLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter your email and password.');
      return;
    }

    setState(() => _loading = true);

    try {
      if (Firebase.apps.isEmpty) {
        _showMessage(
          'Firebase is not initialized. Please check configuration.',
        );
        return;
      }
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      final isAdmin = await UserRoleService.isAdmin(credential.user);
      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        isAdmin ? '/admin' : '/customer',
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) _showMessage(_firebaseErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showMessage('Enter your email first so we can send the reset link.');
      return;
    }

    setState(() => _resetLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        _showMessage('Password reset email sent to $email.');
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) _showMessage(_firebaseErrorMessage(error));
    } finally {
      if (mounted) setState(() => _resetLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _firebaseErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return error.message ?? 'Login failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DrivoAuthScaffold(
      child: DrivoAuthCard(
        subtitle: 'Create your account and get started',
        children: [
          DrivoInputField(
            controller: _emailCtrl,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 34),
          DrivoInputField(
            controller: _passCtrl,
            label: 'Password',
            icon: Icons.lock_outline,
            obscure: _obscure,
            suffix: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off,
                color: kDrivoMuted,
              ),
            ),
          ),
          const SizedBox(height: 42),
          DrivoPrimaryButton(
            label: 'Sign in',
            loading: _loading,
            onPressed: _signIn,
          ),
          const SizedBox(height: 22),
          TextButton(
            onPressed: _resetLoading ? null : _sendPasswordReset,
            child: Text(_resetLoading ? 'Sending...' : 'Forgot password?'),
          ),
          const SizedBox(height: 42),
          const Text(
            'Dont have an account?',
            style: TextStyle(color: kDrivoMuted, fontSize: 16),
          ),
          const SizedBox(height: 26),
          DrivoPrimaryButton(
            label: 'Create Account',
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SignupPage()),
            ),
          ),
        ],
      ),
    );
  }
}
