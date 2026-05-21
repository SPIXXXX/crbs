import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/cloudinary_service.dart';
import '../../utils/map_keys.dart';

part 'admin_dashboard_page.dart';
part 'admin_car_rent_page.dart';
part 'admin_calendar.dart';
part 'admin_active_renting_page.dart';

const _blue = Color(0xFF3568E8);
const _darkBlue = Color(0xFF0B4E7A);
const _text = Color(0xFF111827);
const _muted = Color(0xFF90A3BF);
const _line = Color(0xFFE8ECF4);
const _soft = Color(0xFFF6F8FC);
const _red = Color(0xFFFF4D4F);

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _searchCtrl = TextEditingController();
  int _activePage = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/customer', (r) => false);
  }

  Stream<List<_AdminCar>> _carsStream() {
    return FirebaseFirestore.instance.collection('vehicles').snapshots().map((
      snapshot,
    ) {
      final cars = snapshot.docs.map(_AdminCar.fromDoc).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return cars;
    });
  }

  Stream<List<_RentalBooking>> _bookingsStream() {
    return FirebaseFirestore.instance.collection('bookings').snapshots().map((
      snapshot,
    ) {
      final bookings = snapshot.docs.map(_RentalBooking.fromDoc).toList()
        ..sort((a, b) => b.createdSort.compareTo(a.createdSort));
      return bookings;
    });
  }

  Future<void> _deleteCar(_AdminCar car) async {
    await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(car.id)
        .delete();
    _message('${car.name} removed from the car rent list.');
  }

  void _openCarForm({_AdminCar? car}) {
    showDialog<void>(
      context: context,
      builder: (_) => _CarFormDialog(
        car: car,
        onSaved: () => _message(
          car == null
              ? 'Car added. It will now display on the customer page.'
              : 'Car updated.',
        ),
      ),
    );
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          children: [
            _AdminSidebar(
              activePage: _activePage,
              onNavChanged: (page) => setState(() => _activePage = page),
              onLogout: _handleLogout,
            ),
            Expanded(
              child: Column(
                children: [
                  _AdminTopBar(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    onLogout: _handleLogout,
                  ),
                  Expanded(
                    child: StreamBuilder<List<_AdminCar>>(
                      stream: _carsStream(),
                      builder: (context, carsSnapshot) {
                        final cars = carsSnapshot.data ?? const <_AdminCar>[];
                        final loading =
                            carsSnapshot.connectionState ==
                            ConnectionState.waiting;

                        if (_activePage == 1) {
                          return _CarRentPage(
                            cars: _filterCars(cars),
                            loading: loading,
                            onAddCar: () => _openCarForm(),
                            onEditCar: (car) => _openCarForm(car: car),
                            onDeleteCar: _deleteCar,
                          );
                        }

                        if (_activePage == 2) {
                          return StreamBuilder<List<_RentalBooking>>(
                            stream: _bookingsStream(),
                            builder: (context, bookingsSnapshot) {
                              final bookings =
                                  bookingsSnapshot.data ??
                                  const <_RentalBooking>[];
                              return SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  58,
                                  48,
                                  58,
                                  48,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Calendar',
                                      style: TextStyle(
                                        color: _text,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    _AdminCalendar(bookings: bookings),
                                  ],
                                ),
                              );
                            },
                          );
                        }

                        if (_activePage == 3) {
                          return StreamBuilder<List<_RentalBooking>>(
                            stream: _bookingsStream(),
                            builder: (context, bookingsSnapshot) {
                              final bookings =
                                  bookingsSnapshot.data ??
                                  const <_RentalBooking>[];
                              return _ActiveRentingPage(
                                cars: cars,
                                bookings: bookings,
                              );
                            },
                          );
                        }

                        return StreamBuilder<List<_RentalBooking>>(
                          stream: _bookingsStream(),
                          builder: (context, bookingsSnapshot) {
                            return _DashboardPage(
                              cars: cars,
                              bookings:
                                  bookingsSnapshot.data ??
                                  const <_RentalBooking>[],
                              loading: loading,
                              onViewCarRent: () =>
                                  setState(() => _activePage = 1),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_AdminCar> _filterCars(List<_AdminCar> cars) {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return cars;

    return cars.where((car) {
      return car.name.toLowerCase().contains(query) ||
          car.model.toLowerCase().contains(query) ||
          car.category.toLowerCase().contains(query) ||
          car.fuel.toLowerCase().contains(query) ||
          car.transmission.toLowerCase().contains(query);
    }).toList();
  }
}

class _AdminCar {
  const _AdminCar({
    required this.id,
    required this.name,
    required this.model,
    required this.category,
    required this.seats,
    required this.fuel,
    required this.transmission,
    required this.dailyRate,
    required this.status,
    required this.total,
    required this.plateNumber,
    required this.imageUrl,
    required this.imageUrls,
  });

  final String id;
  final String name;
  final String model;
  final String category;
  final int seats;
  final String fuel;
  final String transmission;
  final int dailyRate;
  final String status;
  final int total;
  final String plateNumber;
  final String? imageUrl;
  final List<String> imageUrls;

  bool get isAvailable => status.toLowerCase() == 'available' && (total > 0);

  factory _AdminCar.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return _AdminCar(
      id: doc.id,
      name: _stringValue(data, ['name', 'vehicleName', 'title'], 'Unnamed car'),
      model: _stringValue(data, ['model', 'variant', 'year'], ''),
      category: _stringValue(data, ['category', 'type', 'bodyType'], 'Sedan'),
      seats: _intValue(data, ['seats', 'capacity', 'passengers'], 4),
      fuel: _stringValue(data, ['fuel', 'fuelType', 'fuel_type'], 'Gasoline'),
      transmission: _stringValue(data, [
        'transmission',
        'gear',
        'gearbox',
      ], 'Automatic'),
      dailyRate: _intValue(data, [
        'dailyRate',
        'daily_rate',
        'rate',
        'price',
      ], 0),
      status: _stringValue(data, ['status', 'availability'], 'available'),
      total: _intValue(data, ['total', 'count', 'stock', 'quantity'], 1),
      plateNumber: _stringValue(data, ['plateNumber', 'plate_number'], ''),
      imageUrl: _imageValue(data),
      imageUrls: _imageListValue(data),
    );
  }
}

class _RentalBooking {
  const _RentalBooking({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    required this.category,
    required this.totalFee,
    required this.createdSort,
    required this.dateLabel,
    required this.pickupLocation,
    required this.dropLocation,
    required this.customerName,
    required this.customerPhone,
    required this.days,
    required this.dailyRate,
    required this.status,
    required this.pickupDateLabel,
    required this.dropDateLabel,
    required this.pickupTime,
    required this.dropTime,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
  });

  final String id;
  final String vehicleId;
  final String vehicleName;
  final String category;
  final int totalFee;
  final int createdSort;
  final String dateLabel;
  final String pickupLocation;
  final String dropLocation;
  final String customerName;
  final String customerPhone;
  final int days;
  final int dailyRate;
  final String status;
  final String pickupDateLabel;
  final String dropDateLabel;
  final String pickupTime;
  final String dropTime;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;

  factory _RentalBooking.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final createdAt = data['createdAt'];
    DateTime? date;
    if (createdAt is Timestamp) date = createdAt.toDate();

    DateTime? pickupDate;
    final pd = data['pickupDate'];
    if (pd is Timestamp) pickupDate = pd.toDate();

    DateTime? dropDate;
    final dd = data['returnDate'] ?? data['dropDate'];
    if (dd is Timestamp) dropDate = dd.toDate();

    String _dateStr(DateTime? dt) {
      if (dt == null) return '—';
      return '${dt.day} ${_monthName(dt.month)} ${dt.year}';
    }

    return _RentalBooking(
      id: doc.id,
      vehicleId: _stringValue(data, ['vehicleId', 'vehicle_id'], ''),
      vehicleName: _stringValue(data, [
        'vehicleName',
        'vehicle',
        'name',
      ], 'Rental car'),
      category: _stringValue(data, ['category', 'vehicleCategory'], 'Car Rent'),
      totalFee: _intValue(data, [
        'totalFee',
        'total_fee',
        'price',
        'subtotal',
      ], 0),
      createdSort: date?.millisecondsSinceEpoch ?? 0,
      dateLabel: date == null
          ? 'Today'
          : '${date.day} ${_monthName(date.month)}',
      pickupLocation: _stringValue(data, [
        'pickupLocation',
        'pickup_location',
        'location',
      ], 'CRBS Main Branch'),
      dropLocation: _stringValue(data, [
        'dropLocation',
        'drop_location',
        'returnLocation',
      ], 'Customer Return Area'),
      customerName: _stringValue(data, [
        'customerName',
        'customer_name',
        'name',
      ], 'Customer'),
      customerPhone: _stringValue(data, [
        'customerPhone',
        'customer_phone',
        'phone',
      ], '—'),
      days: _intValue(data, ['days', 'rental_days'], 1),
      dailyRate: _intValue(data, ['dailyRate', 'daily_rate', 'rate'], 0),
      status: _stringValue(data, ['status'], 'Pending'),
      pickupDateLabel: _dateStr(pickupDate),
      dropDateLabel: _dateStr(dropDate),
      pickupTime: _stringValue(data, ['pickupTime', 'pickup_time'], '—'),
      dropTime: _stringValue(data, ['dropTime', 'drop_time'], '—'),
      pickupLat: (data['pickupLat'] as num?)?.toDouble(),
      pickupLng: (data['pickupLng'] as num?)?.toDouble(),
      dropLat: (data['dropLat'] as num?)?.toDouble(),
      dropLng: (data['dropLng'] as num?)?.toDouble(),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.activePage,
    required this.onNavChanged,
    this.onLogout,
  });

  final int activePage;
  final ValueChanged<int> onNavChanged;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: _line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 84),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              'MAIN MENU',
              style: TextStyle(
                color: Color(0xFFD1D8E4),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 22),
          _SidebarItem(
            icon: Icons.home_rounded,
            label: 'Dashboard',
            selected: activePage == 0,
            onTap: () => onNavChanged(0),
          ),
          _SidebarItem(
            icon: Icons.directions_car_filled_outlined,
            label: 'Car Rent',
            selected: activePage == 1,
            onTap: () => onNavChanged(1),
          ),
          // Removed: Insight, Reimburse, Inbox (not needed in sidebar)
          _SidebarItem(
            icon: Icons.calendar_month_outlined,
            label: 'Calendar',
            selected: activePage == 2,
            onTap: () => onNavChanged(2),
          ),
          _SidebarItem(
            icon: Icons.car_rental,
            label: 'Active Renting',
            selected: activePage == 3,
            onTap: () => onNavChanged(3),
          ),
          const SizedBox(height: 48),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              'PREFERENCES',
              style: TextStyle(
                color: Color(0xFFD1D8E4),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Spacer(),
          _SidebarItem(
            icon: Icons.logout_rounded,
            label: 'Log Out',
            onTap: onLogout ?? () => FirebaseAuth.instance.signOut(),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hover = false;

  void _setHover(bool v) => setState(() => _hover = v);

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.selected
        ? _blue
        : (_hover ? _soft : Colors.transparent);
    final iconColor = widget.selected
        ? Colors.white
        : (_hover ? _text : _muted);
    final textColor = widget.selected
        ? Colors.white
        : (_hover ? _text : _muted);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: MouseRegion(
        onEnter: (_) => _setHover(true),
        onExit: (_) => _setHover(false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: _hover && !widget.selected
                  ? [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            transform: Matrix4.diagonal3Values(
              _hover && !widget.selected ? 1.04 : 1.0,
              _hover && !widget.selected ? 1.04 : 1.0,
              1.0,
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: iconColor, size: 24),
                const SizedBox(width: 16),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 260),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: widget.selected
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                  child: Text(widget.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.controller,
    required this.onChanged,
    required this.onLogout,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.symmetric(horizontal: 42),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.directions_car_filled_rounded,
            color: _blue,
            size: 38,
          ),
          const SizedBox(width: 10),
          const Text(
            'CRBS',
            style: TextStyle(
              color: _blue,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 470,
            height: 46,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Color(0xFF596780)),
                suffixIcon: const Icon(Icons.tune, color: Color(0xFF596780)),
                hintText: 'Search something here',
                hintStyle: const TextStyle(color: Color(0xFF596780)),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: const BorderSide(color: _line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: const BorderSide(color: _line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: const BorderSide(color: _blue),
                ),
              ),
            ),
          ),
          const Spacer(),
          _NotificationButton(),
          const SizedBox(width: 18),
          PopupMenuButton<String>(
            tooltip: 'Admin profile',
            onSelected: (value) {
              if (value == 'logout') onLogout();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'logout', child: Text('Log out')),
            ],
            child: const CircleAvatar(
              radius: 23,
              backgroundColor: Color(0xFFEFF4FF),
              child: Icon(Icons.person, color: _blue),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  const _TopIcon(this.icon, {this.active = false, this.hasDot = false});

  final IconData icon;
  final bool active;
  final bool hasDot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: _line),
          ),
          child: Icon(icon, color: active ? _blue : const Color(0xFF596780)),
        ),
        if (hasDot)
          Positioned(
            right: 6,
            top: 3,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFFF4423),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _notificationsStream() {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('target', isEqualTo: 'admin')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _notificationsStream(),
      builder: (context, snap) {
        final unread = snap.hasData
            ? snap.data!.docs
                  .where((d) => (d.data()['read'] as bool?) != true)
                  .length
            : 0;

        return GestureDetector(
          onTap: () => _openNotifications(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _line),
                ),
                child: const Icon(
                  Icons.notifications_rounded,
                  color: Color(0xFF596780),
                ),
              ),
              if (unread > 0)
                Positioned(
                  right: 2,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4423),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openNotifications(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Notifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('target', isEqualTo: 'admin')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.hasError)
                    return const Center(
                      child: Text('Could not load notifications'),
                    );
                  if (!snap.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final docs = snap.data!.docs;
                  if (docs.isEmpty)
                    return const Center(child: Text('No notifications'));

                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final d = docs[i];
                      final data = d.data();
                      final title = data['title'] as String? ?? 'Notification';
                      final body = data['body'] as String? ?? '';
                      final read = (data['read'] as bool?) == true;

                      return ListTile(
                        title: Text(
                          title,
                          style: TextStyle(
                            fontWeight: read
                                ? FontWeight.normal
                                : FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(body),
                        trailing: TextButton(
                          child: const Text('Mark read'),
                          onPressed: () => d.reference.update({'read': true}),
                        ),
                        onTap: () async {
                          // try to open booking in admin dashboard by navigating to bookings page
                          final bookingId = data['bookingId'] as String?;
                          if (bookingId != null) {
                            // copy to clipboard as a fallback
                            await d.reference.update({'read': true});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Booking id copied: $bookingId'),
                              ),
                            );
                            // leave navigation behavior to future improvements
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarImage extends StatelessWidget {
  const _CarImage({required this.imageUrl, this.compact = false});

  final String? imageUrl;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? const Size(118, 56) : const Size(278, 128);

    if (imageUrl == null || imageUrl!.isEmpty) {
      return CustomPaint(
        painter: _CarSilhouettePainter(),
        child: SizedBox(width: size.width, height: size.height),
      );
    }

    return Image.network(
      imageUrl!,
      width: size.width,
      height: size.height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => CustomPaint(
        painter: _CarSilhouettePainter(),
        child: SizedBox(width: size.width, height: size.height),
      ),
    );
  }
}

class _CarSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.06);
    final body = Paint()..color = const Color(0xFFE4E9F1);
    final window = Paint()..color = const Color(0xFFCAD3E1);
    final wheel = Paint()..color = const Color(0xFF94A3B8);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.84),
        width: size.width * 0.78,
        height: size.height * 0.13,
      ),
      shadow,
    );

    final bodyPath = Path()
      ..moveTo(size.width * 0.08, size.height * 0.64)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.40,
        size.width * 0.36,
        size.height * 0.38,
      )
      ..lineTo(size.width * 0.58, size.height * 0.38)
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.40,
        size.width * 0.86,
        size.height * 0.58,
      )
      ..quadraticBezierTo(
        size.width * 0.94,
        size.height * 0.60,
        size.width * 0.96,
        size.height * 0.70,
      )
      ..lineTo(size.width * 0.08, size.height * 0.70)
      ..close();
    canvas.drawPath(bodyPath, body);

    final windowPath = Path()
      ..moveTo(size.width * 0.37, size.height * 0.42)
      ..lineTo(size.width * 0.56, size.height * 0.42)
      ..lineTo(size.width * 0.68, size.height * 0.56)
      ..lineTo(size.width * 0.28, size.height * 0.56)
      ..quadraticBezierTo(
        size.width * 0.31,
        size.height * 0.45,
        size.width * 0.37,
        size.height * 0.42,
      )
      ..close();
    canvas.drawPath(windowPath, window);

    canvas.drawCircle(
      Offset(size.width * 0.28, size.height * 0.70),
      size.width * 0.06,
      wheel,
    );
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.70),
      size.width * 0.06,
      wheel,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter(this.values);

  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.17;
    final rect =
        Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);
    final total = values.fold<int>(0, (runningTotal, value) {
      return runningTotal + value;
    });
    var start = -1.55;

    if (total == 0) {
      canvas.drawArc(
        rect,
        0,
        6.28,
        false,
        Paint()
          ..color = _line
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 6.0;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = _chartColors[i % _chartColors.length]
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      start += sweep + 0.18;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.values != values;
}

final _chartColors = [
  _darkBlue,
  const Color(0xFF1A72B0),
  const Color(0xFF2992D6),
  const Color(0xFF6BB7E8),
  const Color(0xFFA7D1F0),
];

String _stringValue(
  Map<String, dynamic> data,
  List<String> keys,
  String fallback,
) {
  for (final key in keys) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value != null && value is! List && '$value'.trim().isNotEmpty) {
      return '$value'.trim();
    }
  }
  return fallback;
}

int _intValue(Map<String, dynamic> data, List<String> keys, int fallback) {
  for (final key in keys) {
    final value = data[key];
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      final parsed = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
      if (parsed != null) return parsed;
    }
  }
  return fallback;
}

String? _imageValue(Map<String, dynamic> data) {
  for (final key in ['imageUrl', 'image_url', 'photoUrl', 'photo_url']) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }

  for (final key in ['imageUrls', 'image_urls', 'images']) {
    final value = data[key];
    if (value is List && value.isNotEmpty) {
      final first = value.first;
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

List<String> _imageListValue(Map<String, dynamic> data) {
  final urls = <String>[];
  final single = _imageValue(data);
  if (single != null && single.isNotEmpty) urls.add(single);

  for (final key in ['imageUrls', 'image_urls', 'images']) {
    final value = data[key];
    if (value is List) {
      for (final item in value) {
        String? url;
        if (item is String) {
          url = item.trim();
        } else if (item is Map && item['image_url'] is String) {
          url = (item['image_url'] as String).trim();
        } else if (item is Map && item['url'] is String) {
          url = (item['url'] as String).trim();
        }
        if (url != null && url.isNotEmpty && !urls.contains(url)) {
          urls.add(url);
        }
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

String _number(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}

String _monthName(int month) {
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
  return months[(month - 1).clamp(0, 11)];
}
