import '../models/expense.dart';
import '../data/travelers.dart';

class ExpenseCalculator {
  /// Total amount each traveler is responsible for based on split_between.
  static Map<String, double> perPersonTotals(List<Expense> expenses) {
    final totals = {for (final t in kTravelers) t.name: 0.0};

    for (final exp in expenses) {
      final split = exp.splitBetween
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (split.isEmpty) continue;
      final perPerson = exp.amount / split.length;
      for (final person in split) {
        totals[person] = (totals[person] ?? 0) + perPerson;
      }
    }

    return totals;
  }

  /// Category totals for pie/bar breakdown.
  static Map<String, double> categoryTotals(List<Expense> expenses) {
    final totals = <String, double>{};
    for (final exp in expenses) {
      totals[exp.category] = (totals[exp.category] ?? 0) + exp.amount;
    }
    return totals;
  }

  static double groupTotal(List<Expense> expenses) =>
      expenses.fold(0.0, (sum, e) => sum + e.amount);

  /// Directed Graph: Simplify Debts Greedy Algorithm
  static List<Debt> simplifyDebts(List<Expense> expenses) {
    // 1. Calculate net balances for everyone
    final Map<String, double> balances = {};
    for (final exp in expenses) {
      final split = exp.splitBetween
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (split.isEmpty) continue;

      final perPerson = exp.amount / split.length;

      // The payer gets positive balance (creditor)
      balances[exp.paidBy] = (balances[exp.paidBy] ?? 0) + exp.amount;

      // Each split member gets negative balance (debtor)
      for (final person in split) {
        balances[person] = (balances[person] ?? 0) - perPerson;
      }
    }

    // 2. Separate into creditors and debtors
    final creditors = <String, double>{};
    final debtors = <String, double>{};

    balances.forEach((person, balance) {
      // Tolerate floating point errors
      if (balance > 0.01) {
        creditors[person] = balance;
      } else if (balance < -0.01) {
        debtors[person] = -balance;
      }
    });

    // Sort by largest amounts first to greedily settle largest debts
    final sortedCreditors = creditors.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final sortedDebtors = debtors.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // 3. Match creditors and debtors
    final List<Debt> transactions = [];
    int i = 0; // creditor index
    int j = 0; // debtor index

    while (i < sortedCreditors.length && j < sortedDebtors.length) {
      final creditor = sortedCreditors[i];
      final debtor = sortedDebtors[j];

      final settleAmount = creditor.value < debtor.value ? creditor.value : debtor.value;

      transactions.add(Debt(debtor.key, creditor.key, settleAmount));

      sortedCreditors[i] = MapEntry(creditor.key, creditor.value - settleAmount);
      sortedDebtors[j] = MapEntry(debtor.key, debtor.value - settleAmount);

      if (sortedCreditors[i].value < 0.01) i++;
      if (sortedDebtors[j].value < 0.01) j++;
    }

    return transactions;
  }
}

class Debt {
  final String from;
  final String to;
  final double amount;

  Debt(this.from, this.to, this.amount);

  // Unique key for tracking settled status
  String get settlementKey => '${from}_${to}_${amount.toStringAsFixed(2)}';
}
