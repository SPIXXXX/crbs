import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/cloudinary_service.dart';
import '../widgets/drivo_auth_scaffold.dart';
import 'customer/customer_page.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _imagePicker = ImagePicker();
  final _cloudinary = const CloudinaryService();

  Uint8List? _profileImageBytes;
  String? _profileImageName;
  bool _obscure = true;
  bool _confirmObscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;

    setState(() {
      _profileImageBytes = bytes;
      _profileImageName = image.name;
    });
  }

  Future<void> _signUp() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    final confirmPassword = _confirmPassCtrl.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Please fill in all fields.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() => _loading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 20));
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'missing-user',
          message: 'Account was created but the user session was not returned.',
        );
      }

      var successMessage = 'Account created successfully.';
      final profileImageUrl = await _uploadProfileImageAfterSignup();
      await _updateAuthProfile(user, name, profileImageUrl);
      if (_profileImageBytes != null && profileImageUrl == null) {
        successMessage =
            'Account created, but the profile picture upload did not finish.';
      }

      unawaited(_saveCustomerProfile(user, name, email, profileImageUrl));

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerPage(successMessage: successMessage),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) _showMessage(_firebaseErrorMessage(error));
    } on FirebaseException catch (error) {
      if (mounted) {
        _showMessage(error.message ?? 'Could not save your profile data.');
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        _showMessage(
          'Creating your account took too long. Please check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _uploadProfileImageAfterSignup() async {
    if (_profileImageBytes == null) return null;

    try {
      return await _cloudinary
          .uploadProfileImage(
            bytes: _profileImageBytes!,
            fileName: _profileImageName ?? 'customer_profile.jpg',
          )
          .timeout(const Duration(seconds: 25));
    } on Exception catch (error) {
      debugPrint('Profile image upload skipped: $error');
      return null;
    }
  }

  Future<void> _updateAuthProfile(
    User user,
    String name,
    String? profileImageUrl,
  ) async {
    try {
      await user.updateDisplayName(name).timeout(const Duration(seconds: 10));
      if (profileImageUrl != null) {
        await user
            .updatePhotoURL(profileImageUrl)
            .timeout(const Duration(seconds: 10));
      }
    } on Exception catch (error) {
      debugPrint('Auth profile update skipped: $error');
    }
  }

  Future<void> _saveCustomerProfile(
    User user,
    String name,
    String email,
    String? profileImageUrl,
  ) async {
    try {
      final data = {
        'uid': user.uid,
        'name': name,
        'email': email,
        'profileImageUrl': profileImageUrl,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await Future.wait([
        FirebaseFirestore.instance
            .collection('customers')
            .doc(user.uid)
            .set(data, SetOptions(merge: true)),
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(data, SetOptions(merge: true)),
      ]).timeout(const Duration(seconds: 8));
    } on Exception catch (error) {
      debugPrint('Customer profile save skipped: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _firebaseErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'That email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return error.message ?? 'Sign up failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DrivoAuthScaffold(
      child: DrivoAuthCard(
        subtitle: 'Create your account and get started',
        children: [
          _ProfilePicturePicker(
            imageBytes: _profileImageBytes,
            loading: _loading,
            onPressed: _pickProfileImage,
          ),
          const SizedBox(height: 26),
          DrivoInputField(
            controller: _nameCtrl,
            label: 'Full name',
            icon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),
          DrivoInputField(
            controller: _emailCtrl,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 24),
          DrivoInputField(
            controller: _confirmPassCtrl,
            label: 'Confirm Password',
            icon: Icons.lock_outline,
            obscure: _confirmObscure,
            suffix: IconButton(
              onPressed: () =>
                  setState(() => _confirmObscure = !_confirmObscure),
              icon: Icon(
                _confirmObscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off,
                color: kDrivoMuted,
              ),
            ),
          ),
          const SizedBox(height: 36),
          DrivoPrimaryButton(
            label: 'Create Account',
            loading: _loading,
            onPressed: _signUp,
          ),
          const SizedBox(height: 26),
          const Text(
            'Already have an account?',
            style: TextStyle(color: kDrivoMuted, fontSize: 16),
          ),
          const SizedBox(height: 20),
          DrivoPrimaryButton(
            label: 'Sign in',
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePicturePicker extends StatelessWidget {
  const _ProfilePicturePicker({
    required this.imageBytes,
    required this.loading,
    required this.onPressed,
  });

  final Uint8List? imageBytes;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFFEFF4FF),
                backgroundImage: imageBytes == null
                    ? null
                    : MemoryImage(imageBytes!),
                child: imageBytes == null
                    ? const Icon(
                        Icons.person_outline,
                        color: kDrivoBlue,
                        size: 42,
                      )
                    : null,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: kDrivoBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: loading ? null : onPressed,
          icon: const Icon(Icons.cloud_upload_outlined, size: 18),
          label: Text(
            imageBytes == null ? 'Upload profile picture' : 'Change picture',
          ),
        ),
      ],
    );
  }
}
