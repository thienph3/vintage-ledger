class Wallet {
  final int? id;
  final String name;
  final int balance;
  final String createdAt;

  Wallet({
    this.id,
    required this.name,
    this.balance = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'created_at': createdAt,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'],
      name: map['name'],
      balance: map['balance'],
      createdAt: map['created_at'],
    );
  }
}