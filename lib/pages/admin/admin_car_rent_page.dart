part of 'admin_page.dart';

class _CarRentPage extends StatefulWidget {
  const _CarRentPage({
    required this.cars,
    required this.loading,
    required this.onAddCar,
    required this.onEditCar,
    required this.onDeleteCar,
  });

  final List<_AdminCar> cars;
  final bool loading;
  final VoidCallback onAddCar;
  final ValueChanged<_AdminCar> onEditCar;
  final ValueChanged<_AdminCar> onDeleteCar;

  @override
  State<_CarRentPage> createState() => _CarRentPageState();
}

class _CarRentPageState extends State<_CarRentPage>
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(58, 44, 58, 24),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Car Rent',
                      style: TextStyle(
                        color: _text,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add and manage the cars that customers can rent.',
                      style: TextStyle(color: _muted, fontSize: 15),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: widget.onAddCar,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Car'),
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.loading
              ? const Center(child: CircularProgressIndicator(color: _blue))
              : widget.cars.isEmpty
              ? const Center(
                  child: Text(
                    'No cars added yet. Click Add Car to create one.',
                    style: TextStyle(color: _muted, fontSize: 16),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final columns = width >= 1180
                        ? 3
                        : width >= 780
                        ? 2
                        : 1;
                    final gap = 34.0;
                    final cardWidth =
                        (width - 116 - (gap * (columns - 1))) / columns;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(58, 8, 58, 54),
                      child: Wrap(
                        spacing: gap,
                        runSpacing: 44,
                        children: widget.cars.asMap().entries.map((entry) {
                          final index = entry.key;
                          final car = entry.value;
                          final start = (index * 0.08).clamp(0.0, 0.72);
                          final end = (start + 0.28).clamp(0.0, 1.0);
                          final interval = CurvedAnimation(
                            parent: _ctrl,
                            curve: Interval(
                              start,
                              end,
                              curve: Curves.easeOutCubic,
                            ),
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
                                child: _AdminCarTile(
                                  car: car,
                                  onEdit: () => widget.onEditCar(car),
                                  onDelete: () => widget.onDeleteCar(car),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AdminCarTile extends StatefulWidget {
  const _AdminCarTile({
    required this.car,
    required this.onEdit,
    required this.onDelete,
  });

  final _AdminCar car;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_AdminCarTile> createState() => _AdminCarTileState();
}

class _AdminCarTileState extends State<_AdminCarTile>
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
              padding: const EdgeInsets.all(22),
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
                        widget.car.category,
                        style: const TextStyle(
                          color: _muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusPill(status: widget.car.status),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(child: _CarImage(imageUrl: widget.car.imageUrl)),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _Spec(Icons.local_gas_station, widget.car.fuel),
                _Spec(Icons.settings, widget.car.transmission),
                _Spec(Icons.people, '${widget.car.seats} People'),
              ],
            ),
            const SizedBox(height: 20),
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
                IconButton(
                  tooltip: 'Edit car',
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_outlined, color: _blue),
                ),
                IconButton(
                  tooltip: 'Delete car',
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline, color: _red),
                ),
              ],
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: available ? const Color(0xFFEFFAF3) : const Color(0xFFFFF2F2),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: available ? const Color(0xFF17A34A) : _red,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
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
        Icon(icon, size: 18, color: _muted),
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

class _CarPhotoDraft {
  const _CarPhotoDraft._({required this.fileName, this.bytes, this.remoteUrl});

  factory _CarPhotoDraft.local({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _CarPhotoDraft._(bytes: bytes, fileName: fileName);
  }

  factory _CarPhotoDraft.remote(String url) {
    return _CarPhotoDraft._(remoteUrl: url, fileName: 'car_photo.jpg');
  }

  final Uint8List? bytes;
  final String? remoteUrl;
  final String fileName;
}

class _CarPhotoPicker extends StatelessWidget {
  const _CarPhotoPicker({
    required this.photos,
    required this.saving,
    required this.onPick,
    required this.onRemove,
  });

  final List<_CarPhotoDraft> photos;
  final bool saving;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Car photos',
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: saving ? null : onPick,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _soft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: photos.isEmpty ? _blue : _line,
                  width: photos.isEmpty ? 1.4 : 1,
                ),
              ),
              child: photos.isEmpty
                  ? const SizedBox(
                      height: 138,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: _blue,
                            size: 42,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Click to add 1 to 4 car photos',
                            style: TextStyle(
                              color: _text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'The first photo will be used as the main car image.',
                            style: TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (var i = 0; i < photos.length; i++)
                          _PhotoThumb(
                            photo: photos[i],
                            index: i,
                            saving: saving,
                            onRemove: () => onRemove(i),
                          ),
                        if (photos.length < 4)
                          const SizedBox(
                            width: 104,
                            height: 92,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                color: _blue,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${photos.length}/4 photos selected',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({
    required this.photo,
    required this.index,
    required this.saving,
    required this.onRemove,
  });

  final _CarPhotoDraft photo;
  final int index;
  final bool saving;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bytes = photo.bytes;
    final remoteUrl = photo.remoteUrl;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 104,
            height: 92,
            color: Colors.white,
            child: bytes != null
                ? Image.memory(bytes, fit: BoxFit.cover)
                : remoteUrl != null
                ? Image.network(
                    remoteUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.directions_car, color: _muted),
                  )
                : const Icon(Icons.directions_car, color: _muted),
          ),
        ),
        Positioned(
          left: 6,
          bottom: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.56),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              index == 0 ? 'Main' : '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        Positioned(
          right: -8,
          top: -8,
          child: IconButton.filled(
            onPressed: saving ? null : onRemove,
            iconSize: 15,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(backgroundColor: _red),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _CarFormDialog extends StatefulWidget {
  const _CarFormDialog({this.car, required this.onSaved});

  final _AdminCar? car;
  final VoidCallback onSaved;

  @override
  State<_CarFormDialog> createState() => _CarFormDialogState();
}

class _CarFormDialogState extends State<_CarFormDialog>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _nameCtrl;
  late String _model;
  late final TextEditingController _plateCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _seatsCtrl;
  late final TextEditingController _totalCtrl;
  final _imagePicker = ImagePicker();
  final _cloudinary = const CloudinaryService();
  final List<_CarPhotoDraft> _photos = [];

  // Model dropdown options and animation
  static const _allowedModels = [
    'Toyota',
    'Nissan',
    'Suzuki',
    'Honda',
    'Mitsubishi',
    'Ford',
  ];
  late final AnimationController _modelFieldCtrl;
  late final Animation<double> _modelFade;

  late String _category;
  late String _fuel;
  late String _transmission;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final car = widget.car;
    _nameCtrl = TextEditingController(text: car?.name ?? '');
    _model = (car != null && car.model.trim().isNotEmpty)
        ? car.model.trim()
        : _allowedModels.first;
    _plateCtrl = TextEditingController(text: car?.plateNumber ?? '');
    _rateCtrl = TextEditingController(
      text: car == null ? '' : '${car.dailyRate}',
    );
    _seatsCtrl = TextEditingController(
      text: car == null ? '5' : '${car.seats}',
    );
    _totalCtrl = TextEditingController(
      text: car == null ? '1' : '${car.total}',
    );
    _photos.addAll(
      (car?.imageUrls ?? const <String>[]).map(_CarPhotoDraft.remote),
    );
    _category = _validCategory(car?.category);
    _fuel = car?.fuel ?? 'Gasoline';
    _transmission = car?.transmission ?? 'Automatic';
    _status = car?.status ?? 'available';
    _modelFieldCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
    _modelFade = CurvedAnimation(parent: _modelFieldCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _plateCtrl.dispose();
    _rateCtrl.dispose();
    _seatsCtrl.dispose();
    _totalCtrl.dispose();
    _modelFieldCtrl.dispose();
    super.dispose();
  }

  static const _allowedCategories = [
    'Sedan',
    'Hatchback',
    'Van',
    'SUV',
    'Pickup',
  ];

  String _validCategory(String? category) {
    if (category != null && _allowedCategories.contains(category)) {
      return category;
    }
    return 'Sedan';
  }

  Future<void> _pickCarPhotos() async {
    final remaining = 4 - _photos.length;
    if (remaining <= 0) {
      _message('You can add up to 4 car photos only.');
      return;
    }

    final images = await _imagePicker.pickMultiImage(
      imageQuality: 84,
      maxWidth: 1600,
    );
    if (images.isEmpty) return;

    final selected = images.take(remaining);
    final drafts = <_CarPhotoDraft>[];
    for (final image in selected) {
      drafts.add(
        _CarPhotoDraft.local(
          bytes: await image.readAsBytes(),
          fileName: image.name,
        ),
      );
    }
    if (!mounted) return;

    setState(() => _photos.addAll(drafts));
    if (images.length > remaining) {
      _message('Only 4 car photos are allowed.');
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<List<String>> _uploadCarPhotos() async {
    final urls = <String>[];
    for (final photo in _photos) {
      if (photo.remoteUrl != null) {
        urls.add(photo.remoteUrl!);
        continue;
      }

      final bytes = photo.bytes;
      if (bytes == null) continue;

      final url = await _cloudinary
          .uploadProfileImage(bytes: bytes, fileName: photo.fileName)
          .timeout(const Duration(seconds: 25));
      urls.add(url);
    }
    return urls.take(4).toList();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final model = _model.trim();
    final plate = _plateCtrl.text.trim();
    final rate = int.tryParse(_rateCtrl.text.trim());
    final seats = int.tryParse(_seatsCtrl.text.trim());
    final total = int.tryParse(_totalCtrl.text.trim());

    if (name.isEmpty || model.isEmpty || plate.isEmpty || rate == null) {
      _message('Enter the car name, model, plate number, and daily rate.');
      return;
    }

    if (_photos.isEmpty) {
      _message('Add at least 1 car photo.');
      return;
    }

    setState(() => _saving = true);
    try {
      final imageUrls = await _uploadCarPhotos();
      final data = {
        'name': name,
        'model': model,
        'plateNumber': plate,
        'category': _category,
        'fuel': _fuel,
        'transmission': _transmission,
        'seats': seats ?? 5,
        'total': total ?? 1,
        'dailyRate': rate,
        'status': _status,
        'imageUrl': imageUrls.isEmpty ? null : imageUrls.first,
        'imageUrls': imageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final collection = FirebaseFirestore.instance.collection('vehicles');
      if (widget.car == null) {
        await collection.add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await collection.doc(widget.car!.id).update(data);
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } on FirebaseException catch (error) {
      _message(error.message ?? 'Could not save the car.');
    } on Exception catch (error) {
      debugPrint('Car save failed: $error');
      _message('Could not save the car photos. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.car == null ? 'Add Car' : 'Edit Car',
                style: const TextStyle(
                  color: _text,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 22),
              _Input(controller: _nameCtrl, label: 'Car name'),
              FadeTransition(
                opacity: _modelFade,
                child: _Select(
                  label: 'Model / variant',
                  value: _model,
                  items: _allowedModels,
                  onChanged: (value) => setState(() => _model = value),
                ),
              ),
              _Input(controller: _plateCtrl, label: 'Plate number'),
              Row(
                children: [
                  Expanded(
                    child: _Input(
                      controller: _rateCtrl,
                      label: 'Daily rate',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Input(
                      controller: _seatsCtrl,
                      label: 'Seats',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Input(
                      controller: _totalCtrl,
                      label: 'Total cars',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _Select(
                      label: 'Category',
                      value: _category,
                      items: const [
                        'Sedan',
                        'Hatchback',
                        'Van',
                        'SUV',
                        'Pickup',
                      ],
                      onChanged: (value) => setState(() => _category = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Select(
                      label: 'Fuel',
                      value: _fuel,
                      items: const ['Gasoline', 'Diesel', 'Hybrid', 'Electric'],
                      onChanged: (value) => setState(() => _fuel = value),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _Select(
                      label: 'Transmission',
                      value: _transmission,
                      items: const ['Automatic', 'Manual', 'CVT'],
                      onChanged: (value) =>
                          setState(() => _transmission = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Select(
                      label: 'Status',
                      value: _status,
                      items: const [
                        'available',
                        'rented',
                        'maintenance',
                        'inactive',
                      ],
                      onChanged: (value) => setState(() => _status = value),
                    ),
                  ),
                ],
              ),
              _CarPhotoPicker(
                photos: _photos,
                saving: _saving,
                onPick: _pickCarPhotos,
                onRemove: _removePhoto,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(backgroundColor: _blue),
                      child: Text(_saving ? 'Saving...' : 'Save Car'),
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

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _muted),
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
    );
  }
}

class _Select extends StatelessWidget {
  const _Select({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: items.contains(value) ? value : items.first,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _muted),
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
    );
  }
}
