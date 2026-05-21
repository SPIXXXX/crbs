import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:flutter_map/flutter_map.dart';
import '../../utils/map_keys.dart';
import '../../widgets/map_picker.dart';
// reviews queried directly from Firestore

// ── Design tokens ─────────────────────────────────────────────────────────────
const _blue = Color(0xFF3568E8);
const _text = Color(0xFF1A202C);
const _muted = Color(0xFF90A3BF);
const _line = Color(0xFFE8ECF4);
const _soft = Color(0xFFF6F8FC);
const _white = Colors.white;
const _starActive = Color(0xFFFACC15);

// ── Page ──────────────────────────────────────────────────────────────────────

class RentalCheckoutPage extends StatefulWidget {
  const RentalCheckoutPage({
    super.key,
    this.carId,
    this.carName,
    this.carCategory,
    this.carImageUrl,
    this.dailyRate,
  });

  final String? carId;
  final String? carName;
  final String? carCategory;
  final String? carImageUrl;
  final int? dailyRate;

  @override
  State<RentalCheckoutPage> createState() => _RentalCheckoutPageState();
}

class _RentalCheckoutPageState extends State<RentalCheckoutPage> {
  // Billing
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  // Payment
  final _cardNumberCtrl = TextEditingController();
  final _cardHolderCtrl = TextEditingController();
  final _expDateCtrl = TextEditingController();
  final _cvcCtrl = TextEditingController();

  // Promo
  final _promoCtrl = TextEditingController();

  // Rental selection
  String _pickLocation = 'Select your city';
  String _dropLocation = 'Select your city';
  double? _pickLat;
  double? _pickLng;
  double? _dropLat;
  double? _dropLng;
  DateTime? _pickDate;
  DateTime? _dropDate;
  TimeOfDay? _pickTime;
  TimeOfDay? _dropTime;

  // Map preview controllers to keep previews centered on picked locations
  final MapController _pickMapCtrl = MapController();
  final MapController _dropMapCtrl = MapController();

  bool _useCreditCard = true;
  bool _agreeMarketing = false;
  bool _agreeTerms = false;
  bool _submitting = false;

  // previously had a static list of locations; unused so removed

  int get _days {
    if (_pickDate == null || _dropDate == null) return 1;
    final d = _dropDate!.difference(_pickDate!).inDays;
    return d < 1 ? 1 : d;
  }

  int get _dailyRate => widget.dailyRate ?? 80;
  int get _subtotal => _dailyRate * _days;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _cardNumberCtrl.dispose();
    _cardHolderCtrl.dispose();
    _expDateCtrl.dispose();
    _cvcCtrl.dispose();
    _promoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateFor(bool isPick) async {
    final now = DateTime.now();
    final first = isPick ? now : (_pickDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: first,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _blue)),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isPick) {
        _pickDate = picked;
        if (_dropDate != null && _dropDate!.isBefore(picked)) {
          _dropDate = null;
        }
      } else {
        _dropDate = picked;
      }
    });
  }

  Future<void> _pickTimeFor(bool isPick) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _blue)),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isPick) {
        _pickTime = picked;
      } else {
        _dropTime = picked;
      }
    });
  }

  Future<void> _onRentNow() async {
    if (!_agreeTerms) {
      _snack('Please agree to the terms and conditions.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('Please sign in to complete your booking.');
      return;
    }

    if (_pickDate == null || _dropDate == null) {
      _snack('Please select pickup and return dates.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('bookings')
          .add({
            'vehicleId': widget.carId ?? '',
            'vehicleName': widget.carName ?? 'Rental Car',
            'imageUrl': widget.carImageUrl ?? '',
            'customerId': user.uid,
            'customerEmail': user.email,
            'customerName': _nameCtrl.text.trim(),
            'customerPhone': _phoneCtrl.text.trim(),
            'address': _addressCtrl.text.trim(),
            'city': _cityCtrl.text.trim(),
            'pickupLocation': _pickLocation,
            'dropLocation': _dropLocation,
            'pickupLat': _pickLat,
            'pickupLng': _pickLng,
            'dropLat': _dropLat,
            'dropLng': _dropLng,
            'pickupDate': Timestamp.fromDate(_pickDate!),
            'returnDate': Timestamp.fromDate(_dropDate!),
            'pickupTime': _pickTime?.format(context),
            'dropTime': _dropTime?.format(context),
            'days': _days,
            'dailyRate': _dailyRate,
            'subtotal': _subtotal,
            'totalFee': _subtotal,
            'paymentMethod': _useCreditCard ? 'Credit Card' : 'PayPal',
            'status': 'Pending',
            'createdAt': FieldValue.serverTimestamp(),
          });

      // create admin notification
      try {
        await FirebaseFirestore.instance.collection('notifications').add({
          'title': 'New booking',
          'body':
              '${_nameCtrl.text.trim()} booked ${widget.carName ?? 'a car'}',
          'bookingId': docRef.id,
          'target': 'admin',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      if (!mounted) return;
      _showConfirmation();
    } on Exception catch (e) {
      if (mounted) _snack('Could not place your order. Please try again. $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openMapPicker(bool isPick) async {
    final defaultPos = const ll.LatLng(14.5995, 120.9842);
    final initial = ll.LatLng(
      isPick
          ? (_pickLat ?? defaultPos.latitude)
          : (_dropLat ?? defaultPos.latitude),
      isPick
          ? (_pickLng ?? defaultPos.longitude)
          : (_dropLng ?? defaultPos.longitude),
    );

    final res = await Navigator.push<MapPickerResult?>(
      context,
      MaterialPageRoute(builder: (_) => MapPicker(initialPosition: initial)),
    );

    if (res == null) return;
    setState(() {
      if (isPick) {
        _pickLat = res.latLng.latitude;
        _pickLng = res.latLng.longitude;
        _pickLocation = res.address;
      } else {
        _dropLat = res.latLng.latitude;
        _dropLng = res.latLng.longitude;
        _dropLocation = res.address;
      }
    });
    // Move the corresponding preview map to the chosen location
    final newPos = ll.LatLng(
      isPick ? _pickLat ?? 14.5995 : _dropLat ?? 14.5995,
      isPick ? _pickLng ?? 120.9842 : _dropLng ?? 120.9842,
    );
    if (isPick) {
      _pickMapCtrl.move(newPos, 14);
    } else {
      _dropMapCtrl.move(newPos, 14);
    }
  }

  void _showConfirmation() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF22C55E),
              size: 28,
            ),
            SizedBox(width: 10),
            Text(
              'Order Placed!',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: const Text(
          'Your rental request has been submitted successfully.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: _blue),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Checkout'),
        backgroundColor: _white,
        foregroundColor: _text,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
          children: [
            // Top search bar removed for checkout page
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 860;
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 48 : 16,
                      vertical: 32,
                    ),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 13, child: _buildForm()),
                              const SizedBox(width: 28),
                              SizedBox(width: 340, child: _buildSummary()),
                            ],
                          )
                        : Column(
                            children: [
                              _buildForm(),
                              const SizedBox(height: 24),
                              _buildSummary(),
                            ],
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: 'Billing Info',
          subtitle: 'Please enter your billing info',
          step: 'Step 1 of 4',
          child: _buildBilling(),
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Rental Info',
          subtitle: 'Please select your rental date',
          step: 'Step 2 of 4',
          child: _buildRental(),
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Payment Method',
          subtitle: 'Please enter your payment method',
          step: 'Step 3 of 4',
          child: _buildPayment(),
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Confirmation',
          subtitle:
              'We are getting to the end. Just few clicks and your rental is ready!',
          step: 'Step 4 of 4',
          child: _buildConfirmation(),
        ),
        const SizedBox(height: 20),
        _SafetyBadge(),
      ],
    );
  }

  Widget _buildBilling() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FormField(
                label: 'Name',
                hint: 'Your name',
                controller: _nameCtrl,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _FormField(
                label: 'Phone Number',
                hint: 'Phone number',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _FormField(
                label: 'Address',
                hint: 'Address',
                controller: _addressCtrl,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _FormField(
                label: 'Town / City',
                hint: 'Town or city',
                controller: _cityCtrl,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRental() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pick-Up
        Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: _blue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _blue.withValues(alpha: 0.25),
                  width: 3,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Pick – Up',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 500;
            return wide
                ? Row(
                    children: [
                      Expanded(
                        child: _LocationField(
                          label: 'Locations',
                          address: _pickLocation,
                          onTap: () => _openMapPicker(true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _DateField(
                          label: 'Date',
                          hint: 'Select your date',
                          value: _pickDate,
                          onTap: () => _pickDateFor(true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _TimeField(
                          label: 'Time',
                          hint: 'Select your time',
                          value: _pickTime,
                          onTap: () => _pickTimeFor(true),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _LocationField(
                        label: 'Locations',
                        address: _pickLocation,
                        onTap: () => _openMapPicker(true),
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(height: 12),
                      _DateField(
                        label: 'Date',
                        hint: 'Select your date',
                        value: _pickDate,
                        onTap: () => _pickDateFor(true),
                      ),
                      const SizedBox(height: 12),
                      _TimeField(
                        label: 'Time',
                        hint: 'Select your time',
                        value: _pickTime,
                        onTap: () => _pickTimeFor(true),
                      ),
                    ],
                  );
          },
        ),

        const SizedBox(height: 12),

        // Inline map preview for pick-up (tap to open full picker)
        GestureDetector(
          onTap: () => _openMapPicker(true),
          child: Container(
            height: 180,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: _soft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _line),
            ),
            clipBehavior: Clip.hardEdge,
            child: _buildMapPreview(true),
          ),
        ),

        const SizedBox(height: 24),

        // Drop-Off
        Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF7CC7FF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF7CC7FF).withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Drop – Off',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _text,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Inline map preview for drop-off (tap to open full picker)
        GestureDetector(
          onTap: () => _openMapPicker(false),
          child: Container(
            height: 180,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: _soft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _line),
            ),
            clipBehavior: Clip.hardEdge,
            child: _buildMapPreview(false),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 500;
            return wide
                ? Row(
                    children: [
                      Expanded(
                        child: _LocationField(
                          label: 'Locations',
                          address: _dropLocation,
                          onTap: () => _openMapPicker(false),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _DateField(
                          label: 'Date',
                          hint: 'Select your date',
                          value: _dropDate,
                          onTap: () => _pickDateFor(false),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _TimeField(
                          label: 'Time',
                          hint: 'Select your time',
                          value: _dropTime,
                          onTap: () => _pickTimeFor(false),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _LocationField(
                        label: 'Locations',
                        address: _dropLocation,
                        onTap: () => _openMapPicker(false),
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(height: 12),
                      _DateField(
                        label: 'Date',
                        hint: 'Select your date',
                        value: _dropDate,
                        onTap: () => _pickDateFor(false),
                      ),
                      const SizedBox(height: 12),
                      _TimeField(
                        label: 'Time',
                        hint: 'Select your time',
                        value: _dropTime,
                        onTap: () => _pickTimeFor(false),
                      ),
                    ],
                  );
          },
        ),
      ],
    );
  }

  Widget _buildPayment() {
    return Column(
      children: [
        // Credit Card option
        _PaymentOption(
          selected: _useCreditCard,
          label: 'Credit Card',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // VISA logo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F71),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'VISA',
                  style: TextStyle(
                    color: _white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Mastercard
              SizedBox(
                width: 30,
                height: 20,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEB001B),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF79E1B),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          onChanged: (v) => setState(() => _useCreditCard = v),
        ),
        if (_useCreditCard) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FormField(
                  label: 'Card Number',
                  hint: 'Card number',
                  controller: _cardNumberCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 160,
                child: _FormField(
                  label: 'Expiration Date',
                  hint: 'DD / MM / YY',
                  controller: _expDateCtrl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FormField(
                  label: 'Card Holder',
                  hint: 'Card holder',
                  controller: _cardHolderCtrl,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 160,
                child: _FormField(
                  label: 'CVC',
                  hint: 'CVC',
                  controller: _cvcCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),

        // PayPal option
        _PaymentOption(
          selected: !_useCreditCard,
          label: 'PayPal',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'P',
                style: TextStyle(
                  color: Color(0xFF253B80),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Text(
                'Pay',
                style: TextStyle(
                  color: Color(0xFF179BD7),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Text(
                'Pal',
                style: TextStyle(
                  color: Color(0xFF253B80),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          onChanged: (v) => setState(() => _useCreditCard = !v),
        ),
      ],
    );
  }

  Widget _buildMapPreview(bool isPick) {
    final defaultPos = const ll.LatLng(14.5995, 120.9842);
    final lat = isPick ? _pickLat : _dropLat;
    final lng = isPick ? _pickLng : _dropLng;
    final pos = ll.LatLng(
      lat ?? defaultPos.latitude,
      lng ?? defaultPos.longitude,
    );
    final address = isPick ? _pickLocation : _dropLocation;

    return Stack(
      children: [
        FlutterMap(
          mapController: isPick ? _pickMapCtrl : _dropMapCtrl,
          options: MapOptions(
            initialCenter: pos,
            initialZoom: 14,
            onTap: (tapPos, latlng) => _openMapPicker(isPick),
          ),
          children: [
            TileLayer(
              urlTemplate: getTileUrlTemplate(),
              userAgentPackageName: 'org.crbs.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: pos,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on, color: _blue, size: 32),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          left: 12,
          right: 12,
          top: 8,
          child: Card(
            elevation: 0,
            color: _white.withValues(alpha: 0.9),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                address == 'Select your city'
                    ? 'Tap to choose location'
                    : address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CheckboxRow(
          value: _agreeMarketing,
          onChanged: (v) => setState(() => _agreeMarketing = v ?? false),
          label:
              'I agree with sending an Marketing and newsletter emails. No spam, promised!',
        ),
        const SizedBox(height: 12),
        _CheckboxRow(
          value: _agreeTerms,
          onChanged: (v) => setState(() => _agreeTerms = v ?? false),
          label: 'I agree with our terms and conditions and privacy policy.',
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 160,
          height: 52,
          child: FilledButton(
            onPressed: _submitting ? null : _onRentNow,
            style: FilledButton.styleFrom(
              backgroundColor: _blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: _white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Rent Now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final carName = widget.carName ?? 'Nissan GT – R';
    final carCategory = widget.carCategory ?? 'Sport Car';
    final imageUrl = widget.carImageUrl;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rental Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _text,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Prices may change depending on the length of the rental and the price of your rental car.',
                style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 20),

              // Car info
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 80,
                      height: 56,
                      color: _soft,
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(imageUrl, fit: BoxFit.cover)
                          : const Icon(Icons.directions_car, color: _muted),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          carName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: _text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          carCategory,
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('reviews')
                              .where('vehicleId', isEqualTo: widget.carId ?? '')
                              .snapshots(),
                          builder: (context, snap) {
                            final docs = snap.data?.docs ?? [];
                            final total = docs.length;
                            final avg = total == 0
                                ? 0.0
                                : docs
                                          .map(
                                            (d) =>
                                                (d.data()['rating'] as num?)
                                                    ?.toDouble() ??
                                                0.0,
                                          )
                                          .reduce((a, b) => a + b) /
                                      total;
                            final filled = avg.floor();
                            final hasHalf = (avg - filled) >= 0.5;

                            return Row(
                              children: [
                                ...List.generate(5, (i) {
                                  if (i < filled) {
                                    return const Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: _starActive,
                                    );
                                  }
                                  if (i == filled && hasHalf) {
                                    return const Icon(
                                      Icons.star_half_rounded,
                                      size: 14,
                                      color: _starActive,
                                    );
                                  }
                                  return const Icon(
                                    Icons.star_border_rounded,
                                    size: 14,
                                    color: _muted,
                                  );
                                }),
                                const SizedBox(width: 6),
                                Text(
                                  total > 0
                                      ? '$total review${total == 1 ? '' : 's'}'
                                      : 'No reviews yet',
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(color: _line, height: 1),
              const SizedBox(height: 18),

              // Subtotal
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Subtotal',
                      style: TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    '₱$_subtotal.00',
                    style: const TextStyle(
                      color: _text,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(
                    child: Text(
                      'Tax',
                      style: TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    '₱0',
                    style: TextStyle(
                      color: _text,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Promo
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: _soft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _line),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promoCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Apply promo code',
                          hintStyle: TextStyle(color: _muted, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          _snack('Promo code feature coming soon.'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text(
                        'Apply now',
                        style: TextStyle(
                          color: _text,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Divider(color: _line, height: 1),
              const SizedBox(height: 20),

              // Total
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Rental Price',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _text,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Overall price and includes rental discount',
                          style: TextStyle(color: _muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₱$_subtotal.00',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _text,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Top bar (uses shared TopBar from view_all_cars.dart) ───────────────

// _NavLink removed; TopBar from view_all_cars.dart is used instead

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.step,
    required this.child,
  });

  final String title;
  final String subtitle;
  final String step;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                step,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

// ── Form field ────────────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.inputFormatters,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _text,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: _text, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _muted, fontSize: 14),
            filled: true,
            fillColor: _soft,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
              borderSide: const BorderSide(color: _blue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Dropdown field ────────────────────────────────────────────────────────────

// _DropdownField removed (unused)

// ── Date field ────────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.hint,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String hint;
  final DateTime? value;
  final VoidCallback onTap;

  String _format(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')} / '
        '${dt.month.toString().padLeft(2, '0')} / '
        '${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _text,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _soft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null ? hint : _format(value),
                    style: TextStyle(
                      color: value == null ? _muted : _text,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _muted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Location display field (replaces dropdown + choose-on-map button)
class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.label,
    required this.address,
    required this.onTap,
  });

  final String label;
  final String address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _text,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _soft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    address == 'Select your city'
                        ? 'Tap to choose location'
                        : address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: address == 'Select your city' ? _muted : _text,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(Icons.map_outlined, color: _muted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Time field ────────────────────────────────────────────────────────────────

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.hint,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String hint;
  final TimeOfDay? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _text,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _soft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null ? hint : value!.format(context),
                    style: TextStyle(
                      color: value == null ? _muted : _text,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _muted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Payment option ────────────────────────────────────────────────────────────

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.selected,
    required this.label,
    required this.trailing,
    required this.onChanged,
  });

  final bool selected;
  final String label;
  final Widget trailing;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F4FF) : _soft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _blue.withValues(alpha: 0.4) : _line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? _blue : _muted, width: 2),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: _blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: selected ? _text : _muted,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

// ── Checkbox row ──────────────────────────────────────────────────────────────

class _CheckboxRow extends StatelessWidget {
  const _CheckboxRow({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: _blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: _text, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Safety badge ──────────────────────────────────────────────────────────────

class _SafetyBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _soft,
            shape: BoxShape.circle,
            border: Border.all(color: _line),
          ),
          child: const Icon(
            Icons.verified_user_outlined,
            color: _blue,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All your data are safe',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: _text,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'We are using the most advanced security to provide you the best experience ever.',
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}
