class Wallet {
  final String? id;
  final String name;
  final int balance;

  Wallet({this.id, required this.name, this.balance = 0});

  Wallet copyWith({String? id, String? name, int? balance}) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wallet && id == other.id && name == other.name && balance == other.balance;

  @override
  int get hashCode => Object.hash(id, name, balance);

  @override
  String toString() => 'Wallet(id: $id, name: $name, balance: $balance)';
}
