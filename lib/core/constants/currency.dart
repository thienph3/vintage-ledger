class Currency {
  final String code;
  final String symbol;
  final int decimals;
  final bool symbolBefore;

  const Currency({
    required this.code,
    required this.symbol,
    this.decimals = 0,
    this.symbolBefore = false,
  });

  static const vnd = Currency(code: 'VND', symbol: 'đ', decimals: 0);
  static const usd = Currency(code: 'USD', symbol: '\$', decimals: 2, symbolBefore: true);
  static const eur = Currency(code: 'EUR', symbol: '€', decimals: 2, symbolBefore: true);
  static const jpy = Currency(code: 'JPY', symbol: '¥', decimals: 0, symbolBefore: true);
  static const krw = Currency(code: 'KRW', symbol: '₩', decimals: 0, symbolBefore: true);
  static const gbp = Currency(code: 'GBP', symbol: '£', decimals: 2, symbolBefore: true);
  static const cny = Currency(code: 'CNY', symbol: '¥', decimals: 2, symbolBefore: true);
  static const thb = Currency(code: 'THB', symbol: '฿', decimals: 2, symbolBefore: true);

  static const all = [vnd, usd, eur, gbp, jpy, krw, cny, thb];

  static const defaultCurrency = vnd;

  static Currency fromCode(String code) =>
      all.firstWhere((c) => c.code == code, orElse: () => defaultCurrency);

  bool get hasDecimals => decimals > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Currency && code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}
