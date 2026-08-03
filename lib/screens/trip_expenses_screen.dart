import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/travelers.dart';
import '../db/db_helper.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import '../services/expense_calculator.dart';
import '../theme/app_colors.dart';
import '../widgets/trip_app_bar.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class TripExpensesScreen extends StatefulWidget {
  final Trip trip;
  const TripExpensesScreen({super.key, required this.trip});

  @override
  State<TripExpensesScreen> createState() => _TripExpensesScreenState();
}

class _TripExpensesScreenState extends State<TripExpensesScreen> {
  List<Expense> _expenses = [];
  Set<String> _settledPersons = {};
  bool _isLoading = true;
  int _activeTab = 0; // 0: Expenses, 1: Split

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final expenses = await DbHelper.instance.readExpensesForTrip(widget.trip.id!);
    final settled = await DbHelper.instance.readSettledPersons(widget.trip.id!);

    // Re-compute settlement with fresh expenses to clean up stale settled status.
    // If someone was marked settled but no longer has any balance (expense deleted),
    // remove them from settled so the state stays consistent.
    final freshSettlement = ExpenseCalculator.simplifyDebts(expenses);
    final cleanSettled = settled.where((key) {
      return freshSettlement.any((d) => d.settlementKey == key);
    }).toSet();

    // Persist removals to DB silently
    for (final stale in settled.difference(cleanSettled)) {
      await DbHelper.instance.setSettled(widget.trip.id!, stale, settled: false);
    }

    setState(() {
      _expenses = expenses;
      _settledPersons = cleanSettled;
      _isLoading = false;
    });
  }

  Future<void> _toggleSettled(String personName) async {
    final isNowSettled = !_settledPersons.contains(personName);
    await DbHelper.instance.setSettled(widget.trip.id!, personName, settled: isNowSettled);
    setState(() {
      if (isNowSettled) {
        _settledPersons.add(personName);
      } else {
        _settledPersons.remove(personName);
      }
    });
  }

  // ---- Settlement calculation -----------------------------------------

  /// Getter used by the build method — delegates to the pure function.
  List<Debt> get _settlement => ExpenseCalculator.simplifyDebts(_expenses);

  double get _totalSpend => _expenses.fold(0.0, (s, e) => s + e.amount);

  // ---- Add / Edit expense sheet ---------------------------------------------

  void _showExpenseSheet({Expense? editExpense}) {
    final isEdit = editExpense != null;
    final titleCtrl = TextEditingController(text: editExpense?.title ?? '');
    final amountCtrl = TextEditingController(
      text: isEdit ? editExpense.amount.toStringAsFixed(2) : '',
    );
    String paidBy = editExpense?.paidBy ?? 'Me';
    String selectedCategory = editExpense?.category ?? _kCategories.first;
    String selectedPaymentMethod = editExpense?.paymentMethod ?? _kPayMethods.first;
    DateTime selectedDate = (isEdit && editExpense.date.isNotEmpty)
        ? (DateTime.tryParse(editExpense.date) ?? DateTime.now())
        : DateTime.now();
    // Parse split from existing expense, or default everyone in
    final existingSplit = isEdit
        ? editExpense.splitBetween.split(',').map((s) => s.trim()).toSet()
        : null;
    final splitStatus = {
      for (var t in kTravelers) t.name: existingSplit?.contains(t.name) ?? true,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Drag handle ─────────────────────────────────────────
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // ── Header ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isEdit ? 'Edit Expense' : 'Add Expense',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Name ───────────────────────────────────────────────
                _field(titleCtrl, 'Expense name', 'e.g. Dinner at Seminyak'),
                const SizedBox(height: 12),

                // ── Amount ─────────────────────────────────────────────
                _field(amountCtrl, 'Total amount (\$)', '0.00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 12),

                // ── Category & Payment method (side by side) ───────────
                Row(
                  children: [
                    Expanded(
                      child: _dropdown('Category', selectedCategory, _kCategories,
                          (v) => setModalState(() => selectedCategory = v!)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dropdown('Paid via', selectedPaymentMethod, _kPayMethods,
                          (v) => setModalState(() => selectedPaymentMethod = v!)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Paid by ────────────────────────────────────────────
                const Text('Paid by', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: kTravelers.map((t) {
                      final selected = paidBy == t.name;
                      return GestureDetector(
                        onTap: () => setModalState(() => paidBy = t.name),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.teal : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: selected ? AppColors.teal : Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(radius: 13, backgroundImage: NetworkImage(t.avatarUrl)),
                              const SizedBox(width: 6),
                              Text(t.name,
                                  style: TextStyle(
                                      color: selected ? Colors.white : AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Split between ──────────────────────────────────────
                Row(
                  children: [
                    const Text('Split between', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(width: 6),
                    Text('(who shares this cost)', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                ...kTravelers.map((t) {
                  final isMe = t.name == 'Me';
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: AppColors.teal,
                    // 'Me' is always checked and cannot be unchecked
                    value: isMe ? true : (splitStatus[t.name] ?? false),
                    title: Row(
                      children: [
                        CircleAvatar(radius: 14, backgroundImage: NetworkImage(t.avatarUrl)),
                        const SizedBox(width: 10),
                        Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          Text('(always included)', style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                        ],
                      ],
                    ),
                    onChanged: isMe ? null : (val) => setModalState(() => splitStatus[t.name] = val ?? false),
                  );
                }),
                const SizedBox(height: 4),

                // ── Date ───────────────────────────────────────────────
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(primary: AppColors.teal)),
                        child: child!,
                      ),
                    );
                    if (picked != null) setModalState(() => selectedDate = picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                    ),
                    child: Text(DateFormat('dd MMM yyyy').format(selectedDate),
                        style: const TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Save ───────────────────────────────────────────────
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                    if (title.isEmpty || amount <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text('Please enter a valid name and amount.')));
                      return;
                    }
                    final splitNames = {
                      'Me',
                      ...splitStatus.entries.where((e) => e.value).map((e) => e.key),
                    }.join(', ');

                    if (isEdit) {
                      await DbHelper.instance.updateExpense(editExpense.copyWith(
                        title: title,
                        amount: amount,
                        category: selectedCategory,
                        paidBy: paidBy,
                        splitBetween: splitNames,
                        date: DateFormat('yyyy-MM-dd').format(selectedDate),
                        paymentMethod: selectedPaymentMethod,
                      ));
                    } else {
                      await DbHelper.instance.createExpense(Expense(
                        tripId: widget.trip.id!,
                        title: title,
                        amount: amount,
                        category: selectedCategory,
                        paidBy: paidBy,
                        splitBetween: splitNames,
                        date: DateFormat('yyyy-MM-dd').format(selectedDate),
                        paymentMethod: selectedPaymentMethod,
                      ));
                    }
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      _load();
                    }
                  },
                  child: Text(isEdit ? 'Save Changes' : 'Save Expense',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                if (isEdit) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      await DbHelper.instance.deleteExpense(editExpense.id!);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        _load();
                      }
                    },
                    child: const Text('Delete Expense', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _delete(int id) async {
    await DbHelper.instance.deleteExpense(id);
    await _load(); // await so Split view reflects deletion immediately
  }

  // ---- Build ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: const TripAppBar(title: 'Bills'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : Column(
              children: [
                // ── Total summary card ──────────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF37849D), AppColors.teal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Group Total', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('\$${_totalSpend.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('My share', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('\$${_myShare.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Tab toggle ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _tabBtn(0, Icons.receipt_long_outlined, 'Expenses'),
                      const SizedBox(width: 10),
                      _tabBtn(1, Icons.balance_rounded, 'Split'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Content ────────────────────────────────────────────
                Expanded(
                  child: _activeTab == 0 ? _buildExpensesList() : _buildSplitView(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showExpenseSheet,
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── Tab button ───────────────────────────────────────────────────────

  Widget _tabBtn(int index, IconData icon, String label) {
    final selected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.teal : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.teal : Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : Colors.grey),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: selected ? Colors.white : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Expenses list ────────────────────────────────────────────────────

  Widget _buildExpensesList() {
    if (_expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No expenses yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('Tap "Add" to log a group expense.', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
    }

    // Group by category
    final Map<String, List<Expense>> grouped = {};
    for (final e in _expenses) {
      grouped.putIfAbsent(e.category, () => []).add(e);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        // Category chip summary
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: grouped.entries.map((entry) {
              final total = entry.value.fold(0.0, (s, e) => s + e.amount);
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(_catIcon(entry.key), size: 13, color: _catColor(entry.key)),
                    const SizedBox(width: 5),
                    Text('${entry.key}: \$${total.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _catColor(entry.key))),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Expense cards
        for (final e in _expenses) _buildExpenseCard(e),
      ],
    );
  }

  Widget _buildExpenseCard(Expense e) {
    final split = e.splitBetween.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final perPerson = split.isNotEmpty ? e.amount / split.length : e.amount;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: _catColor(e.category).withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(_catIcon(e.category), color: _catColor(e.category), size: 18),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _pill(e.category, _catColor(e.category)),
                    _pill(e.paymentMethod, Colors.blueGrey),
                  ],
                ),
                const SizedBox(height: 6),
                // Paid by + date
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 13, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text(e.paidBy, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    const SizedBox(width: 10),
                    const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text(_fmtDate(e.date), style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 6),
                // Avatars of split members
                Row(
                  children: [
                    const Text('Split: ', style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ...split.map((name) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: CircleAvatar(radius: 10, backgroundImage: NetworkImage(avatarUrlFor(name))),
                    )),
                    Text('\$${perPerson.toStringAsFixed(2)}/each',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount + actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('\$${e.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _showExpenseSheet(editExpense: e),
                    child: Icon(Icons.edit_outlined, color: Colors.grey.shade400, size: 16),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _delete(e.id!),
                    child: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade400, size: 16),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Split / Settlement view ──────────────────────────────────────────

  // ── Split / Settlement view ──────────────────────────────────────────

  Widget _buildSplitView() {
    final net = _settlement;

    if (_expenses.isEmpty) {
      return Center(
        child: Text('Add expenses first to see how to settle up.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      );
    }

    final activeDebts = net.where((d) => !_settledPersons.contains(d.settlementKey)).toList();
    final settledDebts = net.where((d) => _settledPersons.contains(d.settlementKey)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        if (activeDebts.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Suggested Repayments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
          ),
          for (final debt in activeDebts) _settlementCard(debt, isSettled: false),
          const SizedBox(height: 16),
        ],

        // ── All settled ───────────────────────────────────────────────
        if (settledDebts.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Settled Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
          ),
          for (final debt in settledDebts) _settlementCard(debt, isSettled: true),
        ],
        
        if (activeDebts.isEmpty && settledDebts.isEmpty && _expenses.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text('Everyone is settled up!',
                  style: TextStyle(color: Colors.green.shade600, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
      ],
    );
  }

  Widget _settlementCard(Debt debt, {required bool isSettled}) {
    final involvesMe = debt.from == 'Me' || debt.to == 'Me';
    final activeColor = involvesMe ? (debt.to == 'Me' ? Colors.green.shade600 : Colors.red.shade600) : Colors.orange.shade600;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSettled ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSettled ? Colors.grey.shade200 : activeColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: isSettled ? [] : [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Avatar stack for From -> To
          SizedBox(
            width: 50,
            child: Stack(
              children: [
                CircleAvatar(radius: 18, backgroundImage: NetworkImage(avatarUrlFor(debt.from))),
                Positioned(
                  right: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(radius: 16, backgroundImage: NetworkImage(avatarUrlFor(debt.to))),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: isSettled ? Colors.grey : AppColors.textPrimary,
                      decoration: isSettled ? TextDecoration.lineThrough : null,
                    ),
                    children: [
                      TextSpan(text: debt.from, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const TextSpan(text: ' owes '),
                      TextSpan(text: debt.to, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSettled ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isSettled ? '✓ Paid' : 'Not Paid',
                        style: TextStyle(
                          color: isSettled ? Colors.green : Colors.redAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '\$${debt.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isSettled ? Colors.grey.shade400 : activeColor,
                  decoration: isSettled ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _toggleSettled(debt.settlementKey),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSettled ? Colors.grey.shade100 : activeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isSettled ? 'Undo' : 'Mark as Paid',
                    style: TextStyle(
                      color: isSettled ? Colors.grey : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          '\$${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  // ---- Helpers --------------------------------------------------------

  double get _myShare {
    double share = 0;
    for (final e in _expenses) {
      final split = e.splitBetween.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (split.contains('Me') || split.isEmpty) {
        share += e.amount / (split.isEmpty ? 1 : split.length);
      }
    }
    return share;
  }

  Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      );

  String _fmtDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  Widget _field(TextEditingController ctrl, String label, String hint,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.teal, width: 1.5)),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChanged,
    );
  }

  static const _kCategories = ['Food', 'Flights', 'Accomms', 'Transport', 'Sights', 'Shopping', 'Others'];
  static const _kPayMethods = ['Cash', 'Card', 'Bank Transfer', 'E-wallet', 'Other'];

  IconData _catIcon(String c) {
    switch (c) {
      case 'Food':      return Icons.fastfood_outlined;
      case 'Flights':   return Icons.flight_takeoff_rounded;
      case 'Accomms':   return Icons.hotel_outlined;
      case 'Transport': return Icons.directions_bus_outlined;
      case 'Sights':    return Icons.photo_camera_outlined;
      case 'Shopping':  return Icons.shopping_bag_outlined;
      default:          return Icons.receipt_long_outlined;
    }
  }

  Color _catColor(String c) {
    switch (c) {
      case 'Food':      return Colors.orange;
      case 'Flights':   return Colors.indigo;
      case 'Accomms':   return Colors.purple;
      case 'Transport': return Colors.blue;
      case 'Sights':    return Colors.green;
      case 'Shopping':  return Colors.pink;
      default:          return Colors.grey;
    }
  }
}
