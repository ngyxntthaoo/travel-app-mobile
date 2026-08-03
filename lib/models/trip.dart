class Trip {
  final int? id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String mainDestination;
  final bool isPublic;
  final String? shareToken;
  final double? destinationLat;
  final double? destinationLng;

  Trip({
    this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.mainDestination,
    this.isPublic = false,
    this.shareToken,
    this.destinationLat,
    this.destinationLng,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'main_destination': mainDestination,
      'is_public': isPublic ? 1 : 0,
      'share_token': shareToken,
      'destination_lat': destinationLat,
      'destination_lng': destinationLng,
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as int?,
      title: map['title'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      mainDestination: map['main_destination'] as String,
      isPublic: (map['is_public'] as int? ?? 0) == 1,
      shareToken: map['share_token'] as String?,
      destinationLat: map['destination_lat'] != null
          ? (map['destination_lat'] as num).toDouble()
          : null,
      destinationLng: map['destination_lng'] != null
          ? (map['destination_lng'] as num).toDouble()
          : null,
    );
  }

  Trip copyWith({
    int? id,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    String? mainDestination,
    bool? isPublic,
    String? shareToken,
    double? destinationLat,
    double? destinationLng,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      mainDestination: mainDestination ?? this.mainDestination,
      isPublic: isPublic ?? this.isPublic,
      shareToken: shareToken ?? this.shareToken,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
    );
  }

  String get shareLink => shareToken != null ? 'tripplanner://share/$shareToken' : '';
}
