import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import '../utils/map_keys.dart';

class MapPickerResult {
  final LatLng latLng;
  final String address;

  MapPickerResult(this.latLng, this.address);

  LatLng get position => latLng;
}

class MapPicker extends StatefulWidget {
  final LatLng initialPosition;
  final String? initialAddress;

  const MapPicker({
    super.key,
    required this.initialPosition,
    this.initialAddress,
  });

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  late final MapController _mapCtrl;
  late LatLng _selected;
  double _zoom = 13;
  final TextEditingController _searchCtrl = TextEditingController();
  List<dynamic> _searchResults = [];
  String _address = '';

  @override
  void initState() {
    super.initState();
    _mapCtrl = MapController();
    _selected = widget.initialPosition;
    _address = widget.initialAddress ?? '';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    try {
      final url = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': pos.latitude.toString(),
        'lon': pos.longitude.toString(),
      });
      final res = await http.get(url, headers: {'User-Agent': 'crbs-app'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final display = (data['display_name'] ?? '') as String;
        if (!mounted) return;
        setState(() => _address = display);
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _searchPlace(String q) async {
    if (q.trim().isEmpty) return;
    try {
      final url = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'jsonv2',
        'q': q,
        'addressdetails': '1',
        'limit': '10',
      });
      final res = await http.get(url, headers: {'User-Agent': 'crbs-app'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List<dynamic>;
        if (!mounted) return;
        setState(() => _searchResults = data);
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enable device location services.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission permanently denied.'),
          ),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final llPos = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _selected = llPos;
        _zoom = 15;
      });
      _mapCtrl.move(llPos, _zoom);
      await _reverseGeocode(llPos);
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick location'),
        actions: [
          IconButton(
            tooltip: 'Use my location',
            onPressed: _goToCurrentLocation,
            icon: const Icon(Icons.my_location_outlined),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(MapPickerResult(_selected, _address));
            },
            child: const Text('Select', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: widget.initialPosition,
              initialZoom: _zoom,
              onTap: (tapPos, latlng) async {
                setState(() => _selected = latlng);
                await _reverseGeocode(latlng);
                _mapCtrl.move(latlng, _zoom);
              },
              onPositionChanged: (pos, _) {
                setState(() => _zoom = pos.zoom);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: getTileUrlTemplate(),
                userAgentPackageName: 'org.crbs.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selected,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // overlayed search controls
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search place or address',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchResults = []);
                            },
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onSubmitted: _searchPlace,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 180,
                          child: Text(
                            _address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Use my location',
                      onPressed: _goToCurrentLocation,
                      icon: const Icon(Icons.gps_fixed),
                    ),
                  ],
                ),
                if (_searchResults.isNotEmpty)
                  SizedBox(
                    height: 160,
                    child: Card(
                      margin: const EdgeInsets.only(top: 8),
                      child: ListView.separated(
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final item =
                              _searchResults[i] as Map<String, dynamic>;
                          return ListTile(
                            title: Text(item['display_name'] ?? ''),
                            onTap: () {
                              final lat =
                                  double.tryParse(
                                    item['lat']?.toString() ?? '',
                                  ) ??
                                  0;
                              final lon =
                                  double.tryParse(
                                    item['lon']?.toString() ?? '',
                                  ) ??
                                  0;
                              final llPos = LatLng(lat, lon);
                              setState(() {
                                _selected = llPos;
                                _searchResults = [];
                                _searchCtrl.text = item['display_name'] ?? '';
                              });
                              _mapCtrl.move(llPos, _zoom);
                              _reverseGeocode(llPos);
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // confirm button
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop(MapPickerResult(_selected, _address));
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text('Confirm location'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
