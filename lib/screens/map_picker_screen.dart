import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';

// Result returned to caller
class MapPickerResult {
  final String name;
  final String address;
  final double lat;
  final double lng;

  const MapPickerResult({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });
}

class MapPickerScreen extends StatefulWidget {
  final String destination;
  const MapPickerScreen({super.key, required this.destination});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final _searchCtrl = TextEditingController();
  final _mapController = MapController();
  final _debounce = _Debouncer(milliseconds: 500);

  LatLng _center = const LatLng(0, 0);
  LatLng? _pinLatLng;
  String _pinName = '';
  String _pinAddress = '';

  List<_NominatimResult> _suggestions = [];
  bool _searching = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _geocodeDestination();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _mapController.dispose();
    _debounce.dispose();
    super.dispose();
  }

  Future<void> _geocodeDestination() async {
    final results = await _nominatimSearch(widget.destination, limit: 1);
    if (results.isNotEmpty && mounted) {
      final r = results.first;
      setState(() {
        _center = LatLng(r.lat, r.lng);
        _pinLatLng = _center;
        _pinName = r.name;
        _pinAddress = r.address;
      });
      if (_mapReady) {
        _mapController.move(_center, 12);
      }
    }
  }

  Future<List<_NominatimResult>> _nominatimSearch(String query, {int limit = 6}) async {
    if (query.trim().isEmpty) return [];
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&limit=$limit'
        '&addressdetails=1',
      );
      final resp = await http.get(uri, headers: {'User-Agent': 'TripPlannerApp/1.0 (flutter)'});
      if (resp.statusCode != 200) return [];
      final data = json.decode(resp.body) as List;
      return data.map((e) => _NominatimResult.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _reverseGeocode(LatLng latlng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${latlng.latitude}&lon=${latlng.longitude}'
        '&format=json',
      );
      final resp = await http.get(uri, headers: {'User-Agent': 'TripPlannerApp/1.0 (flutter)'});
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final name = data['name'] as String? ?? '';
        final display = data['display_name'] as String? ?? '';
        setState(() {
          _pinName = name.isNotEmpty ? name : display.split(',').first.trim();
          _pinAddress = display;
        });
      }
    } catch (_) {}
  }

  void _onSearchChanged(String value) {
    _debounce.run(() async {
      if (value.trim().isEmpty) {
        setState(() => _suggestions = []);
        return;
      }
      setState(() => _searching = true);
      final results = await _nominatimSearch(value);
      if (mounted) setState(() { _suggestions = results; _searching = false; });
    });
  }

  void _selectSuggestion(_NominatimResult r) {
    final latlng = LatLng(r.lat, r.lng);
    setState(() {
      _pinLatLng = latlng;
      _pinName = r.name;
      _pinAddress = r.address;
      _suggestions = [];
      _searchCtrl.text = r.name;
    });
    _mapController.move(latlng, 15);
    FocusScope.of(context).unfocus();
  }

  void _onMapTap(TapPosition _, LatLng latlng) {
    setState(() {
      _pinLatLng = latlng;
      _pinName = 'Dropped Pin';
      _pinAddress = '${latlng.latitude.toStringAsFixed(5)}, ${latlng.longitude.toStringAsFixed(5)}';
      _suggestions = [];
    });
    _reverseGeocode(latlng);
    FocusScope.of(context).unfocus();
  }

  void _confirm() {
    if (_pinLatLng == null) return;
    Navigator.pop(context, MapPickerResult(
      name: _pinName,
      address: _pinAddress,
      lat: _pinLatLng!.latitude,
      lng: _pinLatLng!.longitude,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Pick a location', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center.latitude != 0 ? _center : const LatLng(21.0, 105.8),
              initialZoom: 13,
              onMapReady: () {
                _mapReady = true;
                if (_center.latitude != 0) {
                  _mapController.move(_center, 12);
                }
              },
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoidGhuaHRoYW8iLCJhIjoiY21zMTV1aGRoMDBhZzJ4b2gwOGp2djd1cCJ9.FAfa4g8ZP_B0MrBcLA1mLw',
                // subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.trip_planner',
              ),
              if (_pinLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pinLatLng!,
                      width: 40,
                      height: 48,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_on_rounded, color: Colors.red, size: 40),
                    ),
                  ],
                ),
            ],
          ),

          // Search bar + suggestions overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Search bar
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search places in ${widget.destination}...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)),
                            )
                          : _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                  onPressed: () { _searchCtrl.clear(); setState(() => _suggestions = []); },
                                )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                // Suggestions dropdown
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (_, i) {
                        final r = _suggestions[i];
                        return ListTile(
                          dense: true,
                          leading: Icon(Icons.place_outlined, color: AppColors.teal, size: 18),
                          title: Text(r.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          subtitle: Text(
                            r.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                          onTap: () => _selectSuggestion(r),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Bottom confirm card
          if (_pinLatLng != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.13), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.teal.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.location_on_rounded, color: AppColors.teal, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _pinName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _pinAddress,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Nominatim result model
// ─────────────────────────────────────────────

class _NominatimResult {
  final String name;
  final String address;
  final double lat;
  final double lng;

  const _NominatimResult({required this.name, required this.address, required this.lat, required this.lng});

  factory _NominatimResult.fromJson(Map<String, dynamic> json) {
    final display = json['display_name'] as String? ?? '';
    final parts = display.split(',');
    final name = parts.isNotEmpty ? parts.first.trim() : display;
    final shortAddr = parts.length > 1
        ? parts.skip(1).take(2).map((s) => s.trim()).where((s) => s.isNotEmpty).join(', ')
        : display;
    return _NominatimResult(
      name: name,
      address: shortAddr,
      lat: double.tryParse(json['lat'] as String? ?? '') ?? 0,
      lng: double.tryParse(json['lon'] as String? ?? '') ?? 0,
    );
  }
}

// ─────────────────────────────────────────────
// Debouncer
// ─────────────────────────────────────────────

class _Debouncer {
  final int milliseconds;
  Timer? _timer;
  _Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() => _timer?.cancel();
}
