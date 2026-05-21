import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/cloudinary_service.dart';
import '../login_page.dart';

const _blue = Color(0xFF3568E8);
const _text = Color(0xFF111827);
const _muted = Color(0xFF697386);
const _line = Color(0xFFE8ECF4);
const _field = Color(0xFFF8FAFC);

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _imagePicker = ImagePicker();
  final _cloudinary = const CloudinaryService();

  String _email = '';
  String? _profileImageUrl;
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 8));
      final data = doc.data() ?? const <String, dynamic>{};

      _nameCtrl.text = _stringValue(data, 'name', user.displayName ?? '');
      _phoneCtrl.text = _stringValue(data, 'phone', '');
      _addressCtrl.text = _stringValue(data, 'address', '');
      _email = _stringValue(data, 'email', user.email ?? '');
      _profileImageUrl = _stringValue(
        data,
        'profileImageUrl',
        user.photoURL ?? '',
      );
      if (_profileImageUrl != null && _profileImageUrl!.isEmpty) {
        _profileImageUrl = null;
      }
    } on Exception catch (error) {
      debugPrint('Customer profile load skipped: $error');
      _nameCtrl.text = user.displayName ?? '';
      _email = user.email ?? '';
      _profileImageUrl = user.photoURL;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
      _pickedImageBytes = bytes;
      _pickedImageName = image.name;
    });
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();

    if (name.isEmpty) {
      _message('Please enter your full name.');
      return;
    }

    setState(() => _saving = true);
    try {
      var profileImageUrl = _profileImageUrl;
      if (_pickedImageBytes != null) {
        profileImageUrl = await _cloudinary
            .uploadProfileImage(
              bytes: _pickedImageBytes!,
              fileName: _pickedImageName ?? 'customer_profile.jpg',
            )
            .timeout(const Duration(seconds: 25));
      }

      await user.updateDisplayName(name).timeout(const Duration(seconds: 10));
      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        await user
            .updatePhotoURL(profileImageUrl)
            .timeout(const Duration(seconds: 10));
      }

      final data = {
        'uid': user.uid,
        'name': name,
        'email': user.email ?? _email,
        'phone': phone,
        'address': address,
        'profileImageUrl': profileImageUrl,
        'role': 'customer',
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
      ]).timeout(const Duration(seconds: 12));

      if (!mounted) return;
      setState(() {
        _profileImageUrl = profileImageUrl;
        _pickedImageBytes = null;
        _pickedImageName = null;
      });
      _message('Profile updated successfully.');
    } on Exception catch (error) {
      debugPrint('Customer profile save failed: $error');
      if (mounted) _message('Could not save your profile. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _text,
        elevation: 0,
        title: const Text('Customer Profile'),
        surfaceTintColor: Colors.white,
      ),
      body: user == null
          ? _SignedOutState(
              onLogin: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              ),
            )
          : _loading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfilePhotoPicker(
                        imageBytes: _pickedImageBytes,
                        imageUrl: _profileImageUrl,
                        saving: _saving,
                        onPick: _pickProfileImage,
                      ),
                      const SizedBox(height: 30),
                      _ProfileInput(
                        controller: _nameCtrl,
                        label: 'Full name',
                        icon: Icons.person_outline,
                        textCapitalization: TextCapitalization.words,
                      ),
                      _ReadonlyField(
                        label: 'Email',
                        value: _email.isEmpty ? user.email ?? '' : _email,
                        icon: Icons.email_outlined,
                      ),
                      _ProfileInput(
                        controller: _phoneCtrl,
                        label: 'Phone number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      _ProfileInput(
                        controller: _addressCtrl,
                        label: 'Address',
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 54,
                        child: FilledButton(
                          onPressed: _saving ? null : _saveProfile,
                          style: FilledButton.styleFrom(
                            backgroundColor: _blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(_saving ? 'Saving...' : 'Save Profile'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 54,
                        child: FilledButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            if (!mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Logout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _ProfilePhotoPicker extends StatelessWidget {
  const _ProfilePhotoPicker({
    required this.imageBytes,
    required this.imageUrl,
    required this.saving,
    required this.onPick,
  });

  final Uint8List? imageBytes;
  final String? imageUrl;
  final bool saving;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    return Column(
      children: [
        InkWell(
          onTap: saving ? null : onPick,
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 58,
                backgroundColor: const Color(0xFFEFF4FF),
                backgroundImage: imageBytes != null
                    ? MemoryImage(imageBytes!)
                    : url != null && url.isNotEmpty
                    ? NetworkImage(url)
                    : null,
                child: imageBytes == null && (url == null || url.isEmpty)
                    ? const Icon(Icons.person_outline, color: _blue, size: 50)
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: saving ? null : onPick,
          icon: const Icon(Icons.cloud_upload_outlined, size: 18),
          label: const Text('Change profile picture'),
        ),
      ],
    );
  }
}

class _ProfileInput extends StatelessWidget {
  const _ProfileInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        decoration: _inputDecoration(label, icon),
      ),
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  const _ReadonlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: TextEditingController(text: value),
        enabled: false,
        decoration: _inputDecoration(label, icon),
      ),
    );
  }
}

class _SignedOutState extends StatelessWidget {
  const _SignedOutState({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, color: _muted, size: 48),
          const SizedBox(height: 14),
          const Text(
            'Sign in to view your profile.',
            style: TextStyle(color: _muted, fontSize: 16),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onLogin,
            style: FilledButton.styleFrom(backgroundColor: _blue),
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: _muted),
    filled: true,
    fillColor: _field,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _blue),
    ),
  );
}

String _stringValue(Map<String, dynamic> data, String key, String fallback) {
  final value = data[key];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}
