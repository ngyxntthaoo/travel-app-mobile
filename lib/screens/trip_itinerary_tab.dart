import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/accommodation.dart';
import '../models/flight.dart';
import '../models/itinerary_place.dart';
import '../models/trip.dart';
import '../theme/app_colors.dart';
import 'map_picker_screen.dart';
import 'trip_route_map_screen.dart';
import 'trip_accoms_screen.dart';
import 'trip_flights_screen.dart';

// ─────────────────────────────────────────────
// Category helpers — mirrors Bills screen exactly
// ─────────────────────────────────────────────

IconData _kindIcon(PlaceKind k) {
  switch (k) {
    case PlaceKind.food:      return Icons.fastfood_outlined;
    case PlaceKind.flights:   return Icons.flight_takeoff_rounded;
    case PlaceKind.accomms:   return Icons.hotel_outlined;
    case PlaceKind.transport: return Icons.directions_bus_outlined;
    case PlaceKind.sights:    return Icons.photo_camera_outlined;
    case PlaceKind.shopping:  return Icons.shopping_bag_outlined;
    case PlaceKind.others:    return Icons.more_horiz_outlined;
  }
}

Color _kindColor(PlaceKind k) {
  switch (k) {
    case PlaceKind.food:      return Colors.orange;
    case PlaceKind.flights:   return Colors.indigo;
    case PlaceKind.accomms:   return Colors.purple;
    case PlaceKind.transport: return Colors.blue;
    case PlaceKind.sights:    return Colors.green;
    case PlaceKind.shopping:  return Colors.pink;
    case PlaceKind.others:    return Colors.grey;
  }
}

String _kindLabel(PlaceKind k) {
  switch (k) {
    case PlaceKind.food:      return 'Food';
    case PlaceKind.flights:   return 'Flights';
    case PlaceKind.accomms:   return 'Accomms';
    case PlaceKind.transport: return 'Transport';
    case PlaceKind.sights:    return 'Sights';
    case PlaceKind.shopping:  return 'Shopping';
    case PlaceKind.others:    return 'Others';
  }
}

// ─────────────────────────────────────────────
// Internal merged entry for a single day slot
// ─────────────────────────────────────────────

enum _EntryKind { flight, checkIn, checkOut, food, flights, accomms, transport, sights, shopping, others }

class _DayEntry {
  final _EntryKind kind;
  final String title;
  final String? startTime;
  final String? endTime;
  final String? location;
  final String? badge;
  final String? categoryLabel; // shown as chip on user-added places
  final double cost;
  final int? placeId; // non-null → user-added, can delete/edit
  final ItineraryPlace? placeData; // full data for edit sheet
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const _DayEntry({
    required this.kind,
    required this.title,
    this.startTime,
    this.endTime,
    this.location,
    this.badge,
    this.categoryLabel,
    this.cost = 0.0,
    this.placeId,
    this.placeData,
    this.onTap,
    this.onEdit,
  });
}

Color _entryColor(_EntryKind k) {
  switch (k) {
    case _EntryKind.flight:    return Colors.indigo;
    case _EntryKind.checkIn:   return Colors.green;
    case _EntryKind.checkOut:  return const Color(0xFF00897B);
    case _EntryKind.food:      return Colors.orange;
    case _EntryKind.flights:   return Colors.indigo;
    case _EntryKind.accomms:   return Colors.purple;
    case _EntryKind.transport: return Colors.blue;
    case _EntryKind.sights:    return Colors.green;
    case _EntryKind.shopping:  return Colors.pink;
    case _EntryKind.others:    return Colors.grey;
  }
}

IconData _entryIcon(_EntryKind k) {
  switch (k) {
    case _EntryKind.flight:    return Icons.flight_takeoff_rounded;
    case _EntryKind.checkIn:   return Icons.login_rounded;
    case _EntryKind.checkOut:  return Icons.logout_rounded;
    case _EntryKind.food:      return Icons.fastfood_outlined;
    case _EntryKind.flights:   return Icons.flight_takeoff_rounded;
    case _EntryKind.accomms:   return Icons.hotel_outlined;
    case _EntryKind.transport: return Icons.directions_bus_outlined;
    case _EntryKind.sights:    return Icons.photo_camera_outlined;
    case _EntryKind.shopping:  return Icons.shopping_bag_outlined;
    case _EntryKind.others:    return Icons.more_horiz_outlined;
  }
}

_EntryKind _entryKindFrom(PlaceKind pk) {
  switch (pk) {
    case PlaceKind.food:      return _EntryKind.food;
    case PlaceKind.flights:   return _EntryKind.flights;
    case PlaceKind.accomms:   return _EntryKind.accomms;
    case PlaceKind.transport: return _EntryKind.transport;
    case PlaceKind.sights:    return _EntryKind.sights;
    case PlaceKind.shopping:  return _EntryKind.shopping;
    case PlaceKind.others:    return _EntryKind.others;
  }
}

String _formatCost(double cost) {
  if (cost >= 1000000) {
    return '\$${(cost / 1000000).toStringAsFixed(cost % 1000000 == 0 ? 0 : 1)}M';
  }
  if (cost >= 1000) {
    return '\$${(cost / 1000).toStringAsFixed(cost % 1000 == 0 ? 0 : 1)}k';
  }
  return '\$${cost.toStringAsFixed(cost == cost.toInt() ? 0 : 2)}';
}

// ─────────────────────────────────────────────
// Main widget
// ─────────────────────────────────────────────

class TripItineraryTab extends StatefulWidget {
  final Trip trip;
  final bool readOnly;
  const TripItineraryTab({super.key, required this.trip, this.readOnly = false});

  @override
  State<TripItineraryTab> createState() => _TripItineraryTabState();
}

class _TripItineraryTabState extends State<TripItineraryTab> {
  late final List<DateTime> _days;
  final Map<String, GlobalKey<_DaySectionState>> _dayKeys = {};
  int _selectedDayIndex = 0;
  final ScrollController _listScroll = ScrollController();
  final ScrollController _chipScroll = ScrollController();

  List<Flight> _flights = [];
  List<Accommodation> _accoms = [];
  List<ItineraryPlace> _places = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _days = _buildDayList();
    for (final d in _days) {
      _dayKeys[_isoDate(d)] = GlobalKey<_DaySectionState>();
    }
    _loadData();
  }

  @override
  void dispose() {
    _listScroll.dispose();
    _chipScroll.dispose();
    super.dispose();
  }

  List<DateTime> _buildDayList() {
    final days = <DateTime>[];
    var cur = widget.trip.startDate;
    while (!cur.isAfter(widget.trip.endDate)) {
      days.add(cur);
      cur = cur.add(const Duration(days: 1));
    }
    return days;
  }

  String _isoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _loadData() async {
    final tripId = widget.trip.id!;
    final results = await Future.wait([
      DbHelper.instance.readFlightsForTrip(tripId),
      DbHelper.instance.readAccommodationsForTrip(tripId),
      DbHelper.instance.readItineraryPlacesForTrip(tripId),
    ]);
    if (!mounted) return;
    setState(() {
      _flights = results[0] as List<Flight>;
      _accoms = results[1] as List<Accommodation>;
      _places = results[2] as List<ItineraryPlace>;
      _loading = false;
    });
  }

  List<_DayEntry> _entriesForDay(DateTime day) {
    final iso = _isoDate(day);
    final entries = <_DayEntry>[];

    for (final f in _flights) {
      if (_normalizeDate(f.flightDate) == iso) {
        final label = f.airlineName.isNotEmpty ? '${f.airlineName} · ${f.flightCode}' : f.flightCode;
        entries.add(_DayEntry(
          kind: _EntryKind.flight,
          title: label,
          startTime: f.departureTime,
          endTime: f.arrivalTime,
          location: f.departureAirport,
          badge: '${f.departureAirport} → ${f.arrivalAirport}',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TripFlightsScreen(trip: widget.trip)),
          ).then((_) => _loadData()),
        ));
      }
    }

    for (final a in _accoms) {
      if (_normalizeDate(a.checkIn) == iso) {
        entries.add(_DayEntry(
          kind: _EntryKind.checkIn,
          title: 'Check in · ${a.hotelName}',
          startTime: '14:00',
          badge: 'Check-in',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TripAccomsScreen(trip: widget.trip)),
          ).then((_) => _loadData()),
        ));
      }
      if (_normalizeDate(a.checkOut) == iso) {
        entries.add(_DayEntry(
          kind: _EntryKind.checkOut,
          title: 'Check out · ${a.hotelName}',
          startTime: '11:00',
          badge: 'Check-out',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TripAccomsScreen(trip: widget.trip)),
          ).then((_) => _loadData()),
        ));
      }
    }

    for (final p in _places) {
      if (p.date == iso) {
        entries.add(_DayEntry(
          kind: _entryKindFrom(p.kind),
          title: p.title,
          startTime: p.startTime.isEmpty ? null : p.startTime,
          endTime: p.endTime.isEmpty ? null : p.endTime,
          location: p.location.isEmpty ? null : p.location,
          categoryLabel: _kindLabel(p.kind),
          cost: p.cost,
          placeId: p.id,
          placeData: p,
          onEdit: widget.readOnly ? null : () => _showEditPlaceSheet(p),
        ));
      }
    }

    entries.sort((a, b) {
      if (a.startTime == null && b.startTime == null) return 0;
      if (a.startTime == null) return 1;
      if (b.startTime == null) return -1;
      return a.startTime!.compareTo(b.startTime!);
    });

    return entries;
  }

  String _normalizeDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt != null) {
      return DateFormat('yyyy-MM-dd').format(dt);
    }
    try {
      return DateFormat('yyyy-MM-dd').format(DateFormat('dd MMM yyyy').parse(raw));
    } catch (_) {}
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }

  void _scrollToDay(int index) {
    setState(() => _selectedDayIndex = index);
    final key = _dayKeys[_isoDate(_days[index])];
    key?.currentState?.expand();
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  Future<void> _showAddPlaceSheet(DateTime day) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPlaceSheet(trip: widget.trip, date: day, onSaved: _loadData),
    );
  }

  Future<void> _showEditPlaceSheet(ItineraryPlace place) async {
    final day = DateTime.tryParse(place.date) ?? widget.trip.startDate;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPlaceSheet(
        trip: widget.trip,
        date: day,
        onSaved: _loadData,
        editPlace: place,
      ),
    );
  }

  Future<void> _deletePlace(int placeId) async {
    await DbHelper.instance.deleteItineraryPlace(placeId);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.teal));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.readOnly)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TripRouteMapScreen(
                        trip: widget.trip,
                        onRouteUpdated: _loadData,
                      ),
                    ),
                  ).then((_) => _loadData());
                },
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('View route map'),
                style: TextButton.styleFrom(foregroundColor: AppColors.teal),
              ),
            ),
          ),
        _DaySelectorBar(
          days: _days,
          selectedIndex: _selectedDayIndex,
          scrollController: _chipScroll,
          onDaySelected: _scrollToDay,
        ),
        Expanded(
          child: ListView.builder(
            controller: _listScroll,
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            itemCount: _days.length,
            itemBuilder: (context, i) => _DaySection(
              key: _dayKeys[_isoDate(_days[i])],
              day: _days[i],
              dayIndex: i,
              initialExpanded: i == 0,
              entries: _entriesForDay(_days[i]),
              readOnly: widget.readOnly,
              onAddPlace: () => _showAddPlaceSheet(_days[i]),
              onDeletePlace: _deletePlace,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Day selector chip bar
// ─────────────────────────────────────────────

class _DaySelectorBar extends StatelessWidget {
  final List<DateTime> days;
  final int selectedIndex;
  final ScrollController scrollController;
  final ValueChanged<int> onDaySelected;

  const _DaySelectorBar({
    required this.days,
    required this.selectedIndex,
    required this.scrollController,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(days.length, (i) {
            final selected = i == selectedIndex;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onDaySelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.teal : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DateFormat('EEE d/M').format(days[i]),
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Collapsible day section
// ─────────────────────────────────────────────

class _DaySection extends StatefulWidget {
  final DateTime day;
  final int dayIndex;
  final bool initialExpanded;
  final List<_DayEntry> entries;
  final bool readOnly;
  final VoidCallback onAddPlace;
  final ValueChanged<int> onDeletePlace;

  const _DaySection({
    super.key,
    required this.day,
    required this.dayIndex,
    required this.initialExpanded,
    required this.entries,
    this.readOnly = false,
    required this.onAddPlace,
    required this.onDeletePlace,
  });

  @override
  State<_DaySection> createState() => _DaySectionState();
}

class _DaySectionState extends State<_DaySection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initialExpanded;
  }

  void expand() {
    if (!_expanded) setState(() => _expanded = true);
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _toggle,
            child: _DayHeader(
              day: widget.day,
              dayIndex: widget.dayIndex,
              entryCount: widget.entries.length,
              isExpanded: _expanded,
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expanded ? _buildBody() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vertical track line
            Container(
              width: 2,
              margin: const EdgeInsets.only(top: 6, bottom: 6),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.25),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 10),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  if (widget.entries.isNotEmpty)
                    _Timeline(entries: widget.entries, onDeletePlace: widget.onDeletePlace),
                  if (!widget.readOnly) ...[
                    const SizedBox(height: 4),
                    _AddPlaceButton(onTap: widget.onAddPlace),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Day header with chevron
// ─────────────────────────────────────────────

class _DayHeader extends StatelessWidget {
  final DateTime day;
  final int dayIndex;
  final int entryCount;
  final bool isExpanded;

  const _DayHeader({
    required this.day,
    required this.dayIndex,
    required this.entryCount,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Text(
            DateFormat('EEE, d MMM').format(day),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
          ),
          const Spacer(),
          AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 220),
            child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400, size: 20),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty placeholder
// ─────────────────────────────────────────────

class _EmptyDayPlaceholder extends StatelessWidget {
  final VoidCallback onAddPlace;
  const _EmptyDayPlaceholder({required this.onAddPlace});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: onAddPlace,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.add_location_alt_outlined, color: Colors.grey.shade300, size: 28),
              const SizedBox(height: 6),
              Text(
                'Add a place for this day',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Add place button
// ─────────────────────────────────────────────

class _AddPlaceButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPlaceButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(Icons.add_circle_outline, size: 16, color: AppColors.teal),
            const SizedBox(width: 6),
            const Text(
              'Add a place',
              style: TextStyle(fontSize: 13, color: AppColors.teal, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Timeline
// ─────────────────────────────────────────────

class _Timeline extends StatelessWidget {
  final List<_DayEntry> entries;
  final ValueChanged<int> onDeletePlace;

  const _Timeline({required this.entries, required this.onDeletePlace});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(entries.length, (i) => _TimelineRow(
        entry: entries[i],
        isLast: i == entries.length - 1,
        onDelete: entries[i].placeId != null ? () => onDeletePlace(entries[i].placeId!) : null,
      )),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final _DayEntry entry;
  final bool isLast;
  final VoidCallback? onDelete;

  const _TimelineRow({required this.entry, required this.isLast, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = _entryColor(entry.kind);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: _EntryCard(entry: entry, color: color, onDelete: onDelete),
    );
  }
}

// ─────────────────────────────────────────────
// Entry card
// ─────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  final _DayEntry entry;
  final Color color;
  final VoidCallback? onDelete;

  const _EntryCard({required this.entry, required this.color, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: entry.onEdit ?? entry.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 3)),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    if (entry.badge != null) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(entry.badge!, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
                      ),
                    ] else ...[
                      if (entry.categoryLabel != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_entryIcon(entry.kind), size: 10, color: color),
                              const SizedBox(width: 3),
                              Text(entry.categoryLabel!, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                      if (entry.location != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.place_outlined, size: 11, color: Colors.grey.shade400),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                entry.location!,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (entry.startTime != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.startTime!,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                        ),
                        if (entry.endTime != null) ...[
                          Text(' – ', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                          Text(
                            entry.endTime!,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ],
                    ),
                  if (entry.cost > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatCost(entry.cost),
                      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700),
                    ),
                  ],
                  if (entry.onEdit != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: entry.onEdit,
                          child: Icon(Icons.edit_outlined, size: 16, color: Colors.grey.shade400),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onDelete,
                          child: Icon(Icons.delete_outline, size: 16, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ] else if (entry.onTap != null) ...[
                    const SizedBox(height: 4),
                    Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey.shade300),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Add Place bottom sheet
// ─────────────────────────────────────────────

class _AddPlaceSheet extends StatefulWidget {
  final Trip trip;
  final DateTime date;
  final VoidCallback onSaved;
  final ItineraryPlace? editPlace; // non-null → edit mode

  const _AddPlaceSheet({
    required this.trip,
    required this.date,
    required this.onSaved,
    this.editPlace,
  });

  @override
  State<_AddPlaceSheet> createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends State<_AddPlaceSheet> {
  final _titleCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  PlaceKind _kind = PlaceKind.sights;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _saving = false;
  bool _deleting = false;

  String _locationName = '';
  String _locationAddress = '';
  double? _lat;
  double? _lng;

  bool get _isEdit => widget.editPlace != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editPlace;
    if (e != null) {
      _titleCtrl.text = e.title;
      _kind = e.kind;
      _locationName = e.location;
      _lat = e.lat;
      _lng = e.lng;
      if (e.cost > 0) _costCtrl.text = e.cost.toStringAsFixed(0);
      if (e.startTime.isNotEmpty) {
        final p = e.startTime.split(':');
        _startTime = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      }
      if (e.endTime.isNotEmpty) {
        final p = e.endTime.split(':');
        _endTime = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    FocusScope.of(context).unfocus();
    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(destination: widget.trip.mainDestination),
      ),
    );
    if (result == null) return;
    setState(() {
      _locationName = result.name;
      _locationAddress = result.address;
      _lat = result.lat;
      _lng = result.lng;
      if (_titleCtrl.text.trim().isEmpty) {
        _titleCtrl.text = result.name;
      }
    });
  }

  String _formatTod(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
          : (_endTime ?? const TimeOfDay(hour: 10, minute: 0)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.teal)),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    final cost = double.tryParse(_costCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final place = ItineraryPlace(
      id: widget.editPlace?.id,
      tripId: widget.trip.id!,
      date: DateFormat('yyyy-MM-dd').format(widget.date),
      title: title,
      startTime: _startTime != null ? _formatTod(_startTime!) : '',
      endTime: _endTime != null ? _formatTod(_endTime!) : '',
      location: _locationName.isNotEmpty ? _locationName : _locationAddress,
      kind: _kind,
      lat: _lat,
      lng: _lng,
      cost: cost,
    );
    if (_isEdit) {
      await DbHelper.instance.updateItineraryPlace(place);
    } else {
      await DbHelper.instance.createItineraryPlace(place);
    }
    if (!mounted) return;
    Navigator.pop(context);
    widget.onSaved();
  }

  Future<void> _delete() async {
    setState(() => _deleting = true);
    await DbHelper.instance.deleteItineraryPlace(widget.editPlace!.id!);
    if (!mounted) return;
    Navigator.pop(context);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                _isEdit ? 'Edit place' : 'Add a place',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Text(DateFormat('EEE, d MMM').format(widget.date), style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 16),
          // Category chips — same as Bills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PlaceKind.values.map((k) {
                final selected = k == _kind;
                final c = _kindColor(k);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _kind = k),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? c.withOpacity(0.12) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: selected ? c : Colors.transparent),
                      ),
                      child: Row(
                        children: [
                          Icon(_kindIcon(k), size: 13, color: selected ? c : Colors.grey.shade500),
                          const SizedBox(width: 5),
                          Text(
                            _kindLabel(k),
                            style: TextStyle(
                              fontSize: 12,
                              color: selected ? c : Colors.grey.shade600,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Place name',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickLocation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.place_outlined, size: 18, color: _locationName.isNotEmpty ? AppColors.teal : Colors.grey.shade400),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _locationName.isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_locationName, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                              if (_locationAddress.isNotEmpty)
                                Text(_locationAddress, style: TextStyle(fontSize: 11, color: Colors.grey.shade400), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          )
                        : Text('Pick on map', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                  ),
                  Icon(Icons.map_outlined, size: 16, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(true),
                  child: _TimeField(label: 'Start time', value: _startTime != null ? _formatTod(_startTime!) : null),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(false),
                  child: _TimeField(label: 'End time', value: _endTime != null ? _formatTod(_endTime!) : null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _costCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Cost (optional)',
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Text('đ', style: TextStyle(fontSize: 15, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixText: _costCtrl.text.isNotEmpty ? _kindLabel(_kind) : null,
              suffixStyle: TextStyle(fontSize: 12, color: _kindColor(_kind), fontWeight: FontWeight.w500),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: _saving || _deleting ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
          if (_isEdit) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: TextButton(
                onPressed: _saving || _deleting ? null : _delete,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade400,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _deleting
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.red.shade300, strokeWidth: 2))
                    : const Text('Delete place', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final String? value;
  const _TimeField({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(Icons.access_time_outlined, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Text(
            value ?? label,
            style: TextStyle(fontSize: 13, color: value != null ? AppColors.textPrimary : Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
