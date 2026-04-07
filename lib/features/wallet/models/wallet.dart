class Wallet {
  final String? id;
  final String name;
  final int balance;
  final int initialBalance;
  final String currency;

  Wallet({
    this.id,
    required this.name,
    this.balance = 0,
    this.initialBalance = 0,
    this.currency = 'VND',
  });

  Wallet copyWith({String? id, String? name, int? balance, int? initialBalance, String? currency}) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      initialBalance: initialBalance ?? this.initialBalance,
      currency: currency ?? this.currency,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wallet && id == other.id && name == other.name &&
          balance == other.balance && initialBalance == other.initialBalance &&
          currency == other.currency;

  @override
  int get hashCode => Object.hash(id, name, balance, initialBalance, currency);
}
