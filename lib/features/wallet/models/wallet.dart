class Wallet {
  final String? id;
  final String name;
  final int balance;
  final String currency;

  Wallet({this.id, required this.name, this.balance = 0, this.currency = 'VND'});

  Wallet copyWith({String? id, String? name, int? balance, String? currency}) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wallet && id == other.id && name == other.name &&
          balance == other.balance && currency == other.currency;

  @override
  int get hashCode => Object.hash(id, name, balance, currency);

  @override
  String toString() => 'Wallet(id: $id, name: $name, balance: $balance, currency: $currency)';
}
