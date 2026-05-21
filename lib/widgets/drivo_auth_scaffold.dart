import 'package:flutter/material.dart';

const kDrivoBlue = Color(0xFF3568E8);
const kDrivoBlueDark = Color(0xFF2556CF);
const kDrivoText = Color(0xFF151A22);
const kDrivoMuted = Color(0xFF6C7280);
const kDrivoField = Color(0xFFF8F8F8);

class DrivoAuthScaffold extends StatelessWidget {
  const DrivoAuthScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDrivoBlue,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _AuthBackgroundPainter()),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -26,
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 42 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Image.asset(
                  'assets/images/auth_car_background.png',
                  height: MediaQuery.of(context).size.width > 900 ? 380 : 230,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 32,
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DrivoAuthCard extends StatelessWidget {
  const DrivoAuthCard({
    super.key,
    required this.subtitle,
    required this.children,
  });

  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      width: width > 760 ? 500 : width * 0.9,
      padding: EdgeInsets.symmetric(
        horizontal: width > 420 ? 58 : 28,
        vertical: width > 420 ? 48 : 34,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 40,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/ada92df8-0d6e-4565-9b2f-6814180ffafa-removebg-preview.png',
            height: 78,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 4),
          const Text(
            'DRIVO',
            style: TextStyle(
              color: kDrivoBlue,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kDrivoMuted,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 34),
          ...children,
        ],
      ),
    );
  }
}

class DrivoInputField extends StatelessWidget {
  const DrivoInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(color: kDrivoText, fontSize: 16),
      decoration: InputDecoration(
        filled: true,
        fillColor: kDrivoField,
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: const TextStyle(color: kDrivoMuted, fontSize: 15),
        floatingLabelStyle: const TextStyle(
          color: kDrivoBlue,
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: Icon(icon, color: kDrivoMuted, size: 21),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.03)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kDrivoBlue, width: 1.4),
        ),
      ),
      cursorColor: kDrivoBlue,
    );
  }
}

class DrivoPrimaryButton extends StatelessWidget {
  const DrivoPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kDrivoBlue,
          disabledBackgroundColor: kDrivoBlue.withValues(alpha: 0.55),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class _AuthBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = kDrivoBlue;
    canvas.drawRect(Offset.zero & size, bg);

    final stripePaint = Paint()..color = Colors.white.withValues(alpha: 0.075);
    final rowHeight = size.height / 2;
    final stripeWidth = size.width * 0.08;
    final gap = size.width * 0.045;

    for (var row = 0; row < 2; row++) {
      final top = row * rowHeight;
      for (
        var x = -stripeWidth;
        x < size.width + stripeWidth;
        x += stripeWidth + gap
      ) {
        final path = Path()
          ..moveTo(x, top)
          ..lineTo(x + stripeWidth, top)
          ..lineTo(x + stripeWidth * 1.34, top + rowHeight * 0.5)
          ..lineTo(x + stripeWidth, top + rowHeight)
          ..lineTo(x, top + rowHeight)
          ..lineTo(x + stripeWidth * 0.34, top + rowHeight * 0.5)
          ..close();
        canvas.drawPath(path, stripePaint);
      }
    }

    final divider = Paint()..color = Colors.white.withValues(alpha: 0.06);
    canvas.drawRect(Rect.fromLTWH(0, rowHeight - 2, size.width, 4), divider);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
