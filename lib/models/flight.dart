class Flight {
  final int? id;
  final int tripId;
  final String flightCode;
  final String departureAirport;
  final String arrivalAirport;
  final String departureTime;
  final String arrivalTime;
  final String flightDate;
  final String confirmationNo;
  final String boardingTime;
  final String gate;
  final String terminal;
  final String seatNumber;
  final String passengerNames; // Comma-separated passenger names
  final String airlineName;
  final double price;

  Flight({
    this.id,
    required this.tripId,
    required this.flightCode,
    required this.departureAirport,
    required this.arrivalAirport,
    required this.departureTime,
    required this.arrivalTime,
    required this.flightDate,
    required this.confirmationNo,
    required this.boardingTime,
    required this.gate,
    required this.terminal,
    required this.seatNumber,
    required this.passengerNames,
    required this.airlineName,
    this.price = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'flight_code': flightCode,
      'departure_airport': departureAirport,
      'arrival_airport': arrivalAirport,
      'departure_time': departureTime,
      'arrival_time': arrivalTime,
      'flight_date': flightDate,
      'confirmation_no': confirmationNo,
      'boarding_time': boardingTime,
      'gate': gate,
      'terminal': terminal,
      'seat_number': seatNumber,
      'passenger_names': passengerNames,
      'airline_name': airlineName,
      'price': price,
    };
  }

  factory Flight.fromMap(Map<String, dynamic> map) {
    return Flight(
      id: map['id'] as int?,
      tripId: map['trip_id'] as int,
      flightCode: map['flight_code'] as String,
      departureAirport: map['departure_airport'] as String,
      arrivalAirport: map['arrival_airport'] as String,
      departureTime: map['departure_time'] as String,
      arrivalTime: map['arrival_time'] as String,
      flightDate: map['flight_date'] as String,
      confirmationNo: map['confirmation_no'] as String,
      boardingTime: map['boarding_time'] as String,
      gate: map['gate'] as String,
      terminal: map['terminal'] as String,
      seatNumber: map['seat_number'] as String,
      passengerNames: map['passenger_names'] as String,
      airlineName: map['airline_name'] as String,
      price: map['price'] != null ? (map['price'] as num).toDouble() : 0.0,
    );
  }

  Flight copyWith({
    int? id,
    int? tripId,
    String? flightCode,
    String? departureAirport,
    String? arrivalAirport,
    String? departureTime,
    String? arrivalTime,
    String? flightDate,
    String? confirmationNo,
    String? boardingTime,
    String? gate,
    String? terminal,
    String? seatNumber,
    String? passengerNames,
    String? airlineName,
    double? price,
  }) {
    return Flight(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      flightCode: flightCode ?? this.flightCode,
      departureAirport: departureAirport ?? this.departureAirport,
      arrivalAirport: arrivalAirport ?? this.arrivalAirport,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      flightDate: flightDate ?? this.flightDate,
      confirmationNo: confirmationNo ?? this.confirmationNo,
      boardingTime: boardingTime ?? this.boardingTime,
      gate: gate ?? this.gate,
      terminal: terminal ?? this.terminal,
      seatNumber: seatNumber ?? this.seatNumber,
      passengerNames: passengerNames ?? this.passengerNames,
      airlineName: airlineName ?? this.airlineName,
      price: price ?? this.price,
    );
  }
}
