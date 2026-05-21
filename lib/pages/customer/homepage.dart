import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../login_page.dart';
import '../signup_page.dart';
import 'car_details_page.dart';
import 'customer_profile_page.dart';
import 'view_all_cars.dart';

const _blue = Color(0xFF3568E8);
const _orange = Color(0xFFFF9D12);
const _text = Color(0xFF111827);
const _muted = Color(0xFF697386);
const _line = Color(0xFFE8ECF4);

// ── Reusable staggered section entrance ───────────────────────────────────────

class _SectionEntrance extends StatefulWidget {
  const _SectionEntrance({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<_SectionEntrance> createState() => _SectionEntranceState();
}

class _SectionEntranceState extends State<_SectionEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 580),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key, this.successMessage});

  final String? successMessage;

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();

    final message = widget.successMessage;
    if (message != null && message.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 820;
            final inset = _pageInset(constraints.maxWidth);

            return SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          inset,
                          wide ? 28 : 20,
                          inset,
                          20,
                        ),
                        child: const _HomeNav(),
                      ),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1360),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: wide ? 54 : 18,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: const [
                                _SectionEntrance(
                                  delay: Duration(milliseconds: 100),
                                  child: _HeroSection(),
                                ),
                                SizedBox(height: 74),
                                _SectionEntrance(
                                  delay: Duration(milliseconds: 260),
                                  child: _FeatureStrip(),
                                ),
                                SizedBox(height: 68),
                                _SectionEntrance(
                                  delay: Duration(milliseconds: 380),
                                  child: _HowItWorksSection(),
                                ),
                                SizedBox(height: 76),
                                _SectionEntrance(
                                  delay: Duration(milliseconds: 480),
                                  child: _CarsSection(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 82),
                      const _FooterSection(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _pageInset(double width) {
    if (width >= 1400) return 72;
    if (width >= 900) return 48;
    return 18;
  }
}

class _HomeNav extends StatelessWidget {
  const _HomeNav();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Row(
          children: [
            const _LogoMark(),
            const Spacer(),
            if (MediaQuery.of(context).size.width >= 940)
              SizedBox(
                width: 420,
                height: 44,
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: const Icon(Icons.tune, size: 18),
                    hintText: 'Search cars, brands, or body type',
                    hintStyle: const TextStyle(fontSize: 13, color: _muted),
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: _line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: _line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: _blue),
                    ),
                  ),
                ),
              ),
            const Spacer(),
            if (user == null) ...[
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ),
                child: const Text('Login'),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupPage()),
                ),
                child: const Text('Sign up'),
              ),
            ] else ...[
              // Current rentals icon
              Tooltip(
                message: 'Currently Renting',
                child: IconButton(
                  onPressed: () => _openCurrentRentals(context, user),
                  icon: const Icon(Icons.directions_car_outlined),
                ),
              ),
              // Rental history icon
              Tooltip(
                message: 'Rental History',
                child: IconButton(
                  onPressed: () => _openRentalHistory(context, user),
                  icon: const Icon(Icons.history),
                ),
              ),
              Tooltip(
                message: 'Profile',
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustomerProfilePage(),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(999),
                  child: _CustomerAvatar(photoUrl: user.photoURL),
                ),
              ),
              const SizedBox(width: 10),
              if (MediaQuery.of(context).size.width >= 560)
                Text(
                  user.displayName?.isNotEmpty == true
                      ? user.displayName!
                      : user.email ?? 'Customer',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
            ],
          ],
        );
      },
    );
  }

  Stream<User?> _authStateChanges() {
    try {
      return FirebaseAuth.instance.userChanges();
    } catch (_) {
      return Stream<User?>.value(null);
    }
  }

  void _openRentalHistory(BuildContext context, User user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.8,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              const Text(
                'Rental History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('customerId', isEqualTo: user.uid)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting)
                      return const Center(child: CircularProgressIndicator());
                    final docs = snap.data?.docs ?? const [];
                    if (docs.isEmpty)
                      return const Center(child: Text('No rental history'));
                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (ctx, i) {
                        final d = docs[i].data();
                        final name = d['vehicleName'] ?? 'Rental Car';
                        final status = d['status'] ?? '—';
                        final pickup = d['pickupDate'] is Timestamp
                            ? (d['pickupDate'] as Timestamp).toDate()
                            : null;
                        final dateLabel = pickup != null
                            ? '${pickup.year}-${pickup.month.toString().padLeft(2, '0')}-${pickup.day.toString().padLeft(2, '0')}'
                            : (d['dateLabel'] ?? '');
                        return ListTile(
                          leading: const Icon(Icons.directions_car),
                          title: Text(name),
                          subtitle: Text(dateLabel),
                          trailing: Text(status),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCurrentRentals(BuildContext context, User user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.6,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              const Text(
                'Currently Renting',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('customerId', isEqualTo: user.uid)
                      .where(
                        'status',
                        whereIn: ['Confirmed', 'Active', 'confirmed', 'active'],
                      )
                      .orderBy('pickupDate', descending: false)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting)
                      return const Center(child: CircularProgressIndicator());
                    final docs = snap.data?.docs ?? const [];
                    if (docs.isEmpty)
                      return const Center(child: Text('No active rentals'));
                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (ctx, i) {
                        final d = docs[i].data();
                        final name = d['vehicleName'] ?? 'Rental Car';
                        final pickup = d['pickupDate'] is Timestamp
                            ? (d['pickupDate'] as Timestamp).toDate()
                            : null;
                        final pickupLabel = pickup != null
                            ? '${pickup.year}-${pickup.month.toString().padLeft(2, '0')}-${pickup.day.toString().padLeft(2, '0')}'
                            : (d['pickupDateLabel'] ?? '');
                        final status = d['status'] ?? '—';
                        return ListTile(
                          leading: const Icon(Icons.directions_car),
                          title: Text(name),
                          subtitle: Text('Pickup: $pickupLabel'),
                          trailing: Text(status),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerAvatar extends StatelessWidget {
  const _CustomerAvatar({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    if (url == null || url.isEmpty) {
      return const CircleAvatar(
        radius: 18,
        backgroundColor: Color(0xFFEFF4FF),
        child: Icon(Icons.person_outline, color: _blue, size: 20),
      );
    }

    return ClipOval(
      child: Image.network(
        url,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFEFF4FF),
            child: Icon(Icons.person_outline, color: _blue, size: 20),
          );
        },
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.directions_car_filled_rounded, color: _blue, size: 32),
        SizedBox(width: 8),
        Text(
          'DRIVO',
          style: TextStyle(
            color: _blue,
            fontSize: 23,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;

        return Container(
          constraints: BoxConstraints(minHeight: wide ? 560 : 0),
          padding: EdgeInsets.fromLTRB(wide ? 70 : 24, 52, wide ? 70 : 24, 52),
          decoration: BoxDecoration(
            color: _blue,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _HeroPatternPainter()),
              ),
              Positioned(
                left: wide ? 320 : -40,
                right: wide ? 350 : -60,
                bottom: wide ? 22 : 115,
                child: Opacity(
                  opacity: 0.9,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1100),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(24 * (1 - value), 0),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: Image.asset(
                      'assets/images/hero_blur_car.png',
                      height: wide ? 260 : 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              wide
                  ? const Row(
                      children: [
                        Expanded(child: _HeroCopy()),
                        SizedBox(width: 76),
                        SizedBox(width: 370, child: _BookingCard()),
                      ],
                    )
                  : const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroCopy(),
                        SizedBox(height: 28),
                        _BookingCard(),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final tirePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;
    final softPaint = Paint()..color = Colors.white.withValues(alpha: 0.06);

    canvas.drawCircle(
      Offset(size.width * 0.13, size.height * 0.18),
      130,
      tirePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.13, size.height * 0.18),
      74,
      tirePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.91, size.height * 0.86),
      160,
      tirePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.91, size.height * 0.86),
      92,
      tirePaint,
    );

    final path = Path()
      ..moveTo(size.width * 0.48, size.height)
      ..lineTo(size.width * 0.72, size.height)
      ..quadraticBezierTo(
        size.width * 0.64,
        size.height * 0.52,
        size.width * 0.88,
        0,
      )
      ..lineTo(size.width * 0.68, 0)
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.42,
        size.width * 0.48,
        size.height,
      )
      ..close();
    canvas.drawPath(path, softPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Experience the road\nlike never before',
          style: TextStyle(
            color: Colors.white,
            fontSize: 42,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 22),
        const SizedBox(
          width: 370,
          child: Text(
            'Reserve clean, road-ready vehicles for daily trips, business travel, and family getaways at clear daily rates.',
            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
          ),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ViewAllCarsPage()),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: _orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('View all cars'),
        ),
      ],
    );
  }
}

class _BookingCard extends StatefulWidget {
  const _BookingCard();

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  String _type = 'Sedan';
  String _model = 'Mercedes';
  String _gear = 'Automatic';
  String _fuel = 'PB 95';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Book your car',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          _BookingDropdown(
            value: _type,
            values: const ['Sedan', 'SUV', 'Sport', 'Minivan'],
            label: 'Car type',
            onChanged: (value) => setState(() => _type = value),
          ),
          _BookingDropdown(
            value: _model,
            values: const ['Mercedes', 'Toyota', 'Porsche'],
            label: 'Car model',
            onChanged: (value) => setState(() => _model = value),
          ),
          _BookingDropdown(
            value: _gear,
            values: const ['Automatic', 'Manual'],
            label: 'Gear box',
            onChanged: (value) => setState(() => _gear = value),
          ),
          _BookingDropdown(
            value: _fuel,
            values: const ['PB 95', 'Diesel', 'Hybrid'],
            label: 'Fuel type',
            onChanged: (value) => setState(() => _fuel = value),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Selected $_model $_type for booking.'),
                  behavior: SnackBarBehavior.floating,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text('Book now'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingDropdown extends StatelessWidget {
  const _BookingDropdown({
    required this.value,
    required this.values,
    required this.label,
    required this.onChanged,
  });

  final String value;
  final List<String> values;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: values
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
        decoration: InputDecoration(
          hintText: label,
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip();

  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureData(
        Icons.pin_drop_outlined,
        'Easy pickup',
        'Choose a pickup location and get your reserved car ready on schedule.',
      ),
      _FeatureData(
        Icons.car_rental_rounded,
        'Reliable fleet',
        'Browse sedans, SUVs, vans, and premium cars maintained for safe rentals.',
      ),
      _FeatureData(
        Icons.account_balance_wallet_outlined,
        'Clear pricing',
        'See the daily rental rate before booking with no confusing add-ons.',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        return Wrap(
          spacing: wide ? 90 : 18,
          runSpacing: 28,
          alignment: WrapAlignment.spaceEvenly,
          children: features
              .map(
                (feature) => SizedBox(
                  width: wide ? 250 : constraints.maxWidth,
                  child: _FeatureItem(feature: feature),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _FeatureData {
  const _FeatureData(this.icon, this.title, this.description);

  final IconData icon;
  final String title;
  final String description;
}

class _FeatureItem extends StatefulWidget {
  const _FeatureItem({required this.feature});

  final _FeatureData feature;

  @override
  State<_FeatureItem> createState() => _FeatureItemState();
}

class _FeatureItemState extends State<_FeatureItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _iconElevation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _iconElevation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _ctrl.forward(),
      onExit: (_) => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _iconElevation,
              builder: (context, child) => Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    const Color(0xFFF0F4FF),
                    const Color(0xFFDDE6FF),
                    _iconElevation.value,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _blue.withValues(
                        alpha: 0.08 + _iconElevation.value * 0.14,
                      ),
                      blurRadius: 8 + _iconElevation.value * 16,
                      offset: Offset(0, 4 + _iconElevation.value * 6),
                    ),
                  ],
                ),
                child: Icon(
                  widget.feature.icon,
                  size: 34,
                  color: Color.lerp(Colors.black, _blue, _iconElevation.value),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.feature.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              widget.feature.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        final image = _HandoffImage(wide: wide);
        final steps = Column(
          children: const [
            _StepItem(
              1,
              'Find the right vehicle',
              'Search available cars by body type, capacity, transmission, and daily rate.',
            ),
            _StepItem(
              2,
              'Review rental details',
              'Check the seats, fuel type, plate number, and vehicle status before booking.',
            ),
            _StepItem(
              3,
              'Send your rental request',
              'Choose your pickup and return dates so the team can prepare the car.',
            ),
            _StepItem(
              4,
              'Pick up and drive',
              'Bring your valid license, confirm the booking, and start your trip.',
            ),
          ],
        );

        if (!wide) {
          return Column(children: [image, const SizedBox(height: 28), steps]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: constraints.maxWidth * 0.43, child: image),
            const SizedBox(width: 80),
            Expanded(child: steps),
          ],
        );
      },
    );
  }
}

class _HandoffImage extends StatelessWidget {
  const _HandoffImage({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: wide ? 1.12 : 1.18,
          child: Image.asset(
            'assets/images/customer_key_handoff.png',
            fit: BoxFit.cover,
            alignment: const Alignment(-0.65, 0),
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFFF2F5FA),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.car_rental_rounded,
                  color: _blue,
                  size: 54,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StepItem extends StatefulWidget {
  const _StepItem(this.number, this.title, this.description);

  final int number;
  final String title;
  final String description;

  @override
  State<_StepItem> createState() => _StepItemState();
}

class _StepItemState extends State<_StepItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bg;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _bg = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _ctrl.forward(),
      onExit: (_) => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _bg,
        builder: (context, child) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.transparent,
              const Color(0xFFF0F4FF),
              _bg.value,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: _blue,
              child: Text(
                '${widget.number}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.description,
                    style: const TextStyle(color: _muted, height: 1.45),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Live cars section ────────────────────────────────────────────────────────

class _CarsSection extends StatefulWidget {
  const _CarsSection();

  @override
  State<_CarsSection> createState() => _CarsSectionState();
}

class _CarsSectionState extends State<_CarsSection> {
  late final Stream<List<_HomeCar>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('vehicles')
        .snapshots()
        .map((snapshot) {
          final cars = snapshot.docs.map(_HomeCar.fromDoc).toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          return cars.take(6).toList();
        })
        .handleError((Object error) {
          debugPrint('Home cars stream error: $error');
        });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<_HomeCar>>(
      stream: _stream,
      builder: (context, snapshot) {
        final cars = snapshot.data ?? const <_HomeCar>[];
        final loading =
            snapshot.connectionState == ConnectionState.waiting && cars.isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Text(
                    'Choose the car that suits you',
                    style: TextStyle(
                      color: _text,
                      fontSize: 26,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ViewAllCarsPage()),
                  ),
                  icon: const Text('View All'),
                  label: const Icon(Icons.arrow_forward, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 30),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: CircularProgressIndicator(color: _blue),
                ),
              )
            else if (cars.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Text(
                    'No cars available yet.',
                    style: TextStyle(color: _muted, fontSize: 15),
                  ),
                ),
              )
            else
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _HomeCarGrid(key: ValueKey(cars.length), cars: cars),
              ),
          ],
        );
      },
    );
  }
}

// ── Staggered car grid ────────────────────────────────────────────────────────

class _HomeCarGrid extends StatefulWidget {
  const _HomeCarGrid({super.key, required this.cars});

  final List<_HomeCar> cars;

  @override
  State<_HomeCarGrid> createState() => _HomeCarGridState();
}

class _HomeCarGridState extends State<_HomeCarGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 300 + (widget.cars.length.clamp(1, 6) * 70),
      ),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 960
            ? 3
            : width >= 620
            ? 2
            : 1;
        final gap = columns == 1 ? 18.0 : 28.0;
        final cardWidth = (width - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: 28,
          children: widget.cars.asMap().entries.map((entry) {
            final index = entry.key;
            final car = entry.value;
            final start = (index * 0.10).clamp(0.0, 0.72);
            final end = (start + 0.28).clamp(0.0, 1.0);
            final interval = CurvedAnimation(
              parent: _ctrl,
              curve: Interval(start, end, curve: Curves.easeOutCubic),
            );
            return SizedBox(
              width: cardWidth,
              child: FadeTransition(
                opacity: interval,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.14),
                    end: Offset.zero,
                  ).animate(interval),
                  child: _CarCard(car),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _HomeCar {
  const _HomeCar({
    required this.id,
    required this.name,
    required this.category,
    required this.transmission,
    required this.fuel,
    required this.seats,
    required this.dailyRate,
    required this.status,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String category;
  final String transmission;
  final String fuel;
  final int seats;
  final int dailyRate;
  final String status;
  final String? imageUrl;

  bool get isAvailable => status.toLowerCase() == 'available';

  factory _HomeCar.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return _HomeCar(
      id: doc.id,
      name: _strVal(d, ['name', 'vehicleName', 'title'], 'Unnamed car'),
      category: _strVal(d, ['category', 'type', 'bodyType'], 'Sedan'),
      transmission: _strVal(d, [
        'transmission',
        'gear',
        'gearbox',
      ], 'Automatic'),
      fuel: _strVal(d, ['fuel', 'fuelType', 'fuel_type'], 'Gasoline'),
      seats: _intVal(d, ['seats', 'capacity', 'passengers'], 4),
      dailyRate: _intVal(d, ['dailyRate', 'daily_rate', 'rate', 'price'], 0),
      status: _strVal(d, ['status', 'availability'], 'available'),
      imageUrl: _imgVal(d),
    );
  }

  static String _strVal(
    Map<String, dynamic> d,
    List<String> keys,
    String fallback,
  ) {
    for (final k in keys) {
      final v = d[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v != null && v is! List && '$v'.trim().isNotEmpty) return '$v'.trim();
    }
    return fallback;
  }

  static int _intVal(Map<String, dynamic> d, List<String> keys, int fallback) {
    for (final k in keys) {
      final v = d[k];
      if (v is int) return v;
      if (v is double) return v.round();
      if (v is String) {
        final p = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
        if (p != null) return p;
      }
    }
    return fallback;
  }

  static String? _imgVal(Map<String, dynamic> d) {
    for (final k in ['imageUrl', 'image_url', 'photoUrl', 'photo_url']) {
      final v = d[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    for (final k in ['imageUrls', 'image_urls', 'images']) {
      final v = d[k];
      if (v is List && v.isNotEmpty) {
        final first = v.first;
        if (first is String && first.trim().isNotEmpty) return first.trim();
        if (first is Map && first['image_url'] is String) {
          return (first['image_url'] as String).trim();
        }
        if (first is Map && first['url'] is String) {
          return (first['url'] as String).trim();
        }
      }
    }
    return null;
  }
}

// ── Car card ──────────────────────────────────────────────────────────────────

class _CarCard extends StatefulWidget {
  const _CarCard(this.car);

  final _HomeCar car;

  @override
  State<_CarCard> createState() => _CarCardState();
}

class _CarCardState extends State<_CarCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverCtrl;
  late final Animation<double> _elevation;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _elevation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut));
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.025,
    ).animate(CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _hoverCtrl.forward(),
      onExit: (_) => _hoverCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _hoverCtrl,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Color.lerp(
                  const Color(0xFFE8ECF4),
                  _blue.withValues(alpha: 0.28),
                  _elevation.value,
                )!,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.04 + _elevation.value * 0.08,
                  ),
                  blurRadius: 8 + _elevation.value * 20,
                  offset: Offset(0, 4 + _elevation.value * 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 142,
              width: double.infinity,
              child:
                  widget.car.imageUrl != null && widget.car.imageUrl!.isNotEmpty
                  ? Image.network(
                      widget.car.imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => CustomPaint(
                        painter: _CarSilhouettePainter(),
                        child: const SizedBox.expand(),
                      ),
                    )
                  : CustomPaint(
                      painter: _CarSilhouettePainter(),
                      child: const SizedBox.expand(),
                    ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.car.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.car.category,
                        style: const TextStyle(color: _muted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _money(widget.car.dailyRate),
                      style: const TextStyle(
                        color: _blue,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text('per day', style: TextStyle(color: _muted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _CarSpec(Icons.settings, widget.car.transmission),
                _CarSpec(Icons.local_gas_station, widget.car.fuel),
                _CarSpec(Icons.people, '${widget.car.seats} seats'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: widget.car.isAvailable
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CarDetailsPage(carId: widget.car.id),
                        ),
                      )
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  disabledBackgroundColor: const Color(0xFFCAD3E1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.car.isAvailable ? 'Rent Now' : 'Unavailable',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _money(int value) {
  final amount = value.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return '₱$amount';
}

class _CarSpec extends StatelessWidget {
  const _CarSpec(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: _muted, fontSize: 12)),
      ],
    );
  }
}

class _CarSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFD4D4D4);
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.05);
    final path = Path()
      ..moveTo(size.width * 0.10, size.height * 0.64)
      ..quadraticBezierTo(
        size.width * 0.16,
        size.height * 0.38,
        size.width * 0.34,
        size.height * 0.36,
      )
      ..lineTo(size.width * 0.56, size.height * 0.36)
      ..quadraticBezierTo(
        size.width * 0.70,
        size.height * 0.38,
        size.width * 0.82,
        size.height * 0.56,
      )
      ..quadraticBezierTo(
        size.width * 0.92,
        size.height * 0.58,
        size.width * 0.94,
        size.height * 0.70,
      )
      ..lineTo(size.width * 0.09, size.height * 0.70)
      ..close();

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.82),
        width: size.width * 0.74,
        height: size.height * 0.12,
      ),
      shadow,
    );
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      Offset(size.width * 0.27, size.height * 0.70),
      size.width * 0.055,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.70),
      size.width * 0.055,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = constraints.maxWidth >= 1400
            ? 72.0
            : constraints.maxWidth >= 900
            ? 48.0
            : 18.0;

        return Column(
          children: [
            const Divider(color: _line, height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(inset, 32, inset, 28),
              child: Column(
                children: [
                  Wrap(
                    spacing: 64,
                    runSpacing: 34,
                    alignment: WrapAlignment.spaceBetween,
                    children: const [
                      _FooterBrand(),
                      _FooterContact(
                        icon: Icons.location_on,
                        title: 'Address',
                        value: 'Tacloban city leyte',
                      ),
                      _FooterContact(
                        icon: Icons.email_outlined,
                        title: 'Email',
                        value: 'Shandonvillacarlos15@gmail.com',
                      ),
                      _FooterContact(
                        icon: Icons.phone,
                        title: 'Phone',
                        value: '+63 951 801 9568',
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  const Text(
                    'Copyright DRIVO Car Rental 2026. All rights reserved.',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car_filled_rounded, color: Colors.black),
              SizedBox(width: 8),
              Text('Car Rental', style: TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          SizedBox(height: 28),
          Text(
            'Book dependable rental cars for city drives, airport transfers, business trips, and weekend travel.',
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterContact extends StatelessWidget {
  const _FooterContact({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _blue,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: _muted)),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
