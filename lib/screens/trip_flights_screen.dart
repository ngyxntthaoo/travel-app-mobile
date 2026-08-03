import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/trip.dart';
import '../models/flight.dart';
import '../data/travelers.dart';
import '../services/flight_api_service.dart';
import '../theme/app_colors.dart';

class TripFlightsScreen extends StatefulWidget {
  final Trip trip;
  const TripFlightsScreen({super.key, required this.trip});

  @override
  State<TripFlightsScreen> createState() => _TripFlightsScreenState();
}

class _TripFlightsScreenState extends State<TripFlightsScreen> {
  List<Flight> _flights = [];
  bool _isLoading = true;

  final List<Map<String, String>> _travelers = kTravelers
      .map((t) => {'name': t.name, 'avatar': t.avatarUrl})
      .toList();

  @override
  void initState() {
    super.initState();
    _loadFlights();
  }

  Future<void> _loadFlights() async {
    setState(() => _isLoading = true);
    final flights = await DbHelper.instance.readFlightsForTrip(widget.trip.id!);
    setState(() {
      _flights = flights;
      _isLoading = false;
    });
  }

  void _showAddFlightOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add flight to this trip',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              ListTile(
                title: const Text('Search available flights', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Find and select flights by route & date'),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                contentPadding: EdgeInsets.zero,
                shape: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                onTap: () {
                  Navigator.pop(context);
                  _showFlightSearch();
                },
              ),
              ListTile(
                title: const Text('Add from my bookings', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                contentPadding: EdgeInsets.zero,
                shape: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                onTap: () {
                  Navigator.pop(context);
                  _showMyBookingsList();
                },
              ),
              ListTile(
                title: const Text('Add details manually', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(context);
                  _showManualAddDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFlightSearch() {
    final originCtrl = TextEditingController(text: 'SIN');
    final destCtrl = TextEditingController(text: 'DPS');
    DateTime searchDate = widget.trip.startDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddFlightOptions();
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text('Search flights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: originCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'From (IATA)',
                            hintText: 'SIN',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: destCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'To (IATA)',
                            hintText: 'DPS',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Departure date'),
                    subtitle: Text(DateFormat('EEE, d MMM yyyy').format(searchDate)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: searchDate,
                        firstDate: widget.trip.startDate.subtract(const Duration(days: 7)),
                        lastDate: widget.trip.endDate.add(const Duration(days: 7)),
                      );
                      if (picked != null) setModalState(() => searchDate = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF37849D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _showFlightSearchResults(
                        originCtrl.text.trim(),
                        destCtrl.text.trim(),
                        searchDate,
                      );
                    },
                    child: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFlightSearchResults(String origin, String destination, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: FlightApiService.instance.searchFlights(
                FlightSearchCriteria(origin: origin, destination: destination, date: date),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF37849D)));
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('No flights found for $origin → $destination on ${DateFormat('d MMM yyyy').format(date)}'),
                    ),
                  );
                }
                final flights = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                            onPressed: () {
                              Navigator.pop(context);
                              _showFlightSearch();
                            },
                          ),
                          Expanded(
                            child: Text(
                              '$origin → $destination · ${flights.length} flights',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: flights.length,
                          itemBuilder: (context, index) => _buildFlightOfferCard(flights[index]),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFlightOfferCard(Map<String, dynamic> flight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF37849D).withValues(alpha: 0.15), width: 1.5),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          final booking = Map<String, dynamic>.from(flight);
          booking['flight_date'] = flight['display_date'] ?? flight['flight_date'];
          _showSelectTravelers(booking);
        },
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              alignment: Alignment.center,
              child: Text(
                (flight['airline_name'] as String).substring(0, 1),
                style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    flight['airline_name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${flight['departure_time']} – ${flight['arrival_time']}  ·  ${flight['flight_code']}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  Text(
                    '${flight['departure_airport']} → ${flight['arrival_airport']}',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${(flight['price'] as num).toStringAsFixed(0)}',
                  style: const TextStyle(color: Color(0xFF37849D), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Text('per person', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMyBookingsList() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: FlightApiService.instance.fetchMyBookingsFromApi(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF37849D)));
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No bookings found. Please check manually.'));
                }
                final bookings = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                            onPressed: () {
                              Navigator.pop(context);
                              _showAddFlightOptions();
                            },
                          ),
                          const SizedBox(width: 8),
                          const Text('Add from my bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: bookings.length,
                          itemBuilder: (context, index) {
                            final b = bookings[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF37849D).withValues(alpha: 0.15), width: 1.5),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  _showSelectTravelers(b);
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: b['airline_name'] == 'AirAsia' ? const Color(0xFFE50914) : const Color(0xFF1E3A8A),
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        b['airline_name'] == 'AirAsia' ? 'AA' : 'SQ',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '${b['departure_time']}  to  ${b['arrival_time']}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                              ),
                                              const Spacer(),
                                              Text(b['flight_date'], style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Text('${b['departure_airport']} - ${b['arrival_airport']}', style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold)),
                                              const Spacer(),
                                              Text(b['flight_code'], style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Confirmation: ${b['confirmation_no']}', style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold)),
                                              if (b['price'] != null)
                                                Text('\$${b['price']}', style: const TextStyle(color: Color(0xFF37849D), fontWeight: FontWeight.bold, fontSize: 12)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showSelectTravelers(Map<String, dynamic> booking) {
    final selectedStatus = List<bool>.generate(_travelers.length, (index) => index == 0);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                        onPressed: () {
                          Navigator.pop(context);
                          _showMyBookingsList();
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text('Who is taking this flight?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _travelers.length,
                      itemBuilder: (context, index) {
                        final traveler = _travelers[index];
                        return CheckboxListTile(
                          value: selectedStatus[index],
                          activeColor: const Color(0xFF37849D),
                          title: Row(
                            children: [
                              CircleAvatar(radius: 14, backgroundImage: NetworkImage(traveler['avatar']!)),
                              const SizedBox(width: 12),
                              Text(traveler['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            ],
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              selectedStatus[index] = val ?? false;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF37849D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final selectedNames = <String>[];
                      for (int i = 0; i < selectedStatus.length; i++) {
                        if (selectedStatus[i]) {
                          selectedNames.add(_travelers[i]['name']!);
                        }
                      }
                      if (selectedNames.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one traveler.')));
                        return;
                      }

                      final flight = Flight(
                        tripId: widget.trip.id!,
                        flightCode: booking['flight_code'],
                        departureAirport: booking['departure_airport'],
                        arrivalAirport: booking['arrival_airport'],
                        departureTime: booking['departure_time'],
                        arrivalTime: booking['arrival_time'],
                        flightDate: booking['flight_date'],
                        confirmationNo: booking['confirmation_no'],
                        boardingTime: booking['boarding_time'],
                        gate: booking['gate'],
                        terminal: booking['terminal'],
                        seatNumber: booking['seat_number'],
                        passengerNames: selectedNames.join(', '),
                        airlineName: booking['airline_name'],
                        price: (booking['price'] != null) ? (booking['price'] as num).toDouble() : 0.0,
                      );

                      await DbHelper.instance.createFlight(flight);
                      _loadFlights();

                      if (context.mounted) {
                        Navigator.pop(context);
                        _showSuccessToast();
                      }
                    },
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSuccessToast() {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      margin: const EdgeInsets.only(bottom: 24, left: 60, right: 60),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      content: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Flight added to trip', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
          SizedBox(width: 6),
          Icon(Icons.check_circle, color: Colors.green, size: 16),
        ],
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showManualAddDialog({Flight? editFlight}) {
    final codeCtrl = TextEditingController(text: editFlight?.flightCode);
    final deptCtrl = TextEditingController(text: editFlight?.departureAirport);
    final arrCtrl = TextEditingController(text: editFlight?.arrivalAirport);
    final deptTimeCtrl = TextEditingController(text: editFlight?.departureTime);
    final arrTimeCtrl = TextEditingController(text: editFlight?.arrivalTime);
    final dateCtrl = TextEditingController(text: editFlight != null ? editFlight.flightDate : DateFormat('EEE, d MMM').format(widget.trip.startDate));
    final confCtrl = TextEditingController(text: editFlight?.confirmationNo);
    final priceCtrl = TextEditingController(text: editFlight != null ? editFlight.price.toStringAsFixed(2) : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(editFlight == null ? 'Add flight manually' : 'Edit Flight Details', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Flight Code (e.g. SQ 278)')),
                TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: 'Departure Airport (SIN)')),
                TextField(controller: arrCtrl, decoration: const InputDecoration(labelText: 'Arrival Airport (DPS)')),
                TextField(controller: deptTimeCtrl, decoration: const InputDecoration(labelText: 'Departure Time (e.g. 21:05)')),
                TextField(controller: arrTimeCtrl, decoration: const InputDecoration(labelText: 'Arrival Time (e.g. 00:50)')),
                TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Flight Date')),
                TextField(controller: confCtrl, decoration: const InputDecoration(labelText: 'Confirmation No.')),
                TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price / Cost (\$)')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            if (editFlight != null)
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  _deleteFlight(editFlight.id!);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF37849D)),
              onPressed: () async {
                if (codeCtrl.text.isEmpty || deptCtrl.text.isEmpty || arrCtrl.text.isEmpty) return;
                final flightPrice = double.tryParse(priceCtrl.text.trim()) ?? 0.0;

                if (editFlight == null) {
                  final flight = Flight(
                    tripId: widget.trip.id!,
                    flightCode: codeCtrl.text,
                    departureAirport: deptCtrl.text,
                    arrivalAirport: arrCtrl.text,
                    departureTime: deptTimeCtrl.text,
                    arrivalTime: arrTimeCtrl.text,
                    flightDate: dateCtrl.text,
                    confirmationNo: confCtrl.text,
                    boardingTime: '12:30 pm',
                    gate: '36',
                    terminal: '2',
                    seatNumber: 'D4',
                    passengerNames: 'Me',
                    airlineName: 'Singapore Airlines',
                    price: flightPrice,
                  );
                  await DbHelper.instance.createFlight(flight);
                } else {
                  final flight = editFlight.copyWith(
                    flightCode: codeCtrl.text,
                    departureAirport: deptCtrl.text,
                    arrivalAirport: arrCtrl.text,
                    departureTime: deptTimeCtrl.text,
                    arrivalTime: arrTimeCtrl.text,
                    flightDate: dateCtrl.text,
                    confirmationNo: confCtrl.text,
                    price: flightPrice,
                  );
                  await DbHelper.instance.updateFlight(flight);
                }
                
                _loadFlights();
                if (context.mounted) {
                  Navigator.pop(context);
                  _showSuccessToast();
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _deleteFlight(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Flight'),
        content: const Text('Are you sure you want to delete this flight? This will also remove the flight ticket information.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DbHelper.instance.deleteFlight(id);
      _loadFlights();
    }
  }

  void _showBoardingPass(Flight flight) {
    final travelers = flight.passengerNames.split(', ');
    final adultCount = travelers.length;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    children: [
                      Container(
                        height: 140,
                        color: Colors.blue.shade50,
                        padding: const EdgeInsets.all(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Opacity(
                              opacity: 0.25,
                              child: Image.network('https://images.unsplash.com/photo-1524661135-423995f22d0b?w=400&fit=crop', fit: BoxFit.cover),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(flight.departureAirport, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.navyDark)),
                                        const Text('Airport', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      ],
                                    ),
                                    const Icon(Icons.flight_takeoff_rounded, color: Color(0xFF37849D), size: 28),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(flight.arrivalAirport, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.navyDark)),
                                        const Text('Airport', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      ],
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    const Icon(Icons.movie_filter_outlined, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    const Text('In-flight\nmovie', style: TextStyle(fontSize: 9, color: Colors.grey, height: 1.1)),
                                    const Spacer(),
                                    const Icon(Icons.people_outline_rounded, size: 18, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text('$adultCount Adult\n0 Child', style: const TextStyle(fontSize: 9, color: Colors.grey, height: 1.1)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
                            ),
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Flex(
                                  direction: Axis.horizontal,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  mainAxisSize: MainAxisSize.max,
                                  children: List.generate(
                                    (constraints.constrainWidth() / 10).floor(),
                                    (index) => SizedBox(
                                      width: 5,
                                      height: 1,
                                      child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey.shade300)),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Container(
                            width: 14,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildTicketField("Passenger Name", travelers.first),
                                _buildTicketField("Flight Type", "Economy"),
                                _buildTicketField("Flight Code", flight.flightCode),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildTicketField("Boarding Time", flight.boardingTime),
                                _buildTicketField("Gate", flight.gate),
                                _buildTicketField("Terminal", flight.terminal),
                                _buildTicketField("Seat Number", flight.seatNumber),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.center,
                              child: Text('Flight date: ${flight.flightDate}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF37849D))),
                            ),
                            const Divider(height: 24),
                            Container(
                              height: 50,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(24, (index) {
                                  final double width = (index % 3 == 0) ? 4.0 : (index % 2 == 0) ? 2.5 : 1.5;
                                  final double space = (index % 4 == 0) ? 3.0 : 1.5;
                                  return Row(
                                    children: [
                                      Container(width: width, height: double.infinity, color: Colors.black),
                                      SizedBox(width: space),
                                    ],
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('1 2 3 4 5 6 7 8 9 10 11 22 33 4 55 6 77 8', style: TextStyle(fontSize: 9, color: Colors.grey.shade400, letterSpacing: 1.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF37849D),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTicketField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Flights'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF37849D)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _flights.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.flight_takeoff_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              const Text('No flights added yet', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16)),
                              const SizedBox(height: 8),
                              const Text('Tap the button below to add your flight details.', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _flights.length,
                          itemBuilder: (context, index) {
                            final flight = _flights[index];
                            final passengers = flight.passengerNames.split(', ');

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade100),
                                boxShadow: [
                                  BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(flight.departureTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                              const SizedBox(width: 8),
                                              const Text('to', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                              const SizedBox(width: 8),
                                              Text(flight.arrivalTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text('${flight.departureAirport}       ${flight.arrivalAirport}', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 11)),
                                        ],
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF37849D), size: 22),
                                        onPressed: () => _showManualAddDialog(editFlight: flight),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Confirmation No.', style: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 2),
                                          Text(flight.confirmationNo, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ],
                                      ),
                                      if (flight.price > 0)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('Cost', style: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 2),
                                            Text('\$${flight.price.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      InkWell(
                                        onTap: () => _showBoardingPass(flight),
                                        child: const Text(
                                          'See tickets',
                                          style: TextStyle(color: Color(0xFF37849D), fontWeight: FontWeight.bold, fontSize: 12, decoration: TextDecoration.underline),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(
                                            height: 24,
                                            child: Row(
                                              children: List.generate(passengers.length, (i) {
                                                final trav = _travelers.firstWhere((t) => t['name'] == passengers[i], orElse: () => _travelers[0]);
                                                return Align(
                                                  widthFactor: 0.65,
                                                  child: Container(
                                                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                                                    child: CircleAvatar(radius: 10, backgroundImage: NetworkImage(trav['avatar']!)),
                                                  ),
                                                );
                                              }),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF37849D),
                      side: const BorderSide(color: Color(0xFF37849D), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _showAddFlightOptions,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 20),
                        SizedBox(width: 8),
                        Text('Add flight', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
