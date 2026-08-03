import 'package:flutter_test/flutter_test.dart';
import 'package:trip_planner/models/trip.dart';
import 'package:trip_planner/models/checklist_item.dart';

void main() {
  group('Trip Model Tests', () {
    test('toMap and fromMap should be consistent', () {
      final now = DateTime.now();
      final trip = Trip(
        id: 1,
        title: 'Summer Vacation',
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
        mainDestination: 'Paris',
      );

      final map = trip.toMap();
      final parsedTrip = Trip.fromMap(map);

      expect(parsedTrip.id, 1);
      expect(parsedTrip.title, 'Summer Vacation');
      expect(parsedTrip.mainDestination, 'Paris');
      expect(parsedTrip.startDate.day, now.day);
      expect(parsedTrip.endDate.day, now.add(const Duration(days: 7)).day);
    });
  });

  group('ChecklistItem Model Tests', () {
    test('toMap and fromMap should be consistent', () {
      final item = ChecklistItem(
        id: 42,
        tripId: 1,
        title: 'Visa Application',
        isCompleted: true,
        localFilePath: '/path/to/visa.pdf',
      );

      final map = item.toMap();
      final parsedItem = ChecklistItem.fromMap(map);

      expect(parsedItem.id, 42);
      expect(parsedItem.tripId, 1);
      expect(parsedItem.title, 'Visa Application');
      expect(parsedItem.isCompleted, true);
      expect(parsedItem.localFilePath, '/path/to/visa.pdf');
    });

    test('copyWith should work correctly', () {
      final item = ChecklistItem(
        id: 10,
        tripId: 2,
        title: 'Flight Ticket',
        isCompleted: false,
      );

      final updatedItem = item.copyWith(isCompleted: true, localFilePath: '/new/path.png');

      expect(updatedItem.id, 10);
      expect(updatedItem.tripId, 2);
      expect(updatedItem.title, 'Flight Ticket');
      expect(updatedItem.isCompleted, true);
      expect(updatedItem.localFilePath, '/new/path.png');
    });
  });
}
