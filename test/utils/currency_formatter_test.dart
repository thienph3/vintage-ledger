import 'package:flutter_test/flutter_test.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/core/constants/currency.dart';

void main() {
  group('AmountFormatter multi-currency', () {
    test('VND vi format', () {
      expect(AmountFormatter.formatCurrency(50000, 'vi'), '50.000đ');
      expect(AmountFormatter.formatCurrency(1500000, 'vi'), '1.500.000đ');
    });

    test('VND compact', () {
      expect(AmountFormatter.formatCompactCurrency(50000, 'vi'), '50k');
      expect(AmountFormatter.formatCompactCurrency(1500000, 'vi'), '1tr5');
      expect(AmountFormatter.formatCompactCurrency(2000000000, 'vi'), '2 tỷ');
    });

    test('USD format', () {
      final r = AmountFormatter.formatCurrency(5099, 'en', currencyCode: 'USD');
      expect(r.startsWith('\$'), true);
    });

    test('JPY no decimals', () {
      final r = AmountFormatter.formatCurrency(5000, 'en', currencyCode: 'JPY');
      expect(r.startsWith('¥'), true);
      expect(r.contains('.'), false);
    });
  });

  group('Currency model', () {
    test('fromCode known', () {
      expect(Currency.fromCode('USD'), Currency.usd);
      expect(Currency.fromCode('VND'), Currency.vnd);
    });

    test('fromCode unknown → default VND', () {
      expect(Currency.fromCode('XYZ'), Currency.defaultCurrency);
    });

    test('hasDecimals', () {
      expect(Currency.vnd.hasDecimals, false);
      expect(Currency.jpy.hasDecimals, false);
      expect(Currency.usd.hasDecimals, true);
      expect(Currency.eur.hasDecimals, true);
    });

    test('all currencies count', () {
      expect(Currency.all.length, 8);
    });
  });
}
