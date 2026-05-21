import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserRoleService {
  const UserRoleService._();

  static Future<bool> isAdmin(User? user) async {
    if (user == null) return false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 8));
      final role = doc.data()?['role'];
      return role is String && role.trim().toLowerCase() == 'admin';
    } on Exception catch (error) {
      debugPrint('Admin role check skipped: $error');
      return false;
    }
  }
}
