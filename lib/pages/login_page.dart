import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'customer_page.dart';
import 'admin_page.dart';

// ── Color constants (shared across login & signup) ───────
const kBgDark      = Color(0xFF0A1628);
const kCard        = Color(0xFF1A2744);
const kCardBorder  = Color(0xFF243357);
const kBlue        = Color(0xFF2D7BF5);
const kInputBg     = Color(0xFF162035);
const kInputBorder = Color(0xFF253A5E);
const kText        = Color(0xFFFFFFFF);
const kTextMuted   = Color(0xFF7A8EAD);
const kTextHint    = Color(0xFF4A5E7A);

// ────────────────────────────────────────────────────────
// LoginPage
// ────────────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {

  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  bool _obscure = true;   // controls password visibility
  bool _loading = false;  // controls spinner on Sign In button

  late AnimationController _animCtrl;
  late Animation<double>   _fadeIn;
  late Animation<Offset>   _slideUp;

  @override
  void initState() {
    super.initState();

    // Set up the entrance animation (fade + slide up)
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeIn = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    ));

    _animCtrl.forward(); // start animation immediately
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // Called when the user taps Sign In
  void _signIn() async {
    setState(() => _loading = true);

    final email    = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    // Basic empty-field validation
    if (email.isEmpty || password.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    // TODO: replace with real Laravel API call
    // final response = await http.post(
    //   Uri.parse('https://yourserver.com/api/auth/login'),
    //   body: {'email': email, 'password': password},
    // );

    await Future.delayed(const Duration(milliseconds: 900));
    setState(() => _loading = false);

    // Test credentials: admin / admin123
    if (email == 'admin' && password == 'admin123') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminPage()),
      );
    } else if (email.contains('@') && password.length >= 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Invalid credentials. Use admin/admin123 or a valid email and password (min 4 chars).'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // Navigate to the Sign Up page
  void _goToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupPage()),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      body: Stack(
        children: [
          // Layer 1 — background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),

          // Layer 2 — blue wave at the bottom
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: CustomPaint(
              painter: _WavePainter(),
              size: Size(MediaQuery.of(ctx).size.width, 220),
            ),
          ),

          // Layer 3 — centered card with entrance animation
          Center(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: _buildCard(ctx),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;

    return SingleChildScrollView(
      child: Container(
        width: w > 500 ? 440 : w * 0.9,
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kCardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Logo ──────────────────────────────────────
            Image.asset(
              'assets/images/ada92df8-0d6e-4565-9b2f-6814180ffafa-removebg-preview.png',
              width: 120,
              height: 70,
              fit: BoxFit.contain,
            ),

            // ── App title ─────────────────────────────────
            const Text(
              'DRIVO',
              style: TextStyle(
                color: kBlue,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Welcome back — sign in to continue',
              style: TextStyle(color: kTextMuted, fontSize: 12),
            ),

            const SizedBox(height: 28),

            // ── Email input ───────────────────────────────
            DrInputField(
              controller: _emailCtrl,
              hint: 'you@yourmail.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 14),

            // ── Password input ────────────────────────────
            DrInputField(
              controller: _passCtrl,
              hint: 'Enter your password',
              icon: Icons.lock_outline,
              obscure: _obscure,
              suffix: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: kTextMuted,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),

            const SizedBox(height: 22),

            // ── Sign In button ────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  disabledBackgroundColor: const Color(0xFF1E3A6E),
                  foregroundColor: kText,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Forgot password link ──────────────────────
            GestureDetector(
              onTap: () {
                // TODO: navigate to ForgotPasswordPage
              },
              child: const Text(
                'Forgot password?',
                style: TextStyle(
                  color: kTextMuted,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: kTextMuted,
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ── Divider ───────────────────────────────────
            const Row(
              children: [
                Expanded(child: Divider(color: kCardBorder, thickness: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "Don't have an account?",
                    style: TextStyle(color: kTextHint, fontSize: 11),
                  ),
                ),
                Expanded(child: Divider(color: kCardBorder, thickness: 1)),
              ],
            ),

            const SizedBox(height: 16),

            // ── Create Account button ─────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _goToSignUp,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kBlue, width: 1.5),
                  foregroundColor: kBlue,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// Shared reusable pill-shaped input field
// Used by both LoginPage and SignupPage
// ────────────────────────────────────────────────────────
class DrInputField extends StatelessWidget {
  const DrInputField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext ctx) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: kInputBg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: kInputBorder),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        style: const TextStyle(color: kText, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: kTextHint, fontSize: 14),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: kTextMuted, size: 20),
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
          isDense: false,
        ),
        cursorColor: kBlue,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// Blue wave painter — used on both pages
// ────────────────────────────────────────────────────────
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = const Color(0xFF2D7BF5);
    final path = Path();

    path.moveTo(0, s.height * .55);
    path.quadraticBezierTo(
      s.width * .25, s.height * .18,
      s.width * .5,  s.height * .38,
    );
    path.quadraticBezierTo(
      s.width * .75, s.height * .58,
      s.width,       s.height * .3,
    );
    path.lineTo(s.width, s.height);
    path.lineTo(0, s.height);
    path.close();

    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// Keep _WavePainter as an alias so existing code doesn't break
class _WavePainter extends WavePainter {}