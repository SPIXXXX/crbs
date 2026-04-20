import 'package:flutter/material.dart';
import 'login_page.dart';

// ────────────────────────────────────────────────────────
// SignupPage
// ────────────────────────────────────────────────────────
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscure = true;
  bool _confirmObscure = true;
  bool _loading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();

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

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // Called when the user taps Sign Up
  void _signUp() async {
    setState(() => _loading = true);

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    final confirmPassword = _confirmPassCtrl.text;

    // Basic validation
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    if (password != confirmPassword) {
      setState(() => _loading = false);
      return;
    }

    // TODO: replace with real Laravel API call
    await Future.delayed(const Duration(milliseconds: 1400));
    setState(() => _loading = false);

    // TODO: Navigate to dashboard on success
  }

  // Navigate back to Login page
  void _goToLogin() {
    Navigator.pop(context);
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
              painter: WavePainter(),
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
              'Create your account to get started',
              style: TextStyle(color: kTextMuted, fontSize: 12),
            ),

            const SizedBox(height: 28),

            // ── Name input ────────────────────────────────
            DrInputField(
              controller: _nameCtrl,
              hint: 'Full name',
              icon: Icons.person_outline,
            ),

            const SizedBox(height: 14),

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

            const SizedBox(height: 14),

            // ── Confirm password input ────────────────────
            DrInputField(
              controller: _confirmPassCtrl,
              hint: 'Confirm your password',
              icon: Icons.lock_outline,
              obscure: _confirmObscure,
              suffix: IconButton(
                icon: Icon(
                  _confirmObscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: kTextMuted,
                  size: 20,
                ),
                onPressed: () => setState(() => _confirmObscure = !_confirmObscure),
              ),
            ),

            const SizedBox(height: 22),

            // ── Sign Up button ────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _signUp,
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
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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
                    'Already have an account?',
                    style: TextStyle(color: kTextHint, fontSize: 11),
                  ),
                ),
                Expanded(child: Divider(color: kCardBorder, thickness: 1)),
              ],
            ),

            const SizedBox(height: 16),

            // ── Back to Login button ──────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _goToLogin,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kBlue, width: 1.5),
                  foregroundColor: kBlue,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Back to Login',
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
