import 'dart:math';
import 'package:trip_planner/models/itinerary_place.dart';
import 'package:trip_planner/models/expense.dart';
import 'package:trip_planner/services/route_optimizer.dart';
import 'package:trip_planner/services/expense_calculator.dart';

void main() {
  final random = Random(42); // fixed seed for reproducibility

  print('### Benchmark Results');
  print('');

  // ==========================================
  // 1. ROUTE OPTIMIZER BENCHMARK
  // ==========================================
  print('#### 1. Đánh giá thuật toán Route Optimization (Nearest Neighbor + Haversine)');
  print('| Số địa điểm | Quãng đường ban đầu (km) | Quãng đường sau tối ưu (km) | % Cải thiện | Thời gian chạy (ms) |');
  print('|---|---|---|---|---|');

  final counts = [10, 30, 50, 100];
  for (final count in counts) {
    // Generate random places around a central coordinate (e.g., Bali)
    final places = List.generate(count, (i) {
      // +/- 0.5 degrees roughly is a ~50km radius
      double lat = -8.5 + (random.nextDouble() - 0.5);
      double lng = 115.2 + (random.nextDouble() - 0.5);
      return ItineraryPlace(
        id: i,
        tripId: 1,
        date: '2026-06-16',
        title: 'Place $i',
        lat: lat,
        lng: lng,
        startTime: '09:00',
        sortOrder: i, // Random initial order is implicit by generation
      );
    });

    final currentOrder = RouteOptimizer.currentOrder(places);
    final currentDist = RouteOptimizer.routeDistanceKm(currentOrder);

    final stopwatch = Stopwatch()..start();
    final optimizedOrder = RouteOptimizer.optimize(places);
    stopwatch.stop();

    final optimizedDist = RouteOptimizer.routeDistanceKm(optimizedOrder);
    final improvement = currentDist > 0 ? ((currentDist - optimizedDist) / currentDist * 100) : 0;

    print('| $count | ${currentDist.toStringAsFixed(2)} | ${optimizedDist.toStringAsFixed(2)} | ${improvement.toStringAsFixed(1)}% | ${stopwatch.elapsedMilliseconds} ms |');
  }

  print('');

  // ==========================================
  // 2. EXPENSE CALCULATOR BENCHMARK
  // ==========================================
  print('#### 2. Đánh giá thuật toán Simplify Debts (Đồ thị có hướng)');
  print('| Số giao dịch gốc | Số người tham gia | Số giao dịch sau khi rút gọn | Thời gian chạy (ms) | Check số dư (Invariants) |');
  print('|---|---|---|---|---|');

  final expenseCounts = [10, 50, 100, 500];
  for (final count in expenseCounts) {
    final numPeople = (count / 5).clamp(3, 20).toInt(); // proportional group size
    final people = List.generate(numPeople, (i) => 'Person_${i+1}');
    
    final expenses = List.generate(count, (i) {
      final payer = people[random.nextInt(people.length)];
      // Randomly select 1 to all people to split
      final splitCount = random.nextInt(people.length) + 1;
      final splitPeople = (people.toList()..shuffle(random)).take(splitCount).join(',');

      return Expense(
        tripId: 1,
        title: 'Expense $i',
        amount: (random.nextDouble() * 1000) + 10,
        category: 'Food',
        paidBy: payer,
        splitBetween: splitPeople,
      );
    });

    // Check invariants (Net balance should be 0 in the end and preserve individual balances)
    // 1. Expected balances
    final expectedBalances = <String, double>{};
    for (final exp in expenses) {
      final split = exp.splitBetween.split(',');
      final perPerson = exp.amount / split.length;
      expectedBalances[exp.paidBy] = (expectedBalances[exp.paidBy] ?? 0) + exp.amount;
      for (final person in split) {
        expectedBalances[person] = (expectedBalances[person] ?? 0) - perPerson;
      }
    }

    final stopwatch = Stopwatch()..start();
    final simplifiedDebts = ExpenseCalculator.simplifyDebts(expenses);
    stopwatch.stop();

    // Reconstruct balances from simplified debts
    final actualBalances = <String, double>{};
    for (final d in simplifiedDebts) {
      actualBalances[d.to] = (actualBalances[d.to] ?? 0) + d.amount; // receiving
      actualBalances[d.from] = (actualBalances[d.from] ?? 0) - d.amount; // paying
    }

    bool invariantsMatch = true;
    for (final p in people) {
      final expected = expectedBalances[p] ?? 0;
      final actual = actualBalances[p] ?? 0;
      // using 0.05 tolerance due to float rounding
      if ((expected - actual).abs() > 0.05) {
        invariantsMatch = false;
        break;
      }
    }

    print('| $count | $numPeople | ${simplifiedDebts.length} | ${stopwatch.elapsedMilliseconds} ms | ${invariantsMatch ? '✅ PASSED' : '❌ FAILED'} |');
  }
}
