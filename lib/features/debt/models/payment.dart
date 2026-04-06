class Payment {
  final String? id;
  final int amount;
  final int date;
  final String? note;
  final String? transactionId;
  final int createdAt;

  Payment({
    this.id,
    required this.amount,
    required this.date,
    this.note,
    this.transactionId,
    this.createdAt = 0,
  });

  Map<String, dynamic> toMap() => {
    'amount': amount,
    'date': date,
    'note': note,
    'transaction_id': transactionId,
    'created_at': createdAt,
  };

  factory Payment.fromMap(String id, Map<String, dynamic> data) => Payment(
    id: id,
    amount: data['amount'] ?? 0,
    date: data['date'] ?? 0,
    note: data['note'],
    transactionId: data['transaction_id'],
    createdAt: data['created_at'] ?? 0,
  );
}
