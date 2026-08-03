import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/trip.dart';
import '../theme/app_colors.dart';
import 'shared_trip_screen.dart';

class SharedTripsFeedScreen extends StatefulWidget {
  const SharedTripsFeedScreen({super.key});

  @override
  State<SharedTripsFeedScreen> createState() => _SharedTripsFeedScreenState();
}

class _SharedTripsFeedScreenState extends State<SharedTripsFeedScreen> {
  List<Trip> _trips = [];
  bool _loading = true;
  String? _error;
  final _tokenCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trips = await DbHelper.instance.readPublicTrips();
      if (!mounted) return;
      setState(() {
        _trips = trips;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load shared trips. Please refresh the page.';
      });
    }
  }

  Future<void> _openByToken() async {
    final token = _tokenCtrl.text.trim();
    if (token.isEmpty) return;
    final trip = await DbHelper.instance.readTripByShareToken(token);
    if (!mounted) return;
    if (trip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shared trip not found or no longer public')),
      );
      return;
    }
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SharedTripScreen(trip: trip)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Shared Trips'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.teal,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tokenCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Enter share token...',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _openByToken,
                          icon: const Icon(Icons.search_rounded, color: AppColors.teal),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_trips.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Column(
                        children: [
                          Icon(Icons.public_off_outlined, size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'No public trips yet',
                            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Share a trip from Trip detail to make it visible here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._trips.map(_buildTripCard),
                ],
              ),
            ),
    );
  }

  Widget _buildTripCard(Trip trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(trip.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${trip.mainDestination}\n${DateFormat('d MMM').format(trip.startDate)} – ${DateFormat('d MMM yyyy').format(trip.endDate)}',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.4),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () async {
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => SharedTripScreen(trip: trip)),
          );
          _load();
        },
      ),
    );
  }
}
