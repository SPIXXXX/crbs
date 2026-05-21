import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'customer_profile_page.dart';
import 'rental_checkout_page.dart';

// ─── Color tokens (matches your existing design system) ───────────────────────
const _blue = Color(0xFF3568E8);
const _text = Color(0xFF111827);
const _muted = Color(0xFF697386);
const _line = Color(0xFFE8ECF4);
const _soft = Color(0xFFF6F8FC);
const _red = Color(0xFFFF4D4F);
const _green = Color(0xFF17A34A);
const _greenBg = Color(0xFFEFFAF3);
const _redBg = Color(0xFFFFF2F2);
const _starActive = Color(0xFFFFBC11);

// ─── Entry point ──────────────────────────────────────────────────────────────

class CarDetailsPage extends StatefulWidget {
  const CarDetailsPage({super.key, required this.carId});

  final String carId;

  @override
  State<CarDetailsPage> createState() => _CarDetailsPageState();
}

class _CarDetailsPageState extends State<CarDetailsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pageCtrl;
  late final Animation<double> _pageFade;
  late final Animation<Offset> _pageSlide;

  @override
  void initState() {
    super.initState();
    _pageCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 540),
    )..forward();
    _pageFade = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _pageFade,
          child: SlideTransition(
            position: _pageSlide,
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('vehicles')
                  .doc(widget.carId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _blue),
                  );
                }

                final data = snapshot.data?.data();
                if (data == null) {
                  return const Center(
                    child: Text(
                      'Car not found.',
                      style: TextStyle(color: _muted),
                    ),
                  );
                }

                final car = _CarDetail.fromData(widget.carId, data);

                return Column(
                  children: [
                    _DetailsTopBar(onBack: () => Navigator.maybePop(context)),
                    Expanded(child: _CarDetailsBody(car: car)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _DetailsTopBar extends StatelessWidget {
  const _DetailsTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: _text),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.directions_car_filled_rounded,
            color: _blue,
            size: 28,
          ),
          const SizedBox(width: 6),
          const Text(
            'CRBS',
            style: TextStyle(
              color: _blue,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          StreamBuilder<User?>(
            stream: _userChanges(),
            builder: (context, snap) {
              final user = snap.data;
              if (user == null) return const SizedBox.shrink();

              final name = user.displayName?.trim().isNotEmpty == true
                  ? user.displayName!.trim()
                  : user.email ?? 'Customer';
              final url = user.photoURL;

              return Tooltip(
                message: 'View profile',
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustomerProfilePage(),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(999),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      url != null && url.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                url,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Color(0xFFEFF4FF),
                                  child: Icon(
                                    Icons.person_outline,
                                    color: _blue,
                                    size: 20,
                                  ),
                                ),
                              ),
                            )
                          : const CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFFEFF4FF),
                              child: Icon(
                                Icons.person_outline,
                                color: _blue,
                                size: 20,
                              ),
                            ),
                      const SizedBox(width: 10),
                      Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Stream<User?> _userChanges() {
    try {
      return FirebaseAuth.instance.userChanges();
    } catch (_) {
      return Stream<User?>.value(null);
    }
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _CarDetailsBody extends StatelessWidget {
  const _CarDetailsBody({required this.car});

  final _CarDetail car;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 860;
          final inset = wide ? 48.0 : 20.0;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: inset, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Main details block ──────────────────────────────────────
                wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: _CarLeftPanel(car: car)),
                          const SizedBox(width: 48),
                          Expanded(flex: 6, child: _TechSpecPanel(car: car)),
                        ],
                      )
                    : Column(
                        children: [
                          _CarLeftPanel(car: car),
                          const SizedBox(height: 32),
                          _TechSpecPanel(car: car),
                        ],
                      ),
                const SizedBox(height: 48),

                // ── Reviews ────────────────────────────────────────────────
                _ReviewsSection(carId: car.id),
                const SizedBox(height: 64),

                // ── Other cars ─────────────────────────────────────────────
                _OtherCarsSection(excludeId: car.id),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Left panel: image + photo strip ─────────────────────────────────────────

class _CarLeftPanel extends StatefulWidget {
  const _CarLeftPanel({required this.car});

  final _CarDetail car;

  @override
  State<_CarLeftPanel> createState() => _CarLeftPanelState();
}

class _CarLeftPanelState extends State<_CarLeftPanel> {
  int _selectedPhotoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.car.imageUrls;
    final mainUrl = photos.isNotEmpty ? photos[_selectedPhotoIndex] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.car.name,
          style: const TextStyle(
            color: _text,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              _money(widget.car.dailyRate),
              style: const TextStyle(
                color: _blue,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(' / day', style: TextStyle(color: _muted, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 24),

        // Main image
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _soft,
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: mainUrl != null
              ? Image.network(mainUrl, fit: BoxFit.contain)
              : const _CarSilhouettePlaceholder(),
        ),

        // Photo strip
        if (photos.length > 1) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final selected = index == _selectedPhotoIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPhotoIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? _blue : _line,
                        width: selected ? 2.5 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(photos[index], fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Technical spec panel ─────────────────────────────────────────────────────

class _TechSpecPanel extends StatefulWidget {
  const _TechSpecPanel({required this.car});

  final _CarDetail car;

  @override
  State<_TechSpecPanel> createState() => _TechSpecPanelState();
}

class _TechSpecPanelState extends State<_TechSpecPanel> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final car = widget.car;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading + heart
        Row(
          children: [
            const Expanded(
              child: Text(
                'Technical Specification',
                style: TextStyle(
                  color: _text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _liked = !_liked),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  _liked ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey(_liked),
                  color: _liked ? _red : _muted,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Status pill
        Row(children: [_StatusPill(status: car.status)]),
        const SizedBox(height: 18),

        // Spec grid
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SpecCard(
              icon: Icons.settings,
              label: 'Gear Box',
              value: car.transmission,
            ),
            _SpecCard(
              icon: Icons.local_gas_station,
              label: 'Fuel',
              value: car.fuel,
            ),
            _SpecCard(
              icon: Icons.door_front_door_outlined,
              label: 'Doors',
              value: '${car.doors}',
            ),
            _SpecCard(
              icon: Icons.ac_unit,
              label: 'Air Conditioner',
              value: car.hasAC ? 'Yes' : 'No',
            ),
            _SpecCard(
              icon: Icons.people_outlined,
              label: 'Seats',
              value: '${car.seats}',
            ),
            _SpecCard(
              icon: Icons.speed,
              label: 'Mileage',
              value: car.mileage > 0 ? '${car.mileage} km' : 'N/A',
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Plate number
        if (car.plateNumber.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.confirmation_number_outlined,
                  color: _muted,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Plate No: ${car.plateNumber}',
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

        // Rent button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: car.isAvailable
                ? () => _showRentDialog(context, car)
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: _blue,
              disabledBackgroundColor: const Color(0xFFCAD3E1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              car.isAvailable ? 'Rent a car' : 'Not Available',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  void _showRentDialog(BuildContext context, _CarDetail car) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RentalCheckoutPage(
          carId: car.id,
          carName: car.name,
          carCategory: car.category,
          carImageUrl: car.imageUrls.isNotEmpty
              ? car.imageUrls.first
              : car.imageUrl,
          dailyRate: car.dailyRate,
        ),
      ),
    );
  }
}

class _SpecCard extends StatelessWidget {
  const _SpecCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _muted, size: 22),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _text,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final available = status.toLowerCase() == 'available';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: available ? _greenBg : _redBg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: available ? _green : _red,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ─── Reviews section ──────────────────────────────────────────────────────────

class _ReviewsSection extends StatefulWidget {
  const _ReviewsSection({required this.carId});

  final String carId;

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('vehicleId', isEqualTo: widget.carId)
          .snapshots(),
      builder: (context, snapshot) {
        // Sort client-side — no composite index needed
        final reviews =
            (snapshot.data?.docs.map((doc) => _Review.fromDoc(doc)).toList() ??
                  <_Review>[])
              ..sort((a, b) {
                final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
                final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
                return bt.compareTo(at);
              });
        final total = reviews.length;
        final avgRating = total == 0
            ? 0.0
            : reviews.map((r) => r.rating).reduce((a, b) => a + b) / total;
        final visible = _showAll ? reviews : reviews.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Row(
              children: [
                const Text(
                  'Reviews',
                  style: TextStyle(
                    color: _text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '$total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (total > 0) ...[
                  const SizedBox(width: 14),
                  _StarRow(rating: avgRating),
                  const SizedBox(width: 6),
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // ── Write a review ─────────────────────────────────────────────
            _WriteReviewBox(carId: widget.carId),
            const SizedBox(height: 24),

            // ── Review list ────────────────────────────────────────────────
            if (reviews.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No reviews yet. Be the first to leave one!',
                  style: TextStyle(color: _muted),
                ),
              )
            else
              ...visible.asMap().entries.map(
                (e) => _ReviewCard(
                  review: e.value,
                  carId: widget.carId,
                  index: e.key,
                ),
              ),

            if (total > 3)
              TextButton.icon(
                onPressed: () => setState(() => _showAll = !_showAll),
                icon: Icon(
                  _showAll
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                ),
                label: Text(_showAll ? 'Show Less' : 'Show All'),
              ),
          ],
        );
      },
    );
  }
}

class _WriteReviewBox extends StatefulWidget {
  const _WriteReviewBox({required this.carId});

  final String carId;

  @override
  State<_WriteReviewBox> createState() => _WriteReviewBoxState();
}

class _WriteReviewBoxState extends State<_WriteReviewBox>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  int _rating = 5;
  bool _saving = false;

  late final AnimationController _enterCtrl;
  late final Animation<double> _enterFade;
  late final Animation<Offset> _enterSlide;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _enterFade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _enterSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _message('Please sign in to leave a review.');
      return;
    }

    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      _message('Please write something before submitting.');
      return;
    }

    setState(() => _saving = true);
    try {
      // Resolve display name: prefer Auth profile, fall back to Firestore
      String displayName = user.displayName?.trim() ?? '';
      if (displayName.isEmpty) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 6));
          final n = doc.data()?['name'];
          if (n is String && n.trim().isNotEmpty) {
            displayName = n.trim();
          }
        } catch (_) {}
      }
      if (displayName.isEmpty) {
        displayName = user.email?.split('@').first ?? 'Customer';
      }

      await FirebaseFirestore.instance.collection('reviews').add({
        'vehicleId': widget.carId,
        'uid': user.uid,
        'displayName': displayName,
        'photoUrl': user.photoURL ?? '',
        'email': user.email ?? '',
        'rating': _rating,
        'comment': text,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _ctrl.clear();
      setState(() => _rating = 5);
      _message('Review submitted. Thank you!');
    } on FirebaseException catch (e) {
      if (mounted) _message(e.message ?? 'Could not submit review.');
    } on Exception catch (e) {
      if (mounted) _message('Could not submit review: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _enterFade,
      child: SlideTransition(
        position: _enterSlide,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _soft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Write a Review',
                style: TextStyle(
                  color: _text,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              // Star rating picker
              Row(
                children: List.generate(5, (i) {
                  final filled = i < _rating;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: filled ? _starActive : _muted,
                        size: 28,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ctrl,
                maxLines: 3,
                style: const TextStyle(color: _text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Share your experience with this car...',
                  hintStyle: const TextStyle(color: _muted, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _blue),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: _saving ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: Text(_saving ? 'Submitting...' : 'Submit Review'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Animated review card with Facebook-style 3-dot menu
class _ReviewCard extends StatefulWidget {
  const _ReviewCard({
    required this.review,
    required this.carId,
    this.index = 0,
  });

  final _Review review;
  final String carId;
  final int index;

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    // Stagger each card by 80 ms
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
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
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid != null && currentUid == widget.review.uid;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReviewAvatar(
                      photoUrl: widget.review.photoUrl,
                      name: widget.review.displayName,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.review.displayName,
                            style: const TextStyle(
                              color: _text,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              _StarRow(rating: widget.review.rating.toDouble()),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(widget.review.createdAt),
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 3-dot menu — only visible to review owner
                    if (isOwner)
                      _ReviewMenu(
                        onEdit: () => _showEditDialog(context),
                        onDelete: () => _confirmDelete(context),
                      ),
                  ],
                ),
              ),
              // ── Comment body ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Text(
                  widget.review.comment,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) =>
          _EditReviewDialog(carId: widget.carId, review: widget.review),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Review',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'This review will be permanently deleted. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: _red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('reviews')
            .doc(widget.review.id)
            .delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review deleted.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } on FirebaseException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message ?? 'Could not delete review.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}

// Facebook-style 3-dot popup menu
class _ReviewMenu extends StatelessWidget {
  const _ReviewMenu({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      offset: const Offset(0, 36),
      icon: const Icon(Icons.more_horiz_rounded, color: _muted, size: 22),
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_outlined, color: _blue, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Edit',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: _red,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: _red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditReviewDialog extends StatefulWidget {
  const _EditReviewDialog({required this.carId, required this.review});

  final String carId;
  final _Review review;

  @override
  State<_EditReviewDialog> createState() => _EditReviewDialogState();
}

class _EditReviewDialogState extends State<_EditReviewDialog> {
  late final TextEditingController _ctrl;
  late int _rating;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.review.comment);
    _rating = widget.review.rating;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.review.id)
          .update({
            'rating': _rating,
            'comment': text,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review updated.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Could not update review.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Review'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rating', style: TextStyle(color: _muted, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: filled ? _starActive : _muted,
                      size: 28,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _ctrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Update your review...',
                hintStyle: const TextStyle(color: _muted),
                filled: true,
                fillColor: _soft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _blue),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: _blue),
          child: Text(_saving ? 'Saving...' : 'Save Changes'),
        ),
      ],
    );
  }
}

class _ReviewAvatar extends StatelessWidget {
  const _ReviewAvatar({required this.photoUrl, required this.name});

  final String photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _initials(name),
        ),
      );
    }
    return _initials(name);
  }

  Widget _initials(String name) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 22,
      backgroundColor: _blue.withValues(alpha: 0.12),
      child: Text(
        letter,
        style: const TextStyle(
          color: _blue,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return const Icon(Icons.star_rounded, color: _starActive, size: 16);
        } else if (i < rating) {
          return const Icon(
            Icons.star_half_rounded,
            color: _starActive,
            size: 16,
          );
        } else {
          return const Icon(
            Icons.star_outline_rounded,
            color: _starActive,
            size: 16,
          );
        }
      }),
    );
  }
}

// ─── Other cars section ───────────────────────────────────────────────────────

class _OtherCarsSection extends StatefulWidget {
  const _OtherCarsSection({required this.excludeId});

  final String excludeId;

  @override
  State<_OtherCarsSection> createState() => _OtherCarsSectionState();
}

class _OtherCarsSectionState extends State<_OtherCarsSection> {
  late final Stream<List<_CarDetail>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('vehicles')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => _CarDetail.fromData(doc.id, doc.data()))
              .where((car) => car.id != widget.excludeId)
              .take(6)
              .toList(),
        )
        .handleError((Object e) => debugPrint('Other cars error: $e'));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<_CarDetail>>(
      stream: _stream,
      builder: (context, snapshot) {
        final cars = snapshot.data ?? const <_CarDetail>[];
        if (cars.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Other Cars You Might Like',
              style: TextStyle(
                color: _text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = width >= 900
                    ? 3
                    : width >= 580
                    ? 2
                    : 1;
                const gap = 20.0;
                final cardWidth = (width - (gap * (columns - 1))) / columns;

                return Wrap(
                  spacing: gap,
                  runSpacing: 20,
                  children: cars
                      .map(
                        (car) => SizedBox(
                          width: cardWidth,
                          child: _OtherCarCard(car: car),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _OtherCarCard extends StatefulWidget {
  const _OtherCarCard({required this.car});

  final _CarDetail car;

  @override
  State<_OtherCarCard> createState() => _OtherCarCardState();
}

class _OtherCarCardState extends State<_OtherCarCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverCtrl;
  late final Animation<double> _elevation;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
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
    final car = widget.car;

    return MouseRegion(
      onEnter: (_) => _hoverCtrl.forward(),
      onExit: (_) => _hoverCtrl.reverse(),
      child: GestureDetector(
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CarDetailsPage(carId: car.id)),
        ),
        child: AnimatedBuilder(
          animation: _hoverCtrl,
          builder: (context, child) => Transform.scale(
            scale: _scale.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color.lerp(
                    _line,
                    _blue.withValues(alpha: 0.28),
                    _elevation.value,
                  )!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.035 + _elevation.value * 0.07,
                    ),
                    blurRadius: 8 + _elevation.value * 18,
                    offset: Offset(0, 3 + _elevation.value * 8),
                  ),
                ],
              ),
              child: child,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          car.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _text,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          car.category,
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    car.isAvailable ? Icons.favorite_border : Icons.block,
                    color: car.isAvailable ? _muted : _red,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                width: double.infinity,
                child: car.imageUrl != null
                    ? Image.network(car.imageUrl!, fit: BoxFit.contain)
                    : const _CarSilhouettePlaceholder(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _MiniSpec(Icons.local_gas_station, car.fuel),
                  _MiniSpec(Icons.settings, car.transmission),
                  _MiniSpec(Icons.people, '${car.seats}'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _money(car.dailyRate),
                      style: const TextStyle(
                        color: _text,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    width: 96,
                    child: FilledButton(
                      onPressed: car.isAvailable
                          ? () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CarDetailsPage(carId: car.id),
                              ),
                            )
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        disabledBackgroundColor: const Color(0xFFCAD3E1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        car.isAvailable ? 'Rent Now' : 'N/A',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniSpec extends StatelessWidget {
  const _MiniSpec(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _muted),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
      ],
    );
  }
}

// ─── Rent dialog ──────────────────────────────────────────────────────────────

class _RentDialog extends StatefulWidget {
  const _RentDialog({required this.car});

  final _CarDetail car;

  @override
  State<_RentDialog> createState() => _RentDialogState();
}

class _RentDialogState extends State<_RentDialog> {
  DateTime? _pickupDate;
  DateTime? _returnDate;
  bool _saving = false;
  late String _pickupLocation;
  static const _locations = [
    'CRBS Main Branch',
    'Customer Return Area',
    'Downtown Office',
    'Airport Terminal',
  ];

  @override
  void initState() {
    super.initState();
    _pickupLocation = _locations.first;
  }

  int get _days {
    if (_pickupDate == null || _returnDate == null) return 1;
    return _returnDate!.difference(_pickupDate!).inDays.clamp(1, 365);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rent ${widget.car.name}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.car.category} • ${widget.car.seats} seats • ${widget.car.transmission}',
              style: const TextStyle(color: _muted),
            ),
            const SizedBox(height: 18),
            _DateButton(
              label: 'Pickup date',
              value: _pickupDate,
              onPicked: (d) => setState(() => _pickupDate = d),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _pickupLocation,
              decoration: const InputDecoration(labelText: 'Pickup location'),
              items: _locations
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _pickupLocation = v ?? _locations.first),
            ),
            const SizedBox(height: 10),
            _DateButton(
              label: 'Return date',
              value: _returnDate,
              firstDate: _pickupDate,
              onPicked: (d) => setState(() => _returnDate = d),
            ),
            const SizedBox(height: 18),
            Text(
              'Estimated total: ${_money(widget.car.dailyRate * _days)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: _blue),
          child: Text(_saving ? 'Sending...' : 'Submit Request'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_pickupDate == null || _returnDate == null) {
      _msg('Select pickup and return dates first.');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pop(context);
      return;
    }

    setState(() => _saving = true);
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('bookings')
          .add({
            'vehicleId': widget.car.id,
            'vehicleName': widget.car.name,
            'pickupLocation': _pickupLocation,
            'customerId': user.uid,
            'customerEmail': user.email,
            'pickupDate': Timestamp.fromDate(_pickupDate!),
            'returnDate': Timestamp.fromDate(_returnDate!),
            'days': _days,
            'dailyRate': widget.car.dailyRate,
            'totalFee': widget.car.dailyRate * _days,
            'status': 'Pending',
            'createdAt': FieldValue.serverTimestamp(),
          });

      try {
        await FirebaseFirestore.instance.collection('notifications').add({
          'title': 'New booking',
          'body': '${user.displayName ?? user.email} booked ${widget.car.name}',
          'bookingId': docRef.id,
          'target': 'admin',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      if (!mounted) return;
      Navigator.pop(context);
      _msg('Rental request sent for ${widget.car.name}.');
    } on FirebaseException catch (e) {
      _msg(e.message ?? 'Could not send the rental request.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _msg(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onPicked,
    this.firstDate,
  });

  final String label;
  final DateTime? value;
  final DateTime? firstDate;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final today = DateTime.now();
        final first = firstDate ?? DateTime(today.year, today.month, today.day);
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? first,
          firstDate: first,
          lastDate: today.add(const Duration(days: 365)),
        );
        if (picked != null) onPicked(picked);
      },
      icon: const Icon(Icons.calendar_today_outlined, size: 16),
      label: Text(
        value == null ? label : '${value!.month}/${value!.day}/${value!.year}',
      ),
    );
  }
}

// ─── Car silhouette placeholder ───────────────────────────────────────────────

class _CarSilhouettePlaceholder extends StatelessWidget {
  const _CarSilhouettePlaceholder();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SilhouettePainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.05);
    final body = Paint()..color = const Color(0xFFD4D4D4);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.82),
        width: size.width * 0.74,
        height: size.height * 0.12,
      ),
      shadow,
    );
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
    canvas.drawPath(path, body);
    canvas.drawCircle(
      Offset(size.width * 0.27, size.height * 0.70),
      size.width * 0.055,
      body,
    );
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.70),
      size.width * 0.055,
      body,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Data models ──────────────────────────────────────────────────────────────

class _CarDetail {
  const _CarDetail({
    required this.id,
    required this.name,
    required this.category,
    required this.transmission,
    required this.fuel,
    required this.seats,
    required this.doors,
    required this.dailyRate,
    required this.status,
    required this.plateNumber,
    required this.hasAC,
    required this.mileage,
    this.imageUrl,
    required this.imageUrls,
  });

  final String id;
  final String name;
  final String category;
  final String transmission;
  final String fuel;
  final int seats;
  final int doors;
  final int dailyRate;
  final String status;
  final String plateNumber;
  final bool hasAC;
  final int mileage;
  final String? imageUrl;
  final List<String> imageUrls;

  bool get isAvailable => status.toLowerCase() == 'available';

  factory _CarDetail.fromData(String id, Map<String, dynamic> d) {
    return _CarDetail(
      id: id,
      name: _sv(d, ['name', 'vehicleName', 'title'], 'Unnamed car'),
      category: _sv(d, ['category', 'type', 'bodyType'], 'Sedan'),
      transmission: _sv(d, ['transmission', 'gear', 'gearbox'], 'Automatic'),
      fuel: _sv(d, ['fuel', 'fuelType', 'fuel_type'], 'Gasoline'),
      seats: _iv(d, ['seats', 'capacity', 'passengers'], 4),
      doors: _iv(d, ['doors', 'numDoors'], 4),
      dailyRate: _iv(d, ['dailyRate', 'daily_rate', 'rate', 'price'], 0),
      status: _sv(d, ['status', 'availability'], 'available'),
      plateNumber: _sv(d, ['plateNumber', 'plate_number'], ''),
      hasAC: _bv(d, ['hasAC', 'airConditioner', 'ac'], true),
      mileage: _iv(d, ['mileage', 'distance', 'km'], 0),
      imageUrl: _imgSingle(d),
      imageUrls: _imgList(d),
    );
  }
}

class _Review {
  const _Review({
    required this.id,
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  factory _Review.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final ts = d['createdAt'];
    return _Review(
      id: doc.id,
      uid: _sv(d, ['uid'], ''),
      displayName: _sv(d, ['displayName', 'name'], 'Customer'),
      email: _sv(d, ['email'], ''),
      photoUrl: _sv(d, ['photoUrl', 'photoURL'], ''),
      rating: _iv(d, ['rating'], 5).clamp(1, 5),
      comment: _sv(d, ['comment', 'review', 'text'], ''),
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _sv(Map<String, dynamic> d, List<String> keys, String fallback) {
  for (final k in keys) {
    final v = d[k];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    if (v != null && v is! List && '$v'.trim().isNotEmpty) return '$v'.trim();
  }
  return fallback;
}

int _iv(Map<String, dynamic> d, List<String> keys, int fallback) {
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

bool _bv(Map<String, dynamic> d, List<String> keys, bool fallback) {
  for (final k in keys) {
    final v = d[k];
    if (v is bool) return v;
    if (v is String) {
      return v.toLowerCase() == 'yes' || v.toLowerCase() == 'true';
    }
  }
  return fallback;
}

String? _imgSingle(Map<String, dynamic> d) {
  for (final k in ['imageUrl', 'image_url', 'photoUrl', 'photo_url']) {
    final v = d[k];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  for (final k in ['imageUrls', 'image_urls', 'images']) {
    final v = d[k];
    if (v is List && v.isNotEmpty) {
      final first = v.first;
      if (first is String && first.trim().isNotEmpty) return first.trim();
    }
  }
  return null;
}

List<String> _imgList(Map<String, dynamic> d) {
  final urls = <String>[];
  final single = _imgSingle(d);
  if (single != null) urls.add(single);

  for (final k in ['imageUrls', 'image_urls', 'images']) {
    final v = d[k];
    if (v is List) {
      for (final item in v) {
        String? url;
        if (item is String) {
          url = item.trim();
        } else if (item is Map && item['image_url'] is String) {
          url = (item['image_url'] as String).trim();
        } else if (item is Map && item['url'] is String) {
          url = (item['url'] as String).trim();
        }
        if (url != null && url.isNotEmpty && !urls.contains(url)) urls.add(url);
      }
    }
  }
  return urls.take(4).toList();
}

String _money(int value) {
  final amount = value.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return '₱$amount';
}

String _formatDate(DateTime? dt) {
  if (dt == null) return 'Today';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}
