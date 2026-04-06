enum WalletType {
  spending,
  savings;

  static WalletType fromString(String value) =>
      WalletType.values.firstWhere((e) => e.name == value, orElse: () => WalletType.spending);
}

class Wallet {
  final String? id;
  final String name;
  final int balance;
  final int initialBalance;
  final String currency;
  final WalletType type;

  Wallet({
    this.id,
    required this.name,
    this.balance = 0,
    this.initialBalance = 0,
    this.currency = 'VND',
    this.type = WalletType.spending,
  });

  Wallet copyWith({String? id, String? name, int? balance, int? initialBalance, String? currency, WalletType? type}) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      initialBalance: initialBalance ?? this.initialBalance,
      currency: currency ?? this.currency,
      type: type ?? this.type,
    );
  }

  bool get isSavings => type == WalletType.savings;
  bool get isSpending => type == WalletType.spending;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wallet && id == other.id && name == other.name &&
          balance == other.balance && initialBalance == other.initialBalance &&
          currency == other.currency && type == other.type;

  @override
  int get hashCode => Object.hash(id, name, balance, initialBalance, currency, type);
}
