import 'package:flutter_test/flutter_test.dart';
import 'package:trip_planner/models/expense.dart';
import 'package:trip_planner/models/itinerary_place.dart';
import 'package:trip_planner/services/expense_calculator.dart';
import 'package:trip_planner/services/flight_api_service.dart';
import 'package:trip_planner/services/route_optimizer.dart';

void main() {
  group('RouteOptimizer', () {
    test('optimize reduces distance for scattered points', () {
      final places = [
        const ItineraryPlace(
          id: 1,
          tripId: 1,
          date: '2026-06-16',
          title: 'A',
          startTime: '09:00',
          lat: -8.4095,
          lng: 115.1889,
        ),
        const ItineraryPlace(
          id: 2,
          tripId: 1,
          date: '2026-06-16',
          title: 'B',
          startTime: '10:00',
          lat: -8.6500,
          lng: 115.2167,
        ),
        const ItineraryPlace(
          id: 3,
          tripId: 1,
          date: '2026-06-16',
          title: 'C',
          startTime: '11:00',
          lat: -8.5000,
          lng: 115.2600,
        ),
      ];

      final current = RouteOptimizer.currentOrder(places);
      final optimized = RouteOptimizer.optimize(places);

      expect(current.length, 3);
      expect(optimized.length, 3);
      expect(
        RouteOptimizer.routeDistanceKm(optimized),
        lessThanOrEqualTo(RouteOptimizer.routeDistanceKm(current) + 0.01),
      );
    });
  });

  group('RouteOptimizer key stops', () {
    ItineraryPlace place(int id, double lat, double lng, {double cost = 0}) => ItineraryPlace(
          id: id,
          tripId: 1,
          date: '2026-06-16',
          title: 'P$id',
          startTime: '09:00',
          lat: lat,
          lng: lng,
          cost: cost,
        );

    test('groups nearby places into fewer key stops', () {
      // Two tight clusters around (0,0) and (0, 0.5) plus one isolated point.
      final places = [
        place(1, 0.000, 0.000, cost: 100),
        place(2, 0.001, 0.001),
        place(3, 0.002, 0.000),
        place(4, 0.000, 0.500, cost: 200),
        place(5, 0.001, 0.501),
        place(6, 0.300, 0.300, cost: 50),
      ];

      final rec = RouteOptimizer.recommendKeyStops(places, radiusKm: 1.0);

      expect(rec.originalCount, 6);
      expect(rec.keyCount, 3); // one per cluster + isolated
      expect(rec.mergedCount, 3);
      // Every original place is either a key stop or a satellite.
      final total = rec.keyCount +
          rec.keyStops.fold<int>(0, (s, k) => s + rec.satellitesFor(k).length);
      expect(total, 6);
    });

    test('elects the most important place as key stop', () {
      final places = [
        place(1, 0.000, 0.000, cost: 10),
        place(2, 0.001, 0.001, cost: 500), // highest cost → should be key
      ];
      final rec = RouteOptimizer.recommendKeyStops(places, radiusKm: 1.0);
      expect(rec.keyCount, 1);
      expect(rec.keyStops.first.id, 2);
    });

    test('keeps all as key stops when spread beyond radius', () {
      final places = [
        place(1, 0.0, 0.0),
        place(2, 0.0, 1.0),
        place(3, 1.0, 0.0),
      ];
      final rec = RouteOptimizer.recommendKeyStops(places, radiusKm: 0.5);
      expect(rec.keyCount, 3);
      expect(rec.mergedCount, 0);
    });
  });

  group('ExpenseCalculator', () {
    test('perPersonTotals splits evenly', () {
      final expenses = [
        Expense(
          tripId: 1,
          title: 'Hotel',
          amount: 400,
          category: 'Accomms',
          paidBy: 'Me',
          splitBetween: 'Me, Claire, Celeste, Jessica',
        ),
        Expense(
          tripId: 1,
          title: 'Lunch',
          amount: 80,
          category: 'Food',
          paidBy: 'Me',
          splitBetween: 'Me, Claire',
        ),
      ];

      final totals = ExpenseCalculator.perPersonTotals(expenses);
      expect(totals['Me'], 140);
      expect(totals['Claire'], 140);
      expect(totals['Celeste'], 100);
      expect(totals['Jessica'], 100);
    });
  });

  group('FlightApiService', () {
    test('searchFlights returns results for known route', () async {
      final results = await FlightApiService.instance.searchFlights(
        FlightSearchCriteria(
          origin: 'SIN',
          destination: 'DPS',
          date: DateTime(2026, 6, 16),
        ),
      );

      expect(results, isNotEmpty);
      expect(results.first['departure_airport'], 'SIN');
      expect(results.first['arrival_airport'], 'DPS');
    });

    test('searchFlights generates fallback for unknown route', () async {
      final results = await FlightApiService.instance.searchFlights(
        FlightSearchCriteria(
          origin: 'HAN',
          destination: 'CNX',
          date: DateTime(2026, 7, 1),
        ),
      );

      expect(results.length, 3);
      expect(results.first['departure_airport'], 'HAN');
    });
  });
}
