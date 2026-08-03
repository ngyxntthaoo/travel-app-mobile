import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../db/db_helper.dart';
import '../models/itinerary_place.dart';
import '../models/trip.dart';
import '../services/route_optimizer.dart';
import '../services/mapbox_service.dart';
import '../theme/app_colors.dart';

enum _MapMode { route, keyStops }

class TripRouteMapScreen extends StatefulWidget {
  final Trip trip;
  final bool allowReorder;
  final VoidCallback? onRouteUpdated;

  const TripRouteMapScreen({
    super.key,
    required this.trip,
    this.allowReorder = true,
    this.onRouteUpdated,
  });

  @override
  State<TripRouteMapScreen> createState() => _TripRouteMapScreenState();
}

class _TripRouteMapScreenState extends State<TripRouteMapScreen> {
  final _mapController = MapController();
  List<ItineraryPlace> _places = [];
  bool _loading = true;
  bool _showOptimized = true;
  _MapMode _mode = _MapMode.route;
  String? _selectedDay; // null = all days
  ItineraryPlace? _selectedPlace;
  
  List<LatLng> _currentRouteReal = [];
  List<LatLng> _optimizedRouteReal = [];
  List<LatLng> _keyStopsReal = [];
  bool _fetchingRoutes = false;

  // Grouping radius for key-stop recommendation. Null = auto.
  double? _radiusKm;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    setState(() => _loading = true);
    final places = await DbHelper.instance.readItineraryPlacesForTrip(widget.trip.id!);
    if (!mounted) return;
    setState(() {
      _places = places;
      _loading = false;
    });
    _fitBounds();
    _refreshRealRoutes();
  }

  Future<void> _refreshRealRoutes() async {
    final current = _currentRoute;
    final optimized = _optimizedRoute;
    final rec = _recommendation;
    
    setState(() => _fetchingRoutes = true);
    
    final currentReal = await MapboxService.getRoute(_toLatLngs(current));
    final optimizedReal = await MapboxService.getRoute(_toLatLngs(optimized));
    final keyStopsReal = await MapboxService.getRoute(_toLatLngs(rec.keyStops));
    
    if (!mounted) return;
    setState(() {
      _currentRouteReal = currentReal;
      _optimizedRouteReal = optimizedReal;
      _keyStopsReal = keyStopsReal;
      _fetchingRoutes = false;
    });
  }

  List<String> get _availableDays {
    final days = _places
        .where((p) => p.lat != null && p.lng != null)
        .map((p) => p.date)
        .toSet()
        .toList()
      ..sort();
    return days;
  }

  List<ItineraryPlace> get _filteredPlaces {
    if (_selectedDay == null) return _places;
    return _places.where((p) => p.date == _selectedDay).toList();
  }

  List<ItineraryPlace> get _currentRoute =>
      RouteOptimizer.currentOrder(_filteredPlaces);

  List<ItineraryPlace> get _optimizedRoute =>
      RouteOptimizer.optimize(_filteredPlaces);

  RouteRecommendation get _recommendation =>
      RouteOptimizer.recommendKeyStops(_filteredPlaces, radiusKm: _radiusKm);

  List<LatLng> _toLatLngs(List<ItineraryPlace> route) =>
      route.map((p) => LatLng(p.lat!, p.lng!)).toList();

  void _fitBounds() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final coords = _currentRoute;
      if (coords.isEmpty) {
        if (widget.trip.destinationLat != null && widget.trip.destinationLng != null) {
          _mapController.move(
            LatLng(widget.trip.destinationLat!, widget.trip.destinationLng!),
            12,
          );
        }
        return;
      }
      if (coords.length == 1) {
        _mapController.move(LatLng(coords.first.lat!, coords.first.lng!), 14);
        return;
      }
      final bounds = LatLngBounds.fromPoints(_toLatLngs(coords));
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
      );
    });
  }

  Future<void> _applyOptimizedRoute() async {
    final optimized = _optimizedRoute;
    if (optimized.length < 2) return;
    await DbHelper.instance.reorderItineraryPlaces(
      optimized.map((p) => p.id!).toList(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Applied suggested route order')),
    );
    widget.onRouteUpdated?.call();
    _loadPlaces();
  }

  void _showPlaceInfo(ItineraryPlace place, {List<ItineraryPlace> satellites = const []}) {
    setState(() => _selectedPlace = place);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(place.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (place.location.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(place.location, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (place.startTime.isNotEmpty)
                  Chip(
                    label: Text('${place.startTime}${place.endTime.isNotEmpty ? ' – ${place.endTime}' : ''}'),
                    visualDensity: VisualDensity.compact,
                  ),
                if (place.cost > 0) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('\$${place.cost.toStringAsFixed(0)}'),
                    backgroundColor: AppColors.teal.withValues(alpha: 0.1),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            if (satellites.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.near_me_outlined, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    'Nearby stops grouped here (${satellites.length})',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...satellites.map((s) {
                final dist = RouteOptimizer.haversineKmBetween(place, s);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s.title, style: const TextStyle(fontSize: 13))),
                      Text('${dist.toStringAsFixed(1)} km', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.teal)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Route Map'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildModeSelector(),
          if (_availableDays.length > 1) _buildDayChips(),
          Expanded(
            child: _mode == _MapMode.route ? _buildRouteView() : _buildKeyStopsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SegmentedButton<_MapMode>(
        segments: const [
          ButtonSegment(value: _MapMode.route, icon: Icon(Icons.timeline_rounded, size: 18), label: Text('Route')),
          ButtonSegment(value: _MapMode.keyStops, icon: Icon(Icons.auto_awesome_rounded, size: 18), label: Text('Key stops')),
        ],
        selected: {_mode},
        showSelectedIcon: false,
        onSelectionChanged: (s) {
          setState(() => _mode = s.first);
          _fitBounds();
          // Real routes for Key stops might need fetching if radius changed
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? AppColors.teal : Colors.white),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? Colors.white : AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildDayChips() {
    final chips = <Widget>[
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: const Text('All days', style: TextStyle(fontSize: 12)),
          selected: _selectedDay == null,
          onSelected: (_) {
            setState(() => _selectedDay = null);
            _fitBounds();
            _refreshRealRoutes();
          },
          selectedColor: AppColors.teal.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: _selectedDay == null ? AppColors.teal : Colors.grey.shade700,
            fontWeight: _selectedDay == null ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
      ..._availableDays.map((day) {
        final selected = day == _selectedDay;
        final label = DateFormat('EEE d MMM').format(DateTime.parse(day));
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label, style: const TextStyle(fontSize: 12)),
            selected: selected,
            onSelected: (_) {
              setState(() => _selectedDay = day);
              _fitBounds();
              _refreshRealRoutes();
            },
            selectedColor: AppColors.teal.withValues(alpha: 0.15),
            labelStyle: TextStyle(
              color: selected ? AppColors.teal : Colors.grey.shade700,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }),
    ];

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: chips,
      ),
    );
  }

  Widget _buildEmptyOverlay() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)],
        ),
        child: const Text(
          'Add places with map locations in your itinerary to see the route here.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ─────────────────────────────── Route view ───────────────────────────────

  Widget _buildRouteView() {
    final current = _currentRoute;
    final optimized = _optimizedRoute;
    final currentDist = RouteOptimizer.routeDistanceKm(current);
    final optimizedDist = RouteOptimizer.routeDistanceKm(optimized);
    final savings = currentDist > 0 && optimizedDist < currentDist
        ? ((1 - optimizedDist / currentDist) * 100).clamp(0, 99)
        : 0.0;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.trip.destinationLat != null
                ? LatLng(widget.trip.destinationLat!, widget.trip.destinationLng!)
                : const LatLng(21.0, 105.8),
            initialZoom: 12,
            onTap: (_, __) => setState(() => _selectedPlace = null),
          ),
          children: [
            _tileLayer(),
            if (_currentRouteReal.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(points: _currentRouteReal, color: AppColors.teal, strokeWidth: 4),
                ],
              ),
            if (_showOptimized && _optimizedRouteReal.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _optimizedRouteReal,
                    color: Colors.orange.shade600.withValues(alpha: 0.85),
                    strokeWidth: 3,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (var i = 0; i < current.length; i++)
                  _numberedMarker(current[i], i + 1, current[i].id == _selectedPlace?.id,
                      onTap: () => _showPlaceInfo(current[i])),
              ],
            ),
          ],
        ),
        if (current.isEmpty) _buildEmptyOverlay(),
        if (optimized.length > 1 && savings > 0)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _infoBanner(
              icon: Icons.route_rounded,
              iconColor: Colors.orange.shade700,
              text:
                  'Suggested route saves ~${savings.toStringAsFixed(0)}% distance (${optimizedDist.toStringAsFixed(1)} km vs ${currentDist.toStringAsFixed(1)} km)',
              trailing: widget.allowReorder
                  ? TextButton(onPressed: _applyOptimizedRoute, child: const Text('Apply'))
                  : null,
            ),
          ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                _legendDot(AppColors.teal, 'Current route'),
                const SizedBox(width: 16),
                _legendDot(Colors.orange.shade600, 'Suggested route'),
                const Spacer(),
                Switch(
                  value: _showOptimized,
                  onChanged: (v) => setState(() => _showOptimized = v),
                  activeColor: AppColors.teal,
                ),
              ],
            ),
          ),
        ),
        if (_fetchingRoutes)
          Positioned(
            top: 76,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text('Fetching real routes...', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────── Key stops view ───────────────────────────

  Widget _buildKeyStopsView() {
    final rec = _recommendation;
    final keyLatLngs = _toLatLngs(rec.keyStops);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.trip.destinationLat != null
                ? LatLng(widget.trip.destinationLat!, widget.trip.destinationLng!)
                : const LatLng(21.0, 105.8),
            initialZoom: 12,
            onTap: (_, __) => setState(() => _selectedPlace = null),
          ),
          children: [
            _tileLayer(),
            // Thin links from each satellite to its key stop.
            PolylineLayer(
              polylines: [
                for (final key in rec.keyStops)
                  for (final sat in rec.satellitesFor(key))
                    Polyline(
                      points: [LatLng(key.lat!, key.lng!), LatLng(sat.lat!, sat.lng!)],
                      color: Colors.grey.shade400,
                      strokeWidth: 1.5,
                    ),
              ],
            ),
            // Main route through key stops.
            if (_keyStopsReal.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(points: _keyStopsReal, color: AppColors.teal, strokeWidth: 4),
                ],
              ),
            // Satellite (minor) markers.
            MarkerLayer(
              markers: [
                for (final key in rec.keyStops)
                  for (final sat in rec.satellitesFor(key))
                    _satelliteMarker(sat, () => _showPlaceInfo(sat)),
              ],
            ),
            // Key stop (main) markers on top.
            MarkerLayer(
              markers: [
                for (var i = 0; i < rec.keyStops.length; i++)
                  _numberedMarker(
                    rec.keyStops[i],
                    i + 1,
                    rec.keyStops[i].id == _selectedPlace?.id,
                    big: true,
                    onTap: () => _showPlaceInfo(
                      rec.keyStops[i],
                      satellites: rec.satellitesFor(rec.keyStops[i]),
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (rec.keyStops.isEmpty) _buildEmptyOverlay(),
        if (rec.originalCount > 0)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _infoBanner(
              icon: Icons.auto_awesome_rounded,
              iconColor: AppColors.teal,
              text: rec.mergedCount > 0
                  ? '${rec.originalCount} locations → ${rec.keyCount} key stops · ${rec.mergedCount} grouped nearby${rec.savingsPercent > 0 ? ' · saves ~${rec.savingsPercent.toStringAsFixed(0)}%' : ''}'
                  : '${rec.originalCount} locations — already spread out, no grouping needed',
            ),
          ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: _cardDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _legendDot(AppColors.teal, 'Key stop'),
                    const SizedBox(width: 16),
                    _legendDot(Colors.grey.shade400, 'Nearby (grouped)'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Group radius', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    Expanded(
                      child: Slider(
                        value: rec.radiusKm.clamp(0.2, 8.0),
                        min: 0.2,
                        max: 8.0,
                        divisions: 39,
                        activeColor: AppColors.teal,
                        label: '${rec.radiusKm.toStringAsFixed(1)} km',
                        onChanged: (v) => setState(() => _radiusKm = v),
                      ),
                    ),
                    SizedBox(
                      width: 46,
                      child: Text(
                        '${rec.radiusKm.toStringAsFixed(1)}km',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() => _radiusKm = null);
                      _fitBounds();
                      _refreshRealRoutes();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Auto', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────── Shared bits ──────────────────────────────

  TileLayer _tileLayer() => TileLayer(
        urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoidGhuaHRoYW8iLCJhIjoiY21zMTV1aGRoMDBhZzJ4b2gwOGp2djd1cCJ9.FAfa4g8ZP_B0MrBcLA1mLw',
        // subdomains: const ['a', 'b', 'c', 'd'],
        userAgentPackageName: 'com.example.trip_planner',
      );

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
      );

  Widget _infoBanner({
    required IconData icon,
    required Color iconColor,
    required String text,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Marker _numberedMarker(
    ItineraryPlace place,
    int number,
    bool selected, {
    bool big = false,
    required VoidCallback onTap,
  }) {
    final size = big ? 46.0 : 40.0;
    return Marker(
      point: LatLng(place.lat!, place.lng!),
      width: size,
      height: size,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? AppColors.navyDark : AppColors.teal,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: big ? 3 : 2),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: big ? 6 : 4)],
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: big ? 16 : 13),
          ),
        ),
      ),
    );
  }

  Marker _satelliteMarker(ItineraryPlace place, VoidCallback onTap) {
    return Marker(
      point: LatLng(place.lat!, place.lng!),
      width: 18,
      height: 18,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade500, width: 2),
          ),
        ),
      ),
    );
  }
}
