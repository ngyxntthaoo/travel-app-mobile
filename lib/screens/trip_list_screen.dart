import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/trip.dart';
import '../theme/app_colors.dart';
import '../utils/dialogs.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';
import 'create_trip_screen.dart';
import 'trip_detail_screen.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  List<Trip> _trips = [];
  bool _isLoading = true;

  static const _gradients = [
    AppColors.gradientBrown,
    AppColors.gradientBlue,
    AppColors.gradientGreen,
    [Color(0xFF8E24AA), Color(0xFFAB47BC)],
    [Color(0xFFE65100), Color(0xFFFF9800)],
    [Color(0xFF00695C), Color(0xFF009688)],
  ];

  @override
  void initState() {
    super.initState();
    _refreshTrips();
  }

  Future<void> _refreshTrips() async {
    setState(() => _isLoading = true);
    final trips = await DbHelper.instance.readAllTrips();
    setState(() {
      _trips = trips;
      _isLoading = false;
    });
  }

  void _navigateToCreateTrip() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateTripScreen()),
    );
    if (result == true) _refreshTrips();
  }

  void _deleteTrip(Trip trip) async {
    final confirmed = await showDeleteConfirmation(
      context: context,
      title: 'Delete Trip',
      content: 'Delete "${trip.title}"? All checklists, flights, notes and documents will be removed.',
    );
    if (confirmed) {
      await DbHelper.instance.deleteTrip(trip.id!);
      _refreshTrips();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('My Trips', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _trips.isEmpty
                        ? EmptyState(
                            icon: Icons.luggage_outlined,
                            title: 'No trips found',
                            subtitle: 'Tap the button below to plan your next adventure.',
                          )
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.95,
                            ),
                            itemCount: _trips.length,
                            itemBuilder: (context, index) {
                              final trip = _trips[index];
                              final gradient = _gradients[index % _gradients.length];
                              final startStr = DateFormat('dd MMM').format(trip.startDate);
                              final endStr = DateFormat('dd MMM').format(trip.endDate);

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
                                  ).then((_) => _refreshTrips());
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: gradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              trip.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              trip.mainDestination,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '$startStr - $endStr',
                                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: IconButton(
                                          icon: Icon(Icons.delete_outline_rounded, color: Colors.white.withValues(alpha: 0.6), size: 18),
                                          onPressed: () => _deleteTrip(trip),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Create New Trip',
                    icon: Icons.add,
                    onPressed: _navigateToCreateTrip,
                  ),
                ],
              ),
            ),
    );
  }
}
