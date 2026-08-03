enum PlaceKind { food, flights, accomms, transport, sights, shopping, others }

class ItineraryPlace {
  final int? id;
  final int tripId;
  final String date; // "YYYY-MM-DD"
  final String title;
  final String startTime; // "HH:MM" or ""
  final String endTime; // "HH:MM" or ""
  final String location;
  final PlaceKind kind;
  final int sortOrder;
  final double? lat;
  final double? lng;
  final double cost;

  const ItineraryPlace({
    this.id,
    required this.tripId,
    required this.date,
    required this.title,
    this.startTime = '',
    this.endTime = '',
    this.location = '',
    this.kind = PlaceKind.sights,
    this.sortOrder = 0,
    this.lat,
    this.lng,
    this.cost = 0.0,
  });

  /// Maps PlaceKind to the expense category string used in the Bills screen.
  String get expenseCategory {
    switch (kind) {
      case PlaceKind.food:      return 'Food';
      case PlaceKind.flights:   return 'Flights';
      case PlaceKind.accomms:   return 'Accomms';
      case PlaceKind.transport: return 'Transport';
      case PlaceKind.sights:    return 'Sights';
      case PlaceKind.shopping:  return 'Shopping';
      case PlaceKind.others:    return 'Others';
    }
  }

  String get expenseTitle => 'Place: $title';

  Map<String, dynamic> toMap() => {
    'id': id,
    'trip_id': tripId,
    'date': date,
    'title': title,
    'start_time': startTime,
    'end_time': endTime,
    'location': location,
    'kind': kind.name,
    'sort_order': sortOrder,
    'lat': lat,
    'lng': lng,
    'cost': cost,
  };

  factory ItineraryPlace.fromMap(Map<String, dynamic> map) => ItineraryPlace(
    id: map['id'] as int?,
    tripId: map['trip_id'] as int,
    date: map['date'] as String,
    title: map['title'] as String,
    startTime: map['start_time'] as String? ?? '',
    endTime: map['end_time'] as String? ?? '',
    location: map['location'] as String? ?? '',
    kind: PlaceKind.values.firstWhere(
      (k) => k.name == map['kind'],
      orElse: () => PlaceKind.sights,
    ),
    sortOrder: map['sort_order'] as int? ?? 0,
    lat: map['lat'] != null ? (map['lat'] as num).toDouble() : null,
    lng: map['lng'] != null ? (map['lng'] as num).toDouble() : null,
    cost: map['cost'] != null ? (map['cost'] as num).toDouble() : 0.0,
  );

  ItineraryPlace copyWith({int? id}) => ItineraryPlace(
    id: id ?? this.id,
    tripId: tripId,
    date: date,
    title: title,
    startTime: startTime,
    endTime: endTime,
    location: location,
    kind: kind,
    sortOrder: sortOrder,
    lat: lat,
    lng: lng,
    cost: cost,
  );
}
