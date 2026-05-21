import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import 'firebase_options.dart';
import 'pages/admin/admin_page.dart';
import 'pages/customer/customer_page.dart';
import 'pages/login_page.dart';
import 'services/user_role_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await _initializeFirebase();

  runApp(CRBSApp(firebaseReady: firebaseReady));
}

class CRBSApp extends StatelessWidget {
  const CRBSApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRBS App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF0A1628)),
      routes: {
        '/login': (_) => const LoginPage(),
        '/admin': (_) => const AdminPage(),
        '/customer': (_) => const CustomerPage(),
      },
      home: AuthGate(firebaseReady: firebaseReady),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) {
      return const CustomerPage();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2D7BF5)),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const CustomerPage();
        }

        return _RoleGate(user: user);
      },
    );
  }
}

class _RoleGate extends StatelessWidget {
  const _RoleGate({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: UserRoleService.isAdmin(user),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2D7BF5)),
            ),
          );
        }

        return snapshot.data == true ? const AdminPage() : const CustomerPage();
      },
    );
  }
}

Future<bool> _initializeFirebase() async {
  if (!_firebasePlatformIsSupported) return false;

  final options = DefaultFirebaseOptions.currentPlatform;
  if (_hasPlaceholderFirebaseOptions(options)) return false;

  try {
    await Firebase.initializeApp(options: options);
    return true;
  } on Exception catch (error) {
    debugPrint('Firebase initialization skipped: $error');
    return false;
  }
}

bool get _firebasePlatformIsSupported {
  if (kIsWeb) return true;

  return switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => true,
    TargetPlatform.linux || TargetPlatform.fuchsia => false,
  };
}

bool _hasPlaceholderFirebaseOptions(FirebaseOptions options) {
  return options.apiKey.startsWith('REPLACE_WITH_') ||
      options.appId.startsWith('REPLACE_WITH_') ||
      options.projectId.startsWith('REPLACE_WITH_');
}
