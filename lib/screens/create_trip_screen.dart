import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/trip.dart';
import '../theme/app_colors.dart';
import 'map_picker_screen.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _titleController = TextEditingController();
  final List<String> _availableDestinations = [
    'Bali, Indonesia',
    'Singapore, Singapore',
    'London, United Kingdom',
    'Tokyo, Japan',
    'Paris, France',
    'Sydney, Australia',
    'Rome, Italy',
    'New York, United States',
    'Bangkok, Thailand',
  ];
  final List<String> _selectedDestinations = [];
  DateTime? _startDate;
  DateTime? _endDate;
  final List<String> _partners = [];
  double? _destinationLat;
  double? _destinationLng;
  String _customDestination = '';

  Future<void> _pickDestinationOnMap() async {
    final seed = _selectedDestinations.isNotEmpty
        ? _selectedDestinations.first
        : (_customDestination.isNotEmpty ? _customDestination : 'Singapore');
    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(builder: (_) => MapPickerScreen(destination: seed)),
    );
    if (result == null) return;
    setState(() {
      _customDestination = result.address.isNotEmpty ? result.address : result.name;
      _destinationLat = result.lat;
      _destinationLng = result.lng;
      if (!_selectedDestinations.contains(_customDestination)) {
        _selectedDestinations
          ..clear()
          ..add(_customDestination);
      }
    });
  }

  void _showDestinationSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Select Destination(s)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _availableDestinations.length,
                      itemBuilder: (context, index) {
                        final destination = _availableDestinations[index];
                        final isSelected = _selectedDestinations.contains(destination);
                        return CheckboxListTile(
                          value: isSelected,
                          activeColor: const Color(0xFF37849D),
                          title: Text(
                            destination,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          onChanged: (bool? checked) {
                            setModalState(() {
                              if (checked == true) {
                                _selectedDestinations.add(destination);
                              } else {
                                _selectedDestinations.remove(destination);
                              }
                            });
                            setState(() {}); // Update parent widget to show chips
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF37849D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Done',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final initialRange = _startDate != null && _endDate != null
        ? DateTimeRange(start: _startDate!, end: _endDate!)
        : DateTimeRange(
            start: DateTime.now(),
            end: DateTime.now().add(const Duration(days: 3)),
          );

    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.teal,
                  onPrimary: Colors.white,
                  secondary: AppColors.navyDark,
                ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        _startDate = pickedRange.start;
        _endDate = pickedRange.end;
      });
    }
  }

  void _addPartner() {
    final names = ['Gina', 'Alex', 'Caleb', 'Emma', 'Ryan', 'Zoe'];
    final unusedNames = names.where((name) => !_partners.contains(name)).toList();
    if (unusedNames.isNotEmpty) {
      setState(() {
        _partners.add(unusedNames.first);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All mockup travel partners added!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create New Trip',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Trip name', style: labelStyle),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'E.g. Europe Trip 2023',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Destination(s)', style: labelStyle),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _showDestinationSelector,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedDestinations.isNotEmpty
                              ? AppColors.teal
                              : Colors.grey.shade200,
                          width: _selectedDestinations.isNotEmpty ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _selectedDestinations.isEmpty
                                ? Text(
                                    'Select city - country...',
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                                  )
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: _selectedDestinations.map((dest) {
                                      return Chip(
                                        label: Text(
                                          dest,
                                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                                        ),
                                        backgroundColor: Colors.grey.shade100,
                                        side: BorderSide(color: Colors.grey.shade200),
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        onDeleted: () {
                                          setState(() {
                                            _selectedDestinations.remove(dest);
                                            _destinationLat = null;
                                            _destinationLng = null;
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey.shade500,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _pickDestinationOnMap,
                  icon: const Icon(Icons.map_rounded, color: AppColors.teal, size: 28),
                  tooltip: 'Pick on map',
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Dates', style: labelStyle),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDateRange(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey.shade500),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _startDate == null
                                  ? 'Start Date'
                                  : DateFormat('dd MMM').format(_startDate!),
                              style: TextStyle(
                                color: _startDate == null ? Colors.grey.shade400 : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDateRange(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey.shade500),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _endDate == null
                                  ? 'End Date'
                                  : DateFormat('dd MMM').format(_endDate!),
                              style: TextStyle(
                                color: _endDate == null ? Colors.grey.shade400 : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addPartner,
                icon: const Icon(Icons.add, size: 18, color: Color(0xFF37849D)),
                label: const Text(
                  'Add Travel Partners',
                  style: TextStyle(
                    color: Color(0xFF37849D),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_partners.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _partners.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(_partners[index]),
                        avatar: const CircleAvatar(
                          child: Icon(Icons.person, size: 12),
                        ),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade200),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        labelStyle: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Locations, dates and travel partners can be added or edited in your trip plan later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 36),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF37849D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                final title = _titleController.text.trim();
                final destination = _selectedDestinations.join(', ');

                if (title.isEmpty || destination.isEmpty || _startDate == null || _endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill out all fields and select dates.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                final newTrip = Trip(
                  title: title,
                  mainDestination: destination,
                  startDate: _startDate!,
                  endDate: _endDate!,
                  destinationLat: _destinationLat,
                  destinationLng: _destinationLng,
                );

                await DbHelper.instance.createTrip(newTrip);
                if (mounted) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text(
                'Create Trip',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
