class Wallet {
  final int? id;
  final String name;
  final int balance;
  final int createdAt;

  Wallet({
    this.id,
    required this.name,
    this.balance = 0,
    required this.createdAt,
  });

  Wallet copyWith({int? id, String? name, int? balance, int? createdAt}) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

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
      createdAt: map['created_at'] is int
          ? map['created_at']
          : int.tryParse(map['created_at'].toString()) ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wallet &&
          id == other.id &&
          name == other.name &&
          balance == other.balance &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, name, balance, createdAt);

  @override
  String toString() => 'Wallet(id: $id, name: $name, balance: $balance)';
}
