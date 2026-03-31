import 'package:flutter_test/flutter_test.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

void main() {
  group('AmountFormatter.formatCurrency', () {
    test('vi: formats with dot separator and đ suffix', () {
      expect(AmountFormatter.formatCurrency(0, 'vi'), '0đ');
      expect(AmountFormatter.formatCurrency(1000, 'vi'), '1.000đ');
      expect(AmountFormatter.formatCurrency(1500000, 'vi'), '1.500.000đ');
    });

    test('en: formats with comma separator and ₫ prefix', () {
      expect(AmountFormatter.formatCurrency(0, 'en'), '₫0');
      expect(AmountFormatter.formatCurrency(1000, 'en'), '₫1,000');
      expect(AmountFormatter.formatCurrency(1500000, 'en'), '₫1,500,000');
    });
  });

  group('AmountFormatter.formatCompact (vi)', () {
    test('values under 1000 return as-is', () {
      expect(AmountFormatter.formatCompact(0, 'vi'), '0');
      expect(AmountFormatter.formatCompact(500, 'vi'), '500');
    });

    test('thousands use k suffix', () {
      expect(AmountFormatter.formatCompact(1000, 'vi'), '1k');
      expect(AmountFormatter.formatCompact(50000, 'vi'), '50k');
      expect(AmountFormatter.formatCompact(500000, 'vi'), '500k');
    });

    test('millions use tr suffix', () {
      expect(AmountFormatter.formatCompact(1000000, 'vi'), '1tr');
      expect(AmountFormatter.formatCompact(1500000, 'vi'), '1tr5');
      expect(AmountFormatter.formatCompact(2000000, 'vi'), '2tr');
    });

    test('billions use tỷ suffix', () {
      expect(AmountFormatter.formatCompact(1000000000, 'vi'), '1 tỷ');
      expect(AmountFormatter.formatCompact(1200000000, 'vi'), '1 tỷ 2');
    });
  });

  group('AmountFormatter.formatCompact (en)', () {
    test('values under 1000 return as-is', () {
      expect(AmountFormatter.formatCompact(500, 'en'), '500');
    });

    test('thousands use k suffix', () {
      expect(AmountFormatter.formatCompact(1000, 'en'), '1k');
      expect(AmountFormatter.formatCompact(1500, 'en'), '1.5k');
    });

    test('millions use m suffix', () {
      expect(AmountFormatter.formatCompact(1000000, 'en'), '1m');
      expect(AmountFormatter.formatCompact(2500000, 'en'), '2.5m');
    });

    test('billions use b suffix', () {
      expect(AmountFormatter.formatCompact(1000000000, 'en'), '1b');
    });
  });

  group('AmountFormatter.formatCompactCurrency', () {
    test('vi: no prefix, compact format', () {
      expect(AmountFormatter.formatCompactCurrency(500000, 'vi'), '500k');
      expect(AmountFormatter.formatCompactCurrency(1500000, 'vi'), '1tr5');
    });

    test('en: ₫ prefix + compact format', () {
      expect(AmountFormatter.formatCompactCurrency(500000, 'en'), '₫500k');
      expect(AmountFormatter.formatCompactCurrency(1500000, 'en'), '₫1.5m');
    });
  });

  group('AmountFormatter.formatChartAxis', () {
    test('delegates to formatCompact', () {
      expect(AmountFormatter.formatChartAxis(1500000, 'vi'), '1tr5');
      expect(AmountFormatter.formatChartAxis(1500000, 'en'), '1.5m');
    });
  });
}
