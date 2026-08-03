import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';

/// Displays trip date range and destination — shared by trip detail, expenses, and edit-note screens.
class TripSubheader extends StatelessWidget {
  const TripSubheader({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final startStr = DateFormat('dd MMM').format(trip.startDate);
    final endStr = DateFormat('dd MMM, yyyy').format(trip.endDate);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$startStr - $endStr',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            trip.mainDestination,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
