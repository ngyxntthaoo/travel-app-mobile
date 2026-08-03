import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/travelers.dart';
import '../db/db_helper.dart';
import '../models/expense.dart';
import '../models/trip.dart';
import '../services/expense_calculator.dart';
import '../theme/app_colors.dart';
import '../widgets/trip_subheader.dart';
import 'trip_itinerary_tab.dart';
import 'trip_route_map_screen.dart';

class SharedTripScreen extends StatefulWidget {
  final Trip trip;
  final bool showCloneButton;

  const SharedTripScreen({
    super.key,
    required this.trip,
    this.showCloneButton = true,
  });

  @override
  State<SharedTripScreen> createState() => _SharedTripScreenState();
}

class _SharedTripScreenState extends State<SharedTripScreen> {
  int _activeTab = 0;
  List<Expense> _expenses = [];
  bool _loadingExpenses = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final expenses = await DbHelper.instance.readExpensesForTrip(widget.trip.id!);
    if (!mounted) return;
    setState(() {
      _expenses = expenses;
      _loadingExpenses = false;
    });
  }

  Future<void> _cloneTrip() async {
    final cloned = await DbHelper.instance.cloneTrip(widget.trip.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cloned "${cloned.title}" to your trips')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    const tabs = ['Route Map', 'Expense', 'Plan Detail'];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(widget.trip.title),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TripSubheader(trip: widget.trip),
          Container(
            color: Colors.white,
            child: Row(
              children: List.generate(tabs.length, (index) {
                final selected = _activeTab == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selected ? AppColors.teal : Colors.grey.shade100,
                            width: selected ? 2.5 : 1,
                          ),
                        ),
                      ),
                      child: Text(
                        tabs[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected ? AppColors.teal : Colors.grey,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(child: _buildTabBody()),
        ],
      ),
      bottomNavigationBar: widget.showCloneButton
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: ElevatedButton.icon(
                  onPressed: _cloneTrip,
                  icon: const Icon(Icons.copy_all_rounded),
                  label: const Text('Clone Trip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTabBody() {
    switch (_activeTab) {
      case 0:
        return TripRouteMapScreen(
          trip: widget.trip,
          allowReorder: false,
        );
      case 1:
        return _buildExpenseTab();
      case 2:
        return TripItineraryTab(trip: widget.trip, readOnly: true);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildExpenseTab() {
    if (_loadingExpenses) {
      return const Center(child: CircularProgressIndicator(color: AppColors.teal));
    }

    final perPerson = ExpenseCalculator.perPersonTotals(_expenses);
    final categories = ExpenseCalculator.categoryTotals(_expenses);
    final total = ExpenseCalculator.groupTotal(_expenses);
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Trip budget overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text('\$${total.toStringAsFixed(2)} total', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.teal)),
              Text(
                '${DateFormat('d MMM').format(widget.trip.startDate)} – ${DateFormat('d MMM yyyy').format(widget.trip.endDate)}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Cost per person', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        ...kTravelers.map((traveler) {
          final amount = perPerson[traveler.name] ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 16, backgroundImage: NetworkImage(traveler.avatarUrl)),
                const SizedBox(width: 12),
                Expanded(child: Text(traveler.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                Text('\$${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.teal)),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        const Text('By category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        ...sortedCategories.map((entry) {
          final pct = total > 0 ? (entry.value / total * 100) : 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                    Text('\$${entry.value.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade100,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${pct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          );
        }),
      ],
    );
  }
}
