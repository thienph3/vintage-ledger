import 'package:vintage_ledger/features/debt/models/debt.dart';

class DebtPayment {
  final String id;
  final String debtId;
  final int amount;
  final DateTime date;
  final String? note;
  final String? transactionId;
  final String createdBy;
  final DateTime createdAt;

  const DebtPayment({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.date,
    this.note,
    this.transactionId,
    required this.createdBy,
    required this.createdAt,
  });

  // Computed properties
  bool get isLinkedToTransaction => transactionId != null;
  
  String get displayNote => note ?? 'Thanh toán nợ';

  // Factory constructors
  factory DebtPayment.fromMap(String id, Map<String, dynamic> data) {
    return DebtPayment(
      id: id,
      debtId: data['debt_id'] ?? '',
      amount: data['amount'] ?? 0,
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] ?? 0),
      note: data['note'],
      transactionId: data['transaction_id'],
      createdBy: data['created_by'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'debt_id': debtId,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      if (note != null) 'note': note,
      if (transactionId != null) 'transaction_id': transactionId,
      'created_by': createdBy,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  DebtPayment copyWith({
    String? id,
    String? debtId,
    int? amount,
    DateTime? date,
    String? note,
    String? transactionId,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return DebtPayment(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      transactionId: transactionId ?? this.transactionId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DebtPayment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DebtPayment(id: $id, debtId: $debtId, amount: $amount, date: $date)';
  }
}

/// Combined model for debt with its payments
class DebtWithPayments {
  final Debt debt;
  final List<DebtPayment> payments;

  const DebtWithPayments({
    required this.debt,
    required this.payments,
  });

  // Computed properties
  int get totalPaid => payments.fold(0, (sum, payment) => sum + payment.amount);
  
  List<DebtPayment> get sortedPayments => 
      List.from(payments)..sort((a, b) => b.date.compareTo(a.date));
  
  DebtPayment? get lastPayment => 
      payments.isEmpty ? null : sortedPayments.first;
  
  bool get hasPayments => payments.isNotEmpty;
  
  int get paymentCount => payments.length;

  DebtWithPayments copyWith({
    Debt? debt,
    List<DebtPayment>? payments,
  }) {
    return DebtWithPayments(
      debt: debt ?? this.debt,
      payments: payments ?? this.payments,
    );
  }
}