class Accommodation {
  final int? id;
  final int tripId;
  final String hotelName;
  final String checkIn;
  final String checkOut;
  final String confirmationNo;
  final String? localFilePath;
  final double price;
  final double? lat;
  final double? lng;
  final String address;

  Accommodation({
    this.id,
    required this.tripId,
    required this.hotelName,
    required this.checkIn,
    required this.checkOut,
    required this.confirmationNo,
    this.localFilePath,
    this.price = 0.0,
    this.lat,
    this.lng,
    this.address = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'hotel_name': hotelName,
      'check_in': checkIn,
      'check_out': checkOut,
      'confirmation_no': confirmationNo,
      'local_file_path': localFilePath,
      'price': price,
      'lat': lat,
      'lng': lng,
      'address': address,
    };
  }

  factory Accommodation.fromMap(Map<String, dynamic> map) {
    return Accommodation(
      id: map['id'] as int?,
      tripId: map['trip_id'] as int,
      hotelName: map['hotel_name'] as String,
      checkIn: map['check_in'] as String,
      checkOut: map['check_out'] as String,
      confirmationNo: map['confirmation_no'] as String,
      localFilePath: map['local_file_path'] as String?,
      price: map['price'] != null ? (map['price'] as num).toDouble() : 0.0,
      lat: map['lat'] != null ? (map['lat'] as num).toDouble() : null,
      lng: map['lng'] != null ? (map['lng'] as num).toDouble() : null,
      address: map['address'] as String? ?? '',
    );
  }

  Accommodation copyWith({
    int? id,
    int? tripId,
    String? hotelName,
    String? checkIn,
    String? checkOut,
    String? confirmationNo,
    String? localFilePath,
    double? price,
    double? lat,
    double? lng,
    String? address,
  }) {
    return Accommodation(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      hotelName: hotelName ?? this.hotelName,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      confirmationNo: confirmationNo ?? this.confirmationNo,
      localFilePath: localFilePath ?? this.localFilePath,
      price: price ?? this.price,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
    );
  }
}
