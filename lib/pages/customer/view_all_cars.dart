import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../login_page.dart';
import 'car_details_page.dart';
import 'customer_profile_page.dart';

const _blue = Color(0xFF3568E8);
const _red = Color(0xFFFF4D4F);
const _text = Color(0xFF111827);
const _muted = Color(0xFF8EA0B8);
const _line = Color(0xFFE8ECF4);

class ViewAllCarsPage extends StatefulWidget {
  const ViewAllCarsPage({super.key});

  @override
  State<ViewAllCarsPage> createState() => _ViewAllCarsPageState();
}

class _ViewAllCarsPageState extends State<ViewAllCarsPage>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final Set<String> _selectedTypes = {};
  final Set<String> _selectedModels = {};
  final Set<int> _selectedCapacities = {};
  double? _maxPrice;

  late final AnimationController _pageCtrl;
  late final Animation<double> _pageFade;
  late final Animation<Offset> _pageSlide;

  // Stable stream — no timeout, never recreated on rebuild
  late final Stream<List<_RentalCar>> _carsStream;

  @override
  void initState() {
    super.initState();
    _pageCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _pageFade = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOutCubic));

    _carsStream = FirebaseFirestore.instance
        .collection('vehicles')
        .snapshots()
        .map((snapshot) {
          final cars = snapshot.docs.map(_RentalCar.fromDoc).toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          return cars;
        })
        .handleError((Object error) {
          debugPrint('Cars stream error: $error');
        });
  }

  void _openRentalHistory(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _RentalHistoryPage(userId: user.uid)),
    );
  }

  void _openCurrentRentals(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _CurrentRentalsPage(userId: user.uid)),
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_RentalCar> _applyFilters(List<_RentalCar> cars, double maxPrice) {
    final query = _searchCtrl.text.trim().toLowerCase();
    return cars.where((car) {
      final matchesSearch =
          query.isEmpty ||
          car.name.toLowerCase().contains(query) ||
          car.model.toLowerCase().contains(query) ||
          car.category.toLowerCase().contains(query) ||
          car.transmission.toLowerCase().contains(query) ||
          car.fuel.toLowerCase().contains(query);
      final matchesModel =
          _selectedModels.isEmpty || _selectedModels.contains(car.model);
      final matchesType =
          _selectedTypes.isEmpty || _selectedTypes.contains(car.category);
      final matchesCapacity =
          _selectedCapacities.isEmpty ||
          _selectedCapacities.any((capacity) {
            if (capacity == 8) return car.seats >= 8;
            return car.seats == capacity;
          });
      return matchesSearch &&
          matchesModel &&
          matchesType &&
          matchesCapacity &&
          car.dailyRate <= maxPrice;
    }).toList();
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
            child: StreamBuilder<List<_RentalCar>>(
              stream: _carsStream,
              initialData: const <_RentalCar>[],
              builder: (context, snapshot) {
                final cars = snapshot.data ?? const <_RentalCar>[];
                final typeCounts = _countTypes(cars);
                final modelCounts = _countModels(cars);
                final capacityCounts = _countCapacities(cars);
                final highestRate = _highestRate(cars);
                final priceLimit = (_maxPrice ?? highestRate)
                    .clamp(0, highestRate)
                    .toDouble();
                final visibleCars = _applyFilters(cars, priceLimit);

                return Column(
                  children: [
                    TopBar(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      onBack: () => Navigator.maybePop(context),
                      onOpenCurrent: () => _openCurrentRentals(context),
                      onOpenHistory: () => _openRentalHistory(context),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 880;
                          final filters = _FilterPanel(
                            typeCounts: typeCounts,
                            modelCounts: modelCounts,
                            capacityCounts: capacityCounts,
                            selectedTypes: _selectedTypes,
                            selectedModels: _selectedModels,
                            selectedCapacities: _selectedCapacities,
                            maxPrice: priceLimit.toDouble(),
                            highestRate: highestRate,
                            onTypeChanged: _toggleType,
                            onModelChanged: _toggleModel,
                            onCapacityChanged: _toggleCapacity,
                            onPriceChanged: (value) =>
                                setState(() => _maxPrice = value),
                          );

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (wide)
                                TweenAnimationBuilder<Offset>(
                                  tween: Tween(
                                    begin: const Offset(-1, 0),
                                    end: Offset.zero,
                                  ),
                                  duration: const Duration(milliseconds: 420),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, offset, child) =>
                                      FractionalTranslation(
                                        translation: offset,
                                        child: child,
                                      ),
                                  child: SizedBox(width: 292, child: filters),
                                ),
                              Expanded(
                                child: Column(
                                  children: [
                                    if (!wide)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          18,
                                          12,
                                          18,
                                          0,
                                        ),
                                        child: _MobileFilterButton(
                                          filterPanel: filters,
                                        ),
                                      ),
                                    Expanded(
                                      child: _CarsGrid(
                                        cars: visibleCars,
                                        emptyMessage: cars.isEmpty
                                            ? 'No cars available.'
                                            : 'No cars match your filters.',
                                        onRent: _openRentDialog,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Map<String, int> _countTypes(List<_RentalCar> cars) {
    final counts = <String, int>{};
    for (final car in cars) {
      counts[car.category] = (counts[car.category] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> _countModels(List<_RentalCar> cars) {
    final counts = <String, int>{};
    for (final car in cars) {
      final model = car.model.trim();
      if (model.isEmpty) continue;
      counts[model] = (counts[model] ?? 0) + 1;
    }
    return counts;
  }

  Map<int, int> _countCapacities(List<_RentalCar> cars) {
    final counts = <int, int>{2: 0, 4: 0, 6: 0, 8: 0};
    for (final car in cars) {
      if (car.seats >= 8) {
        counts[8] = counts[8]! + 1;
      } else if (car.seats >= 6) {
        counts[6] = counts[6]! + 1;
      } else if (car.seats >= 4) {
        counts[4] = counts[4]! + 1;
      } else {
        counts[2] = counts[2]! + 1;
      }
    }
    return counts;
  }

  double _highestRate(List<_RentalCar> cars) {
    if (cars.isEmpty) return 10000;
    return cars
        .map((car) => car.dailyRate)
        .reduce((value, next) => value > next ? value : next)
        .toDouble();
  }

  void _toggleType(String type, bool selected) {
    setState(() {
      if (selected) {
        _selectedTypes.add(type);
      } else {
        _selectedTypes.remove(type);
      }
    });
  }

  void _toggleModel(String model, bool selected) {
    setState(() {
      if (selected) {
        _selectedModels.add(model);
      } else {
        _selectedModels.remove(model);
      }
    });
  }

  void _toggleCapacity(int capacity, bool selected) {
    setState(() {
      if (selected) {
        _selectedCapacities.add(capacity);
      } else {
        _selectedCapacities.remove(capacity);
      }
    });
  }

  void _openRentDialog(_RentalCar car) {
    showDialog<void>(
      context: context,
      builder: (_) => _RentDialog(car: car),
    );
  }
}

class _RentalCar {
  const _RentalCar({
    required this.id,
    required this.name,
    required this.model,
    required this.category,
    required this.seats,
    required this.fuel,
    required this.transmission,
    required this.dailyRate,
    required this.status,
    required this.plateNumber,
    required this.imageUrl,
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
  final String plateNumber;
  final String? imageUrl;

  bool get isAvailable => status.toLowerCase() == 'available';

  factory _RentalCar.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return _RentalCar(
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
      plateNumber: _stringValue(data, ['plateNumber', 'plate_number'], ''),
      imageUrl: _imageValue(data),
    );
  }

  static String _stringValue(
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

  static int _intValue(
    Map<String, dynamic> data,
    List<String> keys,
    int fallback,
  ) {
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

  static String? _imageValue(Map<String, dynamic> data) {
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
}

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onBack,
    this.onOpenCurrent,
    this.onOpenHistory,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onBack;
  final VoidCallback? onOpenCurrent;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 36),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.directions_car_filled_rounded,
            color: _blue,
            size: 34,
          ),
          const SizedBox(width: 8),
          const Text(
            'CRBS',
            style: TextStyle(
              color: _blue,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: _muted),
                suffixIcon: const Icon(Icons.tune, color: _muted),
                hintText: 'Search available rental cars',
                hintStyle: const TextStyle(color: _muted),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(color: _line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(color: _line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(color: _blue),
                ),
              ),
            ),
          ),
          const Spacer(),
          // Currently renting icon
          Tooltip(
            message: 'Currently Renting',
            child: IconButton(
              onPressed: onOpenCurrent,
              icon: const Icon(
                Icons.directions_car_outlined,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Rental history icon with hover label
          Tooltip(
            message: 'Rental History',
            child: IconButton(
              onPressed: onOpenHistory,
              icon: const Icon(Icons.history, color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(width: 14),
          Tooltip(
            message: 'Favorites',
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.favorite, color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(width: 14),
          Tooltip(
            message: 'Notifications',
            child: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_rounded,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const _CustomerProfileAvatar(),
        ],
      ),
    );
  }
}

class _CustomerProfileAvatar extends StatelessWidget {
  const _CustomerProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            ),
            child: const Text('Login'),
          );
        }

        final name = user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : user.email ?? 'Customer';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'View profile',
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomerProfilePage(),
                  ),
                ),
                borderRadius: BorderRadius.circular(999),
                child: _AvatarImage(photoUrl: user.photoURL),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomerProfilePage()),
              ),
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
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

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    if (url == null || url.isEmpty) {
      return const CircleAvatar(
        radius: 22,
        backgroundColor: Color(0xFFEFF4FF),
        child: Icon(Icons.person_outline, color: _blue, size: 24),
      );
    }

    return ClipOval(
      child: Image.network(
        url,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFEFF4FF),
            child: Icon(Icons.person_outline, color: _blue, size: 24),
          );
        },
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon(this.icon, {this.active = false});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: _line),
      ),
      child: Icon(icon, color: active ? _blue : const Color(0xFF64748B)),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.typeCounts,
    required this.modelCounts,
    required this.capacityCounts,
    required this.selectedTypes,
    required this.selectedModels,
    required this.selectedCapacities,
    required this.maxPrice,
    required this.highestRate,
    required this.onTypeChanged,
    required this.onModelChanged,
    required this.onCapacityChanged,
    required this.onPriceChanged,
  });

  final Map<String, int> typeCounts;
  final Map<String, int> modelCounts;
  final Map<int, int> capacityCounts;
  final Set<String> selectedTypes;
  final Set<String> selectedModels;
  final Set<int> selectedCapacities;
  final double maxPrice;
  final double highestRate;
  final void Function(String type, bool selected) onTypeChanged;
  final void Function(String model, bool selected) onModelChanged;
  final void Function(int capacity, bool selected) onCapacityChanged;
  final ValueChanged<double> onPriceChanged;

  @override
  Widget build(BuildContext context) {
    final types = typeCounts.keys.toList()..sort();
    final models = modelCounts.keys.toList()..sort();
    final max = highestRate <= 0 ? 10000.0 : highestRate;

    return Container(
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 30, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: _line)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FilterTitle('TYPE'),
            if (types.isEmpty)
              const Text(
                'No vehicle types yet.',
                style: TextStyle(color: _muted),
              )
            else
              ...types.map(
                (type) => _CheckRow(
                  label: type,
                  count: typeCounts[type] ?? 0,
                  selected: selectedTypes.contains(type),
                  onChanged: (value) => onTypeChanged(type, value),
                ),
              ),
            const SizedBox(height: 18),
            const _FilterTitle('MODEL'),
            if (models.isEmpty)
              const Text('No models yet.', style: TextStyle(color: _muted))
            else
              ...models.map(
                (model) => _CheckRow(
                  label: model,
                  count: modelCounts[model] ?? 0,
                  selected: selectedModels.contains(model),
                  onChanged: (value) => onModelChanged(model, value),
                ),
              ),
            const SizedBox(height: 30),
            const _FilterTitle('CAPACITY'),
            for (final capacity in const [2, 4, 6, 8])
              _CheckRow(
                label: capacity == 8 ? '8 or More' : '$capacity Person',
                count: capacityCounts[capacity] ?? 0,
                selected: selectedCapacities.contains(capacity),
                onChanged: (value) => onCapacityChanged(capacity, value),
              ),
            const SizedBox(height: 30),
            const _FilterTitle('PRICE'),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _blue,
                inactiveTrackColor: const Color(0xFFB7C3D4),
                thumbColor: _blue,
                overlayColor: _blue.withValues(alpha: 0.12),
              ),
              child: Slider(
                min: 0,
                max: max,
                value: maxPrice.clamp(0, max),
                onChanged: onPriceChanged,
              ),
            ),
            Text(
              'Max. ${_money(maxPrice.round())}',
              style: const TextStyle(
                color: Color(0xFF526072),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTitle extends StatelessWidget {
  const _FilterTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: const TextStyle(
          color: _muted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _CheckRow extends StatefulWidget {
  const _CheckRow({
    required this.label,
    required this.count,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final int count;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  State<_CheckRow> createState() => _CheckRowState();
}

class _CheckRowState extends State<_CheckRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<Color?> _bg;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: widget.selected ? 1.0 : 0.0,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _bg = ColorTween(
      begin: Colors.transparent,
      end: const Color(0xFFEEF3FF),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_CheckRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      widget.selected ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: Container(
          decoration: BoxDecoration(
            color: _bg.value,
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        ),
      ),
      child: CheckboxListTile(
        value: widget.selected,
        onChanged: (value) => widget.onChanged(value ?? false),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
        activeColor: _blue,
        title: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: widget.selected ? _blue : const Color(0xFF526072),
            fontSize: 18,
            fontWeight: widget.selected ? FontWeight.w800 : FontWeight.w700,
          ),
          child: Text('${widget.label} (${widget.count})'),
        ),
      ),
    );
  }
}

class _MobileFilterButton extends StatelessWidget {
  const _MobileFilterButton({required this.filterPanel});

  final Widget filterPanel;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => SizedBox(height: 560, child: filterPanel),
          );
        },
        icon: const Icon(Icons.tune),
        label: const Text('Filters'),
      ),
    );
  }
}

class _CarsGrid extends StatelessWidget {
  const _CarsGrid({
    required this.cars,
    required this.emptyMessage,
    required this.onRent,
  });

  final List<_RentalCar> cars;
  final String emptyMessage;
  final ValueChanged<_RentalCar> onRent;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return SizedBox(
          width: double.infinity,
          child: Stack(
            alignment: Alignment.topLeft,
            children: [
              ...previousChildren,
              currentChild ?? const SizedBox.shrink(),
            ],
          ),
        );
      },
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
      child: cars.isEmpty
          ? Center(
              key: const ValueKey('empty'),
              child: Text(
                emptyMessage,
                style: const TextStyle(color: _muted, fontSize: 16),
              ),
            )
          : _AnimatedGrid(
              key: ValueKey(cars.length),
              cars: cars,
              onRent: onRent,
            ),
    );
  }
}

class _AnimatedGrid extends StatefulWidget {
  const _AnimatedGrid({super.key, required this.cars, required this.onRent});

  final List<_RentalCar> cars;
  final ValueChanged<_RentalCar> onRent;

  @override
  State<_AnimatedGrid> createState() => _AnimatedGridState();
}

class _AnimatedGridState extends State<_AnimatedGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 300 + (widget.cars.length.clamp(1, 9) * 60),
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
        final columns = width >= 1180
            ? 3
            : width >= 780
            ? 2
            : 1;
        final gap = 34.0;
        final cardWidth = (width - 116 - (gap * (columns - 1))) / columns;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(58, 8, 58, 54),
          child: Wrap(
            spacing: gap,
            runSpacing: 44,
            alignment: WrapAlignment.start,
            runAlignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: widget.cars.asMap().entries.map((entry) {
              final index = entry.key;
              final car = entry.value;
              // Stagger: each card starts 60ms after the previous
              final start = (index * 0.08).clamp(0.0, 0.72);
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
                      begin: const Offset(0, 0.12),
                      end: Offset.zero,
                    ).animate(interval),
                    child: _CarTile(car: car, onRent: () => widget.onRent(car)),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _CarTile extends StatefulWidget {
  const _CarTile({required this.car, required this.onRent});

  final _RentalCar car;
  final VoidCallback onRent;

  @override
  State<_CarTile> createState() => _CarTileState();
}

class _CarTileState extends State<_CarTile>
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
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              height: 370,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color.lerp(
                    _line,
                    _blue.withValues(alpha: 0.30),
                    _elevation.value,
                  )!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.04 + (_elevation.value * 0.08),
                    ),
                    blurRadius: 8 + (_elevation.value * 20),
                    offset: Offset(0, 4 + (_elevation.value * 10)),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(22),
              child: child,
            ),
          );
        },
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
                        widget.car.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.car.model.isNotEmpty
                            ? '${widget.car.category} · ${widget.car.model}'
                            : widget.car.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: widget.car.isAvailable
                        ? const Color(0xFFEFFAF3)
                        : const Color(0xFFFFF2F2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    widget.car.status,
                    style: TextStyle(
                      color: widget.car.isAvailable
                          ? const Color(0xFF17A34A)
                          : _red,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Expanded(
              child: Center(child: _CarImage(imageUrl: widget.car.imageUrl)),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _Spec(Icons.local_gas_station, widget.car.fuel),
                _Spec(Icons.settings, widget.car.transmission),
                _Spec(Icons.people, '${widget.car.seats} People'),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: _money(widget.car.dailyRate),
                      style: const TextStyle(
                        color: _text,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                      children: const [
                        TextSpan(
                          text: ' / day',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 128,
                  height: 44,
                  child: FilledButton(
                    onPressed: widget.car.isAvailable
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CarDetailsPage(carId: widget.car.id),
                            ),
                          )
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      disabledBackgroundColor: const Color(0xFFCAD3E1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      widget.car.isAvailable ? 'Rent Now' : 'Unavailable',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CarImage extends StatelessWidget {
  const _CarImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CustomPaint(
        painter: _CarSilhouettePainter(),
        child: const SizedBox(width: 260, height: 120),
      );
    }

    return Image.network(
      imageUrl!,
      width: 280,
      height: 132,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => CustomPaint(
        painter: _CarSilhouettePainter(),
        child: const SizedBox(width: 260, height: 120),
      ),
    );
  }
}

class _Spec extends StatelessWidget {
  const _Spec(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF90A3BF)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RentDialog extends StatefulWidget {
  const _RentDialog({required this.car});

  final _RentalCar car;

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
            ),
            const SizedBox(height: 18),
            _DateButton(
              label: 'Pickup date',
              value: _pickupDate,
              onPicked: (date) => setState(() => _pickupDate = date),
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
              onPicked: (date) => setState(() => _returnDate = date),
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
          onPressed: _saving ? null : _submitRequest,
          style: FilledButton.styleFrom(backgroundColor: _blue),
          child: Text(_saving ? 'Sending...' : 'Submit Request'),
        ),
      ],
    );
  }

  Future<void> _submitRequest() async {
    if (_pickupDate == null || _returnDate == null) {
      _message('Select pickup and return dates first.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
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
          'body':
              '${user.displayName ?? user.email} requested ${widget.car.name}',
          'bookingId': docRef.id,
          'target': 'admin',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      if (!mounted) return;
      Navigator.pop(context);
      _message('Rental request sent for ${widget.car.name}.');
    } on FirebaseException catch (error) {
      _message(error.message ?? 'Could not send the rental request.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) {
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
      icon: const Icon(Icons.calendar_today_outlined),
      label: Text(
        value == null ? label : '${value!.month}/${value!.day}/${value!.year}',
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

// ─── Currently Renting – full page ───────────────────────────────────────────

class _CurrentRentalsPage extends StatefulWidget {
  const _CurrentRentalsPage({required this.userId});
  final String userId;

  @override
  State<_CurrentRentalsPage> createState() => _CurrentRentalsPageState();
}

class _CurrentRentalsPageState extends State<_CurrentRentalsPage> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    // No orderBy here — combining whereIn + orderBy on a different field
    // requires a Firestore composite index. We sort in memory instead.
    _stream = FirebaseFirestore.instance
        .collection('bookings')
        .where('customerId', isEqualTo: widget.userId)
        .where(
          'status',
          whereIn: [
            'Pending',
            'pending',
            'Confirmed',
            'confirmed',
            'Active',
            'active',
            'Return Requested',
            'return requested',
          ],
        )
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Currently Renting',
          style: TextStyle(
            color: _text,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _line),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error: \${snap.error}',
                  style: const TextStyle(color: _red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = (snap.data?.docs ?? const []).toList()
            ..sort((a, b) {
              final aDate = a.data()['pickupDate'];
              final bDate = b.data()['pickupDate'];
              if (aDate is Timestamp && bDate is Timestamp) {
                return aDate.compareTo(bDate);
              }
              return 0;
            });
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 64,
                    color: _muted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No active rentals',
                    style: TextStyle(color: _muted, fontSize: 16),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final d = docs[i].data();
              final name = (d['vehicleName'] as String?) ?? 'Rental Car';
              final imageUrl = (d['imageUrl'] as String?) ?? '';
              final vehicleId = (d['vehicleId'] as String?) ?? '';
              final status = (d['status'] as String?) ?? '—';
              final pickup = d['pickupDate'] is Timestamp
                  ? (d['pickupDate'] as Timestamp).toDate()
                  : null;
              final returnDate = d['returnDate'] is Timestamp
                  ? (d['returnDate'] as Timestamp).toDate()
                  : null;
              final pickupLabel = pickup != null
                  ? '${pickup.year}-${pickup.month.toString().padLeft(2, '0')}-${pickup.day.toString().padLeft(2, '0')}'
                  : (d['pickupDateLabel'] as String?) ?? '—';
              final returnLabel = returnDate != null
                  ? '${returnDate.year}-${returnDate.month.toString().padLeft(2, '0')}-${returnDate.day.toString().padLeft(2, '0')}'
                  : '—';
              final totalFee = d['totalFee'];
              final feeLabel = totalFee != null
                  ? _money((totalFee as num).toInt())
                  : '—';
              final statusLow = status.toLowerCase();
              final isActive = statusLow == 'active';
              final isReturnRequested = statusLow == 'return requested';
              final Color statusBadgeBg = isReturnRequested
                  ? const Color(0xFFEDE9FE)
                  : isActive
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFEFF6FF);
              final Color statusBadgeFg = isReturnRequested
                  ? const Color(0xFF7C3AED)
                  : isActive
                  ? const Color(0xFF16A34A)
                  : _blue;
              final canRequestReturn =
                  statusLow == 'confirmed' || statusLow == 'active';
              final bookingDocId = docs[i].id;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: _line),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 100,
                              height: 68,
                              child: _BookingImage(
                                imageUrl: imageUrl,
                                vehicleId: vehicleId,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: _text,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusBadgeBg,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: statusBadgeFg,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                _InfoRow(
                                  icon: Icons.calendar_today_outlined,
                                  label: 'Pickup',
                                  value: pickupLabel,
                                ),
                                const SizedBox(height: 3),
                                _InfoRow(
                                  icon: Icons.event_available_outlined,
                                  label: 'Return',
                                  value: returnLabel,
                                ),
                                const SizedBox(height: 3),
                                _InfoRow(
                                  icon: Icons.payments_outlined,
                                  label: 'Total',
                                  value: feeLabel,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (canRequestReturn) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: ctx,
                                builder: (dialogCtx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text('Request Return'),
                                  content: const Text(
                                    'Are you sure you want to return this car? The admin will confirm the return.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogCtx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(dialogCtx).pop(true),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _blue,
                                      ),
                                      child: const Text('Yes, Return'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok != true) return;
                              try {
                                await FirebaseFirestore.instance
                                    .collection('bookings')
                                    .doc(bookingDocId)
                                    .update({
                                      'status': 'Return Requested',
                                      'returnRequestedAt':
                                          FieldValue.serverTimestamp(),
                                    });
                              } catch (_) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Failed to request return. Try again.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.assignment_return_outlined),
                            label: const Text('Request Return'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _blue,
                              side: const BorderSide(color: _blue),
                            ),
                          ),
                        ),
                      ],
                      if (isReturnRequested) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.hourglass_top_rounded,
                                size: 16,
                                color: Color(0xFF7C3AED),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Waiting for admin to confirm return…',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7C3AED),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Rental History – full page ──────────────────────────────────────────────

class _RentalHistoryPage extends StatefulWidget {
  const _RentalHistoryPage({required this.userId});
  final String userId;

  @override
  State<_RentalHistoryPage> createState() => _RentalHistoryPageState();
}

class _RentalHistoryPageState extends State<_RentalHistoryPage> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  static const _statusColors = <String, Color>{
    'completed': Color(0xFF16A34A),
    'cancelled': _red,
    'pending': Color(0xFFD97706),
    'confirmed': _blue,
    'active': Color(0xFF16A34A),
    'return requested': Color(0xFF7C3AED),
  };

  static const _statusBg = <String, Color>{
    'completed': Color(0xFFDCFCE7),
    'cancelled': Color(0xFFFFE4E6),
    'pending': Color(0xFFFEF9C3),
    'confirmed': Color(0xFFEFF6FF),
    'active': Color(0xFFDCFCE7),
    'return requested': Color(0xFFEDE9FE),
  };

  @override
  void initState() {
    super.initState();
    // orderBy alone on a non-indexed field can fail; sort in memory instead.
    _stream = FirebaseFirestore.instance
        .collection('bookings')
        .where('customerId', isEqualTo: widget.userId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Rental History',
          style: TextStyle(
            color: _text,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _line),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error: ${snap.error}',
                  style: const TextStyle(color: _red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          // Sort by createdAt descending in memory
          final docs = (snap.data?.docs ?? const []).toList()
            ..sort((a, b) {
              final aTs = a.data()['createdAt'];
              final bTs = b.data()['createdAt'];
              if (aTs is Timestamp && bTs is Timestamp) {
                return bTs.compareTo(aTs);
              }
              return 0;
            });
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: _muted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No rental history yet',
                    style: TextStyle(color: _muted, fontSize: 16),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final d = docs[i].data();
              final name = (d['vehicleName'] as String?) ?? 'Rental Car';
              final imageUrl = (d['imageUrl'] as String?) ?? '';
              final vehicleId = (d['vehicleId'] as String?) ?? '';
              final status = (d['status'] as String?) ?? '—';
              final statusKey = status.toLowerCase();
              final statusColor = _statusColors[statusKey] ?? _muted;
              final statusBgColor =
                  _statusBg[statusKey] ?? const Color(0xFFF1F5F9);
              final pickup = d['pickupDate'] is Timestamp
                  ? (d['pickupDate'] as Timestamp).toDate()
                  : null;
              final returnDate = d['returnDate'] is Timestamp
                  ? (d['returnDate'] as Timestamp).toDate()
                  : null;
              final createdAt = d['createdAt'] is Timestamp
                  ? (d['createdAt'] as Timestamp).toDate()
                  : null;
              final dateLabel = pickup != null
                  ? '${pickup.year}-${pickup.month.toString().padLeft(2, '0')}-${pickup.day.toString().padLeft(2, '0')}'
                  : (d['dateLabel'] as String?) ?? '—';
              final returnLabel = returnDate != null
                  ? '${returnDate.year}-${returnDate.month.toString().padLeft(2, '0')}-${returnDate.day.toString().padLeft(2, '0')}'
                  : '—';
              final bookedLabel = createdAt != null
                  ? '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}'
                  : '—';
              final totalFee = d['totalFee'];
              final feeLabel = totalFee != null
                  ? _money((totalFee as num).toInt())
                  : '—';

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: _line),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 100,
                          height: 68,
                          child: _BookingImage(
                            imageUrl: imageUrl,
                            vehicleId: vehicleId,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: _text,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusBgColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _InfoRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Pickup',
                              value: dateLabel,
                            ),
                            const SizedBox(height: 3),
                            _InfoRow(
                              icon: Icons.event_available_outlined,
                              label: 'Return',
                              value: returnLabel,
                            ),
                            const SizedBox(height: 3),
                            _InfoRow(
                              icon: Icons.payments_outlined,
                              label: 'Total',
                              value: feeLabel,
                            ),
                            const SizedBox(height: 3),
                            _InfoRow(
                              icon: Icons.access_time_outlined,
                              label: 'Booked',
                              value: bookedLabel,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _CarIcon extends StatelessWidget {
  const _CarIcon();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(Icons.directions_car_outlined, color: _muted, size: 32),
      ),
    );
  }
}

/// Shows the car image for a booking.
/// Uses [imageUrl] if non-empty; otherwise fetches from the vehicles collection
/// via [vehicleId] — so old bookings without a stored imageUrl still show the image.
class _BookingImage extends StatefulWidget {
  const _BookingImage({required this.imageUrl, required this.vehicleId});

  final String imageUrl;
  final String vehicleId;

  @override
  State<_BookingImage> createState() => _BookingImageState();
}

class _BookingImageState extends State<_BookingImage> {
  String? _resolvedUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(_BookingImage old) {
    super.didUpdateWidget(old);
    if (old.imageUrl != widget.imageUrl || old.vehicleId != widget.vehicleId) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    // Fast path: booking already has the URL stored
    if (widget.imageUrl.isNotEmpty) {
      if (mounted)
        setState(() {
          _resolvedUrl = widget.imageUrl;
          _loading = false;
        });
      return;
    }
    // Slow path: fetch from the vehicles collection
    if (widget.vehicleId.isEmpty) {
      if (mounted)
        setState(() {
          _resolvedUrl = null;
          _loading = false;
        });
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .get();
      final url = (snap.data()?['imageUrl'] as String?) ?? '';
      if (mounted)
        setState(() {
          _resolvedUrl = url.isEmpty ? null : url;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _resolvedUrl = null;
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        color: const Color(0xFFF1F5F9),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _muted),
          ),
        ),
      );
    }
    if (_resolvedUrl == null || _resolvedUrl!.isEmpty) {
      return const _CarIcon();
    }
    return Image.network(
      _resolvedUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : Container(
              color: const Color(0xFFF1F5F9),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _muted,
                  ),
                ),
              ),
            ),
      errorBuilder: (_, __, ___) => const _CarIcon(),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: _muted),
        const SizedBox(width: 4),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: _muted)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: _text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

String _money(int value) {
  final amount = value.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return '₱$amount';
}
