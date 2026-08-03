class Expense {
  final int? id;
  final int tripId;
  final String title;
  final double amount;
  final String category;
  final String paidBy;
  final String splitBetween;
  final String date;          // ISO-8601 date string yyyy-MM-dd
  final String paymentMethod; // e.g. 'Cash', 'Card', 'Bank Transfer', 'Other'

  Expense({
    this.id,
    required this.tripId,
    required this.title,
    required this.amount,
    required this.category,
    this.paidBy = 'Me',
    this.splitBetween = 'Me',
    String? date,
    this.paymentMethod = 'Cash',
  }) : date = date ?? _today();

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'title': title,
      'amount': amount,
      'category': category,
      'paid_by': paidBy,
      'split_between': splitBetween,
      'date': date,
      'payment_method': paymentMethod,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      tripId: map['trip_id'] as int,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      paidBy: map['paid_by'] as String? ?? 'Me',
      splitBetween: map['split_between'] as String? ?? 'Me',
      date: map['date'] as String? ?? Expense._today(),
      paymentMethod: map['payment_method'] as String? ?? 'Cash',
    );
  }

  Expense copyWith({
    int? id,
    int? tripId,
    String? title,
    double? amount,
    String? category,
    String? paidBy,
    String? splitBetween,
    String? date,
    String? paymentMethod,
  }) {
    return Expense(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paidBy: paidBy ?? this.paidBy,
      splitBetween: splitBetween ?? this.splitBetween,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}
