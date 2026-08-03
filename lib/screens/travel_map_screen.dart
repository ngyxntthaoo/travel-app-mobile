import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/trip.dart';
import '../db/db_helper.dart';
import '../theme/app_colors.dart';
import 'trip_detail_screen.dart';
import 'package:intl/intl.dart';

class TravelMapScreen extends StatefulWidget {
  const TravelMapScreen({super.key});

  @override
  State<TravelMapScreen> createState() => _TravelMapScreenState();
}

class _TravelMapScreenState extends State<TravelMapScreen> {
  List<Trip> _trips = [];
  bool _isLoading = true;

  // A simple mock geocoding dictionary
  final Map<String, LatLng> _mockGeocode = {
    'singapore': const LatLng(1.3521, 103.8198),
    'japan': const LatLng(35.6762, 139.6503),
    'tokyo': const LatLng(35.6762, 139.6503),
    'vietnam': const LatLng(21.0285, 105.8542),
    'hanoi': const LatLng(21.0285, 105.8542),
    'ho chi minh': const LatLng(10.8231, 106.6297),
    'paris': const LatLng(48.8566, 2.3522),
    'london': const LatLng(51.5074, -0.1278),
    'new york': const LatLng(40.7128, -74.0060),
    'bangkok': const LatLng(13.7563, 100.5018),
    'seoul': const LatLng(37.5665, 126.9780),
  };

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final trips = await DbHelper.instance.readAllTrips();
    setState(() {
      _trips = trips;
      _isLoading = false;
    });
  }

  LatLng? _getLatLngForDestination(String destination) {
    String search = destination.toLowerCase();
    for (var key in _mockGeocode.keys) {
      if (search.contains(key)) return _mockGeocode[key];
    }
    return null;
  }

  void _showTripDetails(Trip trip) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final dateFormat = DateFormat('MMM d, yyyy');
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trip.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.teal, size: 20),
                  const SizedBox(width: 8),
                  Text(trip.mainDestination, style: const TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.teal, size: 20),
                  const SizedBox(width: 8),
                  Text('${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate)}'),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TripDetailScreen(trip: trip),
                      ),
                    );
                  },
                  child: const Text('View Full Trip Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final markers = <Marker>[];
    for (var trip in _trips) {
      final latLng = _getLatLngForDestination(trip.mainDestination);
      if (latLng != null) {
        markers.add(
          Marker(
            point: latLng,
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () => _showTripDetails(trip),
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Footprint'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(16.0, 105.0),
          initialZoom: 3.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.travel_mobile_app',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
