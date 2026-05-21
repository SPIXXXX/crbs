part of 'admin_page.dart';

class _DashboardPage extends StatefulWidget {
  const _DashboardPage({
    required this.cars,
    required this.bookings,
    required this.loading,
    required this.onViewCarRent,
  });

  final List<_AdminCar> cars;
  final List<_RentalBooking> bookings;
  final bool loading;
  final VoidCallback onViewCarRent;

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  _AdminCar? _selectedCar;
  _RentalBooking? _selectedBooking;

  // Which stop is highlighted on the map: 'pickup' | 'dropoff' | null
  String? _activeStop;

  // Geocoded overrides (used when booking has no stored coords)
  ll.LatLng? _geocodedPickup;
  ll.LatLng? _geocodedDropoff;

  // Shared MapController so we can .move() without rebuilding the whole tree
  final MapController _mapCtrl = MapController();

  @override
  void dispose() {
    _mapCtrl.dispose();
    super.dispose();
  }

  Future<ll.LatLng?> _geocodeLocation(String query) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1',
      );
      final resp = await http.get(
        url,
        headers: {'User-Agent': 'crbs-admin-app'},
      );
      if (resp.statusCode == 200) {
        final list = json.decode(resp.body) as List<dynamic>;
        if (list.isNotEmpty) {
          final item = list.first as Map<String, dynamic>;
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          if (lat != null && lon != null) return ll.LatLng(lat, lon);
        }
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  ll.LatLng? _resolvedPickup(_RentalBooking? b) {
    if (b?.pickupLat != null && b?.pickupLng != null) {
      return ll.LatLng(b!.pickupLat!, b.pickupLng!);
    }
    return _geocodedPickup;
  }

  ll.LatLng? _resolvedDropoff(_RentalBooking? b) {
    if (b?.dropLat != null && b?.dropLng != null) {
      return ll.LatLng(b!.dropLat!, b.dropLng!);
    }
    return _geocodedDropoff;
  }

  Future<void> _onLocationTap(
    String label,
    bool isPickup,
    _RentalBooking? booking,
  ) async {
    // First try stored coords
    final stored = isPickup
        ? _resolvedPickup(booking)
        : _resolvedDropoff(booking);
    if (stored != null) {
      setState(() => _activeStop = isPickup ? 'pickup' : 'dropoff');
      _mapCtrl.move(stored, 14);
      return;
    }

    // Fall back to geocoding
    if (label.isEmpty || label == '—') return;
    final loc = await _geocodeLocation(label);
    if (loc != null) {
      setState(() {
        _activeStop = isPickup ? 'pickup' : 'dropoff';
        if (isPickup) {
          _geocodedPickup = loc;
        } else {
          _geocodedDropoff = loc;
        }
      });
      _mapCtrl.move(loc, 14);
    } else {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Location not found: $label')));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cars = widget.cars;
    final bookings = widget.bookings;

    // Auto-select the most recent booking on first load
    _RentalBooking? activeBooking =
        _selectedBooking ?? (bookings.isNotEmpty ? bookings.first : null);
    _AdminCar? activeCar = _selectedCar;
    if (activeCar == null && activeBooking != null) {
      try {
        activeCar = cars.firstWhere((c) => c.id == activeBooking.vehicleId);
      } catch (_) {
        activeCar = cars.isNotEmpty ? cars.first : null;
      }
    }

    final pickupPos = _resolvedPickup(activeBooking);
    final dropoffPos = _resolvedDropoff(activeBooking);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(58, 48, 58, 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: map + rental detail ─────────────────────────────────
          Expanded(
            flex: 11,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Details Rental',
                  style: TextStyle(
                    color: _text,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 24),
                _MapPreview(
                  mapCtrl: _mapCtrl,
                  pickupPos: pickupPos,
                  dropoffPos: dropoffPos,
                  activeStop: _activeStop,
                ),
                const SizedBox(height: 30),
                _RentalDetailCard(
                  car: activeCar,
                  booking: activeBooking,
                  activeStop: _activeStop,
                  onLocationTap: (label, isPickup) =>
                      _onLocationTap(label, isPickup, activeBooking),
                  onConfirm: activeBooking == null
                      ? null
                      : () => _confirmBooking(activeBooking, activeCar),
                  onReturn: activeBooking == null
                      ? null
                      : () => _returnBooking(activeBooking, activeCar),
                ),
              ],
            ),
          ),
          const SizedBox(width: 70),
          // ── Right: donut + recent transactions ────────────────────────
          Expanded(
            flex: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopRentalPanel(cars: cars, bookings: bookings),
                const SizedBox(height: 58),
                _RecentTransactionPanel(
                  cars: cars,
                  bookings: bookings,
                  loading: widget.loading,
                  onViewAll: widget.onViewCarRent,
                  selectedBookingId: activeBooking?.id,
                  onTransactionTap: (tx) {
                    _AdminCar? found;
                    try {
                      if (tx.booking?.vehicleId.isNotEmpty == true) {
                        found = cars.firstWhere(
                          (c) => c.id == tx.booking!.vehicleId,
                        );
                      }
                    } catch (_) {}
                    setState(() {
                      _selectedBooking = tx.booking;
                      _selectedCar = found;
                      _activeStop = null;
                      _geocodedPickup = null;
                      _geocodedDropoff = null;
                    });
                  },
                  onDelete: (tx) async {
                    final booking = tx.booking;
                    if (booking == null) return;
                    try {
                      await FirebaseFirestore.instance
                          .collection('bookings')
                          .doc(booking.id)
                          .delete();
                      if (!mounted) return;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaction deleted')),
                        );
                      });
                      setState(() {
                        if (_selectedBooking?.id == booking.id) {
                          _selectedBooking = null;
                          _selectedCar = null;
                        }
                      });
                    } catch (e) {
                      if (mounted) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to delete transaction'),
                            ),
                          );
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBooking(_RentalBooking? booking, _AdminCar? car) async {
    if (booking == null) return;
    final bookingsRef = FirebaseFirestore.instance
        .collection('bookings')
        .doc(booking.id);
    final vehiclesRef = FirebaseFirestore.instance
        .collection('vehicles')
        .doc(booking.vehicleId);

    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final vehSnap = await txn.get(vehiclesRef);
        int currentTotal = 1;
        if (vehSnap.exists) {
          final vdata = vehSnap.data();
          final rawTotal = vdata?['total'] ?? vdata?['count'];
          if (rawTotal is int) {
            currentTotal = rawTotal;
          } else if (rawTotal is num) {
            currentTotal = rawTotal.toInt();
          } else {
            currentTotal = 1;
          }
        }

        final newTotal = (currentTotal - 1).clamp(0, 999999);
        final newVehData = <String, dynamic>{'total': newTotal};
        if (newTotal == 0) newVehData['status'] = 'inactive';
        txn.set(vehiclesRef, newVehData, SetOptions(merge: true));

        txn.update(bookingsRef, {
          'status': 'Confirmed',
          'confirmedAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Booking confirmed')));
      });
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to confirm booking')),
          );
        });
      }
    }
  }

  Future<void> _returnBooking(_RentalBooking? booking, _AdminCar? car) async {
    if (booking == null) return;
    final bookingsRef = FirebaseFirestore.instance
        .collection('bookings')
        .doc(booking.id);
    final vehiclesRef = FirebaseFirestore.instance
        .collection('vehicles')
        .doc(booking.vehicleId);

    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final vehSnap = await txn.get(vehiclesRef);
        int currentTotal = 0;
        if (vehSnap.exists) {
          final vdata = vehSnap.data();
          final rawTotal = vdata?['total'] ?? vdata?['count'];
          if (rawTotal is int) {
            currentTotal = rawTotal;
          } else if (rawTotal is num) {
            currentTotal = rawTotal.toInt();
          } else {
            currentTotal = 0;
          }
        }

        final newTotal = (currentTotal + 1).clamp(0, 999999);
        final newVehData = <String, dynamic>{'total': newTotal};
        if (newTotal > 0) newVehData['status'] = 'available';
        txn.set(vehiclesRef, newVehData, SetOptions(merge: true));

        txn.update(bookingsRef, {
          'status': 'Completed',
          'completedAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking marked returned')),
        );
      });
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to mark booking returned')),
          );
        });
      }
    }
  }
}

// ── Map preview with FlutterMap (same tile provider as checkout) ─────────────

class _MapPreview extends StatefulWidget {
  const _MapPreview({
    required this.mapCtrl,
    this.pickupPos,
    this.dropoffPos,
    this.activeStop,
  });

  final MapController mapCtrl;
  final ll.LatLng? pickupPos;
  final ll.LatLng? dropoffPos;
  final String? activeStop;

  @override
  State<_MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<_MapPreview> {
  static const _defaultCenter = ll.LatLng(14.5995, 120.9842);

  ll.LatLng get _initialCenter {
    if (widget.pickupPos != null) return widget.pickupPos!;
    if (widget.dropoffPos != null) return widget.dropoffPos!;
    return _defaultCenter;
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];

    if (widget.pickupPos != null) {
      final isActive = widget.activeStop == 'pickup';
      markers.add(
        Marker(
          point: widget.pickupPos!,
          width: 44,
          height: 44,
          child: _MapMarker(
            color: _blue,
            isActive: isActive,
            tooltip: 'Pick-Up',
          ),
        ),
      );
    }

    if (widget.dropoffPos != null) {
      final isActive = widget.activeStop == 'dropoff';
      markers.add(
        Marker(
          point: widget.dropoffPos!,
          width: 44,
          height: 44,
          child: _MapMarker(
            color: const Color(0xFF7CC7FF),
            isActive: isActive,
            tooltip: 'Drop-Off',
          ),
        ),
      );
    }

    if (markers.isEmpty) {
      markers.add(
        Marker(
          point: _defaultCenter,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: _muted, size: 32),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 260,
        width: double.infinity,
        child: FlutterMap(
          mapController: widget.mapCtrl,
          options: MapOptions(initialCenter: _initialCenter, initialZoom: 13),
          children: [
            TileLayer(
              urlTemplate: getTileUrlTemplate(),
              userAgentPackageName: 'org.crbs.app',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.color,
    required this.isActive,
    required this.tooltip,
  });

  final Color color;
  final bool isActive;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: AnimatedScale(
        scale: isActive ? 1.3 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: Icon(
          Icons.location_on,
          color: color,
          size: 36,
          shadows: isActive
              ? [Shadow(color: color.withValues(alpha: 0.4), blurRadius: 10)]
              : null,
        ),
      ),
    );
  }
}

// ── Rental detail card — now driven by both car + booking ─────────────────────

class _RentalDetailCard extends StatelessWidget {
  const _RentalDetailCard({
    required this.car,
    required this.booking,
    this.activeStop,
    this.onLocationTap,
    this.onConfirm,
    this.onReturn,
  });

  final _AdminCar? car;
  final _RentalBooking? booking;
  final String? activeStop;
  final void Function(String label, bool isPickup)? onLocationTap;
  final VoidCallback? onConfirm;
  final VoidCallback? onReturn;

  @override
  Widget build(BuildContext context) {
    final carName = car?.name ?? booking?.vehicleName ?? 'No booking selected';
    final carType = car?.category ?? booking?.category ?? '—';
    final carId = car?.id ?? '';
    final imageUrl = car?.imageUrl;
    final totalPrice = booking?.totalFee ?? car?.dailyRate ?? 0;

    // Booking data
    final pickupLoc = booking?.pickupLocation ?? 'CRBS Main Branch';
    final dropLoc = booking?.dropLocation ?? 'Customer Return Area';
    final pickupDate = booking?.pickupDateLabel ?? '—';
    final dropDate = booking?.dropDateLabel ?? '—';
    final pickupTime = booking?.pickupTime ?? '—';
    final dropTime = booking?.dropTime ?? '—';
    final customerName = booking?.customerName ?? '—';
    final customerPhone = booking?.customerPhone ?? '—';
    final days = booking?.days ?? 1;
    final status = booking?.status ?? '—';

    final statusColor = _statusColor(status);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: _DetailCardContent(
        key: ValueKey('${carId}_${booking?.id ?? ''}'),
        carName: carName,
        carType: carType,
        carId: carId,
        imageUrl: imageUrl,
        totalPrice: totalPrice,
        pickupLoc: pickupLoc,
        dropLoc: dropLoc,
        pickupDate: pickupDate,
        dropDate: dropDate,
        pickupTime: pickupTime,
        dropTime: dropTime,
        customerName: customerName,
        customerPhone: customerPhone,
        days: days,
        status: status,
        statusColor: statusColor,
        activeStop: activeStop,
        onLocationTap: onLocationTap,
        onConfirm: onConfirm,
        onReturn: onReturn,
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'active':
        return const Color(0xFF17A34A);
      case 'return requested':
        return const Color(0xFF7C3AED);
      case 'completed':
        return _blue;
      case 'cancelled':
      case 'canceled':
        return _red;
      default:
        return const Color(0xFFF59E0B); // Pending = amber
    }
  }
}

class _DetailCardContent extends StatelessWidget {
  const _DetailCardContent({
    super.key,
    required this.carName,
    required this.carType,
    required this.carId,
    required this.imageUrl,
    required this.totalPrice,
    required this.pickupLoc,
    required this.dropLoc,
    required this.pickupDate,
    required this.dropDate,
    required this.pickupTime,
    required this.dropTime,
    required this.customerName,
    required this.customerPhone,
    required this.days,
    required this.status,
    required this.statusColor,
    this.activeStop,
    this.onLocationTap,
    this.onConfirm,
    this.onReturn,
  });

  final String carName;
  final String carType;
  final String carId;
  final String? imageUrl;
  final int totalPrice;
  final String pickupLoc;
  final String dropLoc;
  final String pickupDate;
  final String dropDate;
  final String pickupTime;
  final String dropTime;
  final String customerName;
  final String customerPhone;
  final int days;
  final String status;
  final Color statusColor;
  final String? activeStop;
  final void Function(String label, bool isPickup)? onLocationTap;
  final VoidCallback? onConfirm;
  final VoidCallback? onReturn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Car header row ───────────────────────────────────────────────
        Row(
          children: [
            Container(
              width: 126,
              height: 72,
              decoration: BoxDecoration(
                color: _blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _CarImage(imageUrl: imageUrl, compact: true),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    carName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    carType,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  carId.isNotEmpty
                      ? '#${carId.substring(0, carId.length.clamp(0, 4)).toUpperCase()}'
                      : '#——',
                  style: const TextStyle(
                    color: Color(0xFF596780),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // ── Customer info bar ─────────────────────────────────────────────
        if (customerName != '—') ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _soft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFEFF4FF),
                  child: Icon(Icons.person_outline, color: _blue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: const TextStyle(
                          color: _text,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      if (customerPhone != '—')
                        Text(
                          customerPhone,
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$days ${days == 1 ? 'day' : 'days'}',
                      style: const TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'rental period',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 28),

        // ── Pick-up stop ──────────────────────────────────────────────────
        _RentalStop(
          color: _blue,
          title: 'Pick – Up',
          location: pickupLoc,
          date: pickupDate,
          time: pickupTime,
          isActive: activeStop == 'pickup',
          onLocationTap: onLocationTap != null
              ? () => onLocationTap!(pickupLoc, true)
              : null,
        ),
        const SizedBox(height: 28),

        // ── Drop-off stop ─────────────────────────────────────────────────
        _RentalStop(
          color: const Color(0xFF7CC7FF),
          title: 'Drop – Off',
          location: dropLoc,
          date: dropDate,
          time: dropTime,
          isActive: activeStop == 'dropoff',
          onLocationTap: onLocationTap != null
              ? () => onLocationTap!(dropLoc, false)
              : null,
        ),

        const SizedBox(height: 12),
        if (onConfirm != null && status.toLowerCase() == 'pending') ...[
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onConfirm,
              style: FilledButton.styleFrom(backgroundColor: _blue),
              child: const Text('Confirm Booking'),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (onReturn != null && status.toLowerCase() == 'return requested') ...[
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onReturn,
              style: FilledButton.styleFrom(backgroundColor: Color(0xFF16A34A)),
              child: const Text('Confirm Return'),
            ),
          ),
          const SizedBox(height: 12),
        ],

        const Divider(color: _line, height: 44),

        // ── Total price row ───────────────────────────────────────────────
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Rental Price',
                    style: TextStyle(
                      color: _text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Overall price and includes rental discount',
                    style: TextStyle(color: _muted, fontSize: 14),
                  ),
                ],
              ),
            ),
            Text(
              _money(totalPrice),
              style: const TextStyle(
                color: _text,
                fontSize: 36,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RentalStop extends StatelessWidget {
  const _RentalStop({
    required this.color,
    required this.title,
    required this.location,
    required this.date,
    required this.time,
    this.isActive = false,
    this.onLocationTap,
  });

  final Color color;
  final String title;
  final String location;
  final String date;
  final String time;
  final bool isActive;
  final VoidCallback? onLocationTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.28) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 16 : 14,
                height: isActive ? 16 : 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.25),
                    width: isActive ? 5 : 4,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? color : _text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Showing on map',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StopValue(
                  label: 'Locations',
                  value: location,
                  isActive: isActive,
                  activeColor: color,
                  onTap: onLocationTap,
                ),
              ),
              Expanded(
                child: _StopValue(label: 'Date', value: date),
              ),
              Expanded(
                child: _StopValue(label: 'Time', value: time),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StopValue extends StatefulWidget {
  const _StopValue({
    required this.label,
    required this.value,
    this.isActive = false,
    this.activeColor,
    this.onTap,
  });

  final String label;
  final String value;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback? onTap;

  @override
  State<_StopValue> createState() => _StopValueState();
}

class _StopValueState extends State<_StopValue> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isClickable = widget.onTap != null;
    final valueColor = widget.isActive
        ? (widget.activeColor ?? _blue)
        : _hover && isClickable
        ? _blue
        : _muted;

    return Container(
      padding: const EdgeInsets.only(right: 18),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: _line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          MouseRegion(
            cursor: isClickable
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: isClickable
                    ? const EdgeInsets.symmetric(horizontal: 8, vertical: 5)
                    : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: isClickable && _hover
                      ? _blue.withValues(alpha: 0.07)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        widget.value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: valueColor,
                          fontSize: 13,
                          fontWeight: widget.isActive
                              ? FontWeight.w800
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isClickable) ...[
                      const SizedBox(width: 5),
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: valueColor,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top rental donut chart ────────────────────────────────────────────────────

class _TopRentalPanel extends StatelessWidget {
  const _TopRentalPanel({required this.cars, required this.bookings});

  final List<_AdminCar> cars;
  final List<_RentalBooking> bookings;

  @override
  Widget build(BuildContext context) {
    String typeOf(_AdminCar car) {
      final type = car.category.trim();
      if (type.isEmpty) return 'Unknown';
      return type;
    }

    final counts = <String, int>{};
    if (bookings.isNotEmpty) {
      for (final b in bookings) {
        final match = cars.firstWhere(
          (c) => c.id == b.vehicleId,
          orElse: () => _AdminCar(
            id: b.vehicleId,
            name: b.vehicleName,
            model: b.vehicleName,
            category: b.category,
            seats: 4,
            fuel: '',
            transmission: '',
            dailyRate: 0,
            status: '',
            total: 1,
            plateNumber: '',
            imageUrl: null,
            imageUrls: const [],
          ),
        );
        final type = typeOf(match);
        counts[type] = (counts[type] ?? 0) + 1;
      }
    } else {
      for (final car in cars) {
        final type = typeOf(car);
        counts[type] = (counts[type] ?? 0) + 1;
      }
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();
    final total = bookings.isNotEmpty ? bookings.length : cars.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Top 5 Car Types',
                style: TextStyle(
                  color: _text,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Icon(Icons.more_horiz_rounded),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            SizedBox(
              width: 250,
              height: 250,
              child: CustomPaint(
                painter: _DonutPainter(
                  top.map((entry) => entry.value).toList(),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _number(total),
                        style: const TextStyle(
                          color: _text,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Rental Car',
                        style: TextStyle(color: _muted, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 44),
            Expanded(
              child: Column(
                children: List.generate(5, (index) {
                  final entry = index < top.length ? top[index] : null;
                  return _TopRentalRow(
                    color: _chartColors[index],
                    label: entry?.key ?? 'No Data',
                    value: entry?.value ?? 0,
                  );
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TopRentalRow extends StatelessWidget {
  const _TopRentalRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _muted,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _soft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _number(value),
              style: const TextStyle(
                color: _text,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent transactions panel ─────────────────────────────────────────────────

class _RecentTransactionPanel extends StatelessWidget {
  const _RecentTransactionPanel({
    required this.cars,
    required this.bookings,
    required this.loading,
    required this.onViewAll,
    this.selectedBookingId,
    this.onTransactionTap,
    this.onDelete,
  });

  final List<_AdminCar> cars;
  final List<_RentalBooking> bookings;
  final bool loading;
  final VoidCallback onViewAll;
  final String? selectedBookingId;
  final ValueChanged<_TransactionData>? onTransactionTap;
  final ValueChanged<_TransactionData>? onDelete;

  @override
  Widget build(BuildContext context) {
    final rows = bookings.isNotEmpty
        ? bookings.take(4).map((booking) {
            final matches = cars
                .where((c) => c.id == booking.vehicleId)
                .toList();
            final imageUrl = matches.isNotEmpty ? matches.first.imageUrl : null;
            return _TransactionData(
              booking: booking,
              name: booking.vehicleName,
              category: booking.category,
              date: booking.dateLabel,
              price: booking.totalFee,
              status: booking.status,
              imageUrl: imageUrl,
            );
          }).toList()
        : cars
              .take(4)
              .map(
                (car) => _TransactionData(
                  booking: null,
                  name: car.name,
                  category: car.category,
                  date: 'Today',
                  price: car.dailyRate,
                  status: car.status,
                  imageUrl: car.imageUrl,
                ),
              )
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent Transaction',
                style: TextStyle(
                  color: _text,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(onPressed: onViewAll, child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 28),
        if (loading)
          const Center(child: CircularProgressIndicator(color: _blue))
        else if (rows.isEmpty)
          const Text('No rental requests yet.', style: TextStyle(color: _muted))
        else
          ...rows.map(
            (row) => _TransactionRow(
              data: row,
              isSelected: row.booking?.id == selectedBookingId,
              onTap: () => onTransactionTap?.call(row),
              onDelete: () => onDelete?.call(row),
            ),
          ),
      ],
    );
  }
}

class _TransactionData {
  const _TransactionData({
    required this.booking,
    required this.name,
    required this.category,
    required this.date,
    required this.price,
    required this.status,
    required this.imageUrl,
  });

  final _RentalBooking? booking;
  final String name;
  final String category;
  final String date;
  final int price;
  final String status;
  final String? imageUrl;
}

class _TransactionRow extends StatefulWidget {
  const _TransactionRow({
    required this.data,
    required this.isSelected,
    this.onTap,
    this.onDelete,
  });

  final _TransactionData data;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  State<_TransactionRow> createState() => _TransactionRowState();
}

class _TransactionRowState extends State<_TransactionRow> {
  bool _hover = false;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'active':
        return const Color(0xFF17A34A);
      case 'return requested':
        return const Color(0xFF7C3AED);
      case 'completed':
        return _blue;
      case 'cancelled':
      case 'canceled':
        return _red;
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(widget.data.status);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFFEFF4FF)
                : _hover
                ? _soft
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected
                  ? _blue.withValues(alpha: 0.25)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                height: 54,
                child: _CarImage(imageUrl: widget.data.imageUrl, compact: true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.data.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.data.category,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (widget.data.booking?.customerName.isNotEmpty ==
                                true &&
                            widget.data.booking?.customerName != '—') ...[
                          const Icon(
                            Icons.person_outline,
                            size: 12,
                            color: _muted,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.data.booking!.customerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Add delete menu to the row's trailing area by extending the row widget
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.data.date,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _money(widget.data.price),
                    style: const TextStyle(
                      color: _text,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      widget.data.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                onSelected: (val) async {
                  if (val == 'delete') {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete transaction'),
                        content: const Text(
                          'Are you sure you want to delete this transaction? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      widget.onDelete?.call();
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
