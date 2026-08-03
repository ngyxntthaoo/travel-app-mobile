enum ItineraryItemType { flight, transport, accommodation, activity }

class ItineraryItem {
  final String title;
  final DateTime date;
  final String? startTime;
  final String? endTime;
  final String? location;
  final ItineraryItemType type;
  final String? fromCode;
  final String? toCode;
  final String? imageUrl;
  final List<String> tags;
  final double? rating;
  final bool requiresBooking;

  const ItineraryItem({
    required this.title,
    required this.date,
    required this.type,
    this.startTime,
    this.endTime,
    this.location,
    this.fromCode,
    this.toCode,
    this.imageUrl,
    this.tags = const [],
    this.rating,
    this.requiresBooking = false,
  });
}
