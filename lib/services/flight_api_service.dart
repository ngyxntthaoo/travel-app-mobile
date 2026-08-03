import 'dart:convert';
import 'package:intl/intl.dart';

class FlightSearchCriteria {
  final String origin;
  final String destination;
  final DateTime date;

  const FlightSearchCriteria({
    required this.origin,
    required this.destination,
    required this.date,
  });
}

class FlightApiService {
  static final FlightApiService instance = FlightApiService._init();
  FlightApiService._init();

  static const _catalog = [
    {
      'flight_code': 'SQ 278',
      'airline_name': 'Singapore Airlines',
      'departure_airport': 'SIN',
      'arrival_airport': 'DPS',
      'departure_time': '08:30',
      'arrival_time': '11:15',
      'flight_date': '2026-06-16',
      'confirmation_no': 'AVL-7821',
      'boarding_time': '07:45 am',
      'gate': 'A12',
      'terminal': '3',
      'seat_number': 'Available',
      'price': 285.0,
    },
    {
      'flight_code': 'SQ 948',
      'airline_name': 'Singapore Airlines',
      'departure_airport': 'SIN',
      'arrival_airport': 'DPS',
      'departure_time': '18:10',
      'arrival_time': '20:55',
      'flight_date': '2026-06-16',
      'confirmation_no': 'AVL-7822',
      'boarding_time': '05:25 pm',
      'gate': 'B8',
      'terminal': '3',
      'seat_number': 'Available',
      'price': 312.0,
    },
    {
      'flight_code': 'AK 712',
      'airline_name': 'AirAsia',
      'departure_airport': 'SIN',
      'arrival_airport': 'DPS',
      'departure_time': '12:45',
      'arrival_time': '15:30',
      'flight_date': '2026-06-16',
      'confirmation_no': 'AVL-9011',
      'boarding_time': '12:00 pm',
      'gate': 'D2',
      'terminal': '4',
      'seat_number': 'Available',
      'price': 128.0,
    },
    {
      'flight_code': 'AK 713',
      'airline_name': 'AirAsia',
      'departure_airport': 'DPS',
      'arrival_airport': 'SIN',
      'departure_time': '16:20',
      'arrival_time': '19:05',
      'flight_date': '2026-06-24',
      'confirmation_no': 'AVL-9012',
      'boarding_time': '03:35 pm',
      'gate': '5',
      'terminal': 'I',
      'seat_number': 'Available',
      'price': 135.0,
    },
    {
      'flight_code': 'SQ 279',
      'airline_name': 'Singapore Airlines',
      'departure_airport': 'DPS',
      'arrival_airport': 'SIN',
      'departure_time': '21:05',
      'arrival_time': '23:50',
      'flight_date': '2026-06-24',
      'confirmation_no': 'AVL-7823',
      'boarding_time': '08:15 pm',
      'gate': '12',
      'terminal': 'I',
      'seat_number': 'Available',
      'price': 298.0,
    },
    {
      'flight_code': 'VN 628',
      'airline_name': 'Vietnam Airlines',
      'departure_airport': 'SGN',
      'arrival_airport': 'DPS',
      'departure_time': '09:15',
      'arrival_time': '13:40',
      'flight_date': '2026-06-16',
      'confirmation_no': 'AVL-5520',
      'boarding_time': '08:30 am',
      'gate': '7',
      'terminal': '2',
      'seat_number': 'Available',
      'price': 195.0,
    },
    {
      'flight_code': 'VN 629',
      'airline_name': 'Vietnam Airlines',
      'departure_airport': 'DPS',
      'arrival_airport': 'SGN',
      'departure_time': '14:30',
      'arrival_time': '17:10',
      'flight_date': '2026-06-24',
      'confirmation_no': 'AVL-5521',
      'boarding_time': '01:45 pm',
      'gate': '3',
      'terminal': 'I',
      'seat_number': 'Available',
      'price': 188.0,
    },
    {
      'flight_code': 'TG 432',
      'airline_name': 'Thai Airways',
      'departure_airport': 'BKK',
      'arrival_airport': 'DPS',
      'departure_time': '10:00',
      'arrival_time': '14:20',
      'flight_date': '2026-06-16',
      'confirmation_no': 'AVL-3310',
      'boarding_time': '09:10 am',
      'gate': 'C4',
      'terminal': '1',
      'seat_number': 'Available',
      'price': 220.0,
    },
    {
      'flight_code': 'JL 712',
      'airline_name': 'Japan Airlines',
      'departure_airport': 'HND',
      'arrival_airport': 'SIN',
      'departure_time': '18:30',
      'arrival_time': '00:45',
      'flight_date': '2026-06-15',
      'confirmation_no': 'AVL-4410',
      'boarding_time': '05:45 pm',
      'gate': '42',
      'terminal': '1',
      'seat_number': 'Available',
      'price': 540.0,
    },
    {
      'flight_code': 'BA 11',
      'airline_name': 'British Airways',
      'departure_airport': 'LHR',
      'arrival_airport': 'SIN',
      'departure_time': '19:30',
      'arrival_time': '16:10',
      'flight_date': '2026-06-14',
      'confirmation_no': 'AVL-1100',
      'boarding_time': '06:30 pm',
      'gate': 'A3',
      'terminal': '5',
      'seat_number': 'Available',
      'price': 890.0,
    },
  ];

  /// Search available flights by route and date (mock catalog filtered locally).
  Future<List<Map<String, dynamic>>> searchFlights(FlightSearchCriteria criteria) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final origin = criteria.origin.trim().toUpperCase();
    final destination = criteria.destination.trim().toUpperCase();
    final targetDate = DateFormat('yyyy-MM-dd').format(criteria.date);

    final results = _catalog.where((flight) {
      final dep = (flight['departure_airport'] as String).toUpperCase();
      final arr = (flight['arrival_airport'] as String).toUpperCase();
      final date = flight['flight_date'] as String;
      return dep == origin && arr == destination && date == targetDate;
    }).map(_withDisplayDate).toList();

    if (results.isEmpty) {
      return _generateFallbackFlights(origin, destination, criteria.date);
    }

    return results;
  }

  List<Map<String, dynamic>> _generateFallbackFlights(
    String origin,
    String destination,
    DateTime date,
  ) {
    final isoDate = DateFormat('yyyy-MM-dd').format(date);
    final displayDate = DateFormat('EEE, d MMM').format(date);
    final airlines = [
      ('Singapore Airlines', 'SQ', 320.0),
      ('AirAsia', 'AK', 145.0),
      ('Vietnam Airlines', 'VN', 210.0),
    ];

    return List.generate(airlines.length, (i) {
      final (name, code, price) = airlines[i];
      final depHour = 7 + i * 4;
      final arrHour = depHour + 3;
      return _withDisplayDate({
        'flight_code': '$code ${100 + i}',
        'airline_name': name,
        'departure_airport': origin,
        'arrival_airport': destination,
        'departure_time': '${depHour.toString().padLeft(2, '0')}:15',
        'arrival_time': '${arrHour.toString().padLeft(2, '0')}:30',
        'flight_date': isoDate,
        'confirmation_no': 'AVL-${1000 + i}',
        'boarding_time': '${(depHour - 1).toString().padLeft(2, '0')}:45 am',
        'gate': '${10 + i}',
        'terminal': '${i + 1}',
        'seat_number': 'Available',
        'price': price,
        'display_date': displayDate,
      });
    });
  }

  Map<String, dynamic> _withDisplayDate(Map<String, dynamic> flight) {
    final copy = Map<String, dynamic>.from(flight);
    final rawDate = copy['flight_date'] as String;
    final parsed = DateTime.tryParse(rawDate);
    copy['display_date'] = parsed != null
        ? DateFormat('EEE, d MMM').format(parsed)
        : rawDate;
    return copy;
  }

  /// Fetch the user's existing bookings (already purchased tickets).
  Future<List<Map<String, dynamic>>> fetchMyBookingsFromApi() async {
    await Future.delayed(const Duration(milliseconds: 800));

    const jsonResponse = '''
      [
        {
          "flight_code": "SQ 278",
          "airline_name": "Singapore Airlines",
          "departure_airport": "SIN",
          "arrival_airport": "DPS",
          "departure_time": "21:05",
          "arrival_time": "00:50",
          "flight_date": "Sun, 16 Jun",
          "confirmation_no": "#12434",
          "boarding_time": "12:30 pm",
          "gate": "36",
          "terminal": "18",
          "seat_number": "D4/E4/F4",
          "price": 240.0
        },
        {
          "flight_code": "AK 278",
          "airline_name": "AirAsia",
          "departure_airport": "DPS",
          "arrival_airport": "SIN",
          "departure_time": "21:05",
          "arrival_time": "00:50",
          "flight_date": "Sun, 24 Jun",
          "confirmation_no": "#12434",
          "boarding_time": "08:15 pm",
          "gate": "12",
          "terminal": "2",
          "seat_number": "F10/F11",
          "price": 112.0
        },
        {
          "flight_code": "AK 396",
          "airline_name": "AirAsia",
          "departure_airport": "DPS",
          "arrival_airport": "SIN",
          "departure_time": "22:05",
          "arrival_time": "01:50",
          "flight_date": "Sun, 26 Jun",
          "confirmation_no": "#15723",
          "boarding_time": "09:15 pm",
          "gate": "14",
          "terminal": "2",
          "seat_number": "A15/A16/A17",
          "price": 140.0
        }
      ]
      ''';

    return List<Map<String, dynamic>>.from(json.decode(jsonResponse));
  }

  Future<Map<String, dynamic>> getLiveFlightStatus(String flightCode) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'flight_code': flightCode,
      'status': 'On Time',
      'current_gate': '36',
      'estimated_departure': '21:05',
    };
  }
}
