import 'package:intl/intl.dart';
import 'package:vintage_ledger/core/constants/currency.dart';

class AmountFormatter {
  static final _viFormatter = NumberFormat('#,###', 'vi_VN');
  static final _enFormatter = NumberFormat('#,###');

  static String _dotFormat(int value) =>
      _viFormatter.format(value).replaceAll(',', '.');

  /// Full format with currency symbol
  static String formatCurrency(int value, String locale, {String currencyCode = 'VND'}) {
    final c = Currency.fromCode(currencyCode);

    if (c.hasDecimals) {
      final decimal = value / 100;
      final formatted = NumberFormat.currency(
        symbol: '', decimalDigits: c.decimals,
        locale: locale == 'vi' ? 'vi_VN' : 'en_US',
      ).format(decimal);
      return c.symbolBefore ? '${c.symbol}$formatted' : '$formatted${c.symbol}';
    }

    if (locale == 'vi' && currencyCode == 'VND') {
      return '${_dotFormat(value)}${c.symbol}';
    }

    final formatted = _enFormatter.format(value);
    return c.symbolBefore ? '${c.symbol}$formatted' : '$formatted${c.symbol}';
  }

  /// Compact format with currency symbol
  static String formatCompactCurrency(int value, String locale, {String currencyCode = 'VND'}) {
    final c = Currency.fromCode(currencyCode);

    if (c.hasDecimals) {
      final compact = _compactDecimal(value / 100);
      return c.symbolBefore ? '${c.symbol}$compact' : '$compact${c.symbol}';
    }

    if (locale == 'vi' && currencyCode == 'VND') return _compactVi(value);

    final compact = _compactEn(value);
    return c.symbolBefore ? '${c.symbol}$compact' : '$compact${c.symbol}';
  }

  /// Compact without currency symbol (for chart axes)
  static String formatCompact(int value, String locale) {
    if (locale == 'vi') return _compactVi(value);
    return _compactEn(value);
  }

  static String formatChartAxis(double value, String locale) =>
      formatCompact(value.toInt(), locale);

  // ── Compact helpers ──

  static String _compactDecimal(double value) {
    if (value >= 1000000000) {
      final r = value / 1000000000;
      return r % 1 == 0 ? '${r.toInt()}b' : '${r.toStringAsFixed(1)}b';
    }
    if (value >= 1000000) {
      final r = value / 1000000;
      return r % 1 == 0 ? '${r.toInt()}m' : '${r.toStringAsFixed(1)}m';
    }
    if (value >= 1000) {
      final r = value / 1000;
      return r % 1 == 0 ? '${r.toInt()}k' : '${r.toStringAsFixed(1)}k';
    }
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
  }

  static String _compactVi(int value) {
    if (value >= 1000000000) {
      final ty = value ~/ 1000000000;
      final remainder = (value % 1000000000) ~/ 100000000;
      return remainder == 0 ? '$ty tỷ' : '$ty tỷ $remainder';
    }
    if (value >= 1000000) {
      final tr = value ~/ 1000000;
      final remainder = (value % 1000000) ~/ 100000;
      return remainder == 0 ? '${tr}tr' : '${tr}tr$remainder';
    }
    if (value >= 1000) return '${value ~/ 1000}k';
    return value.toString();
  }

  static String _compactEn(int value) {
    if (value >= 1000000000) {
      final r = value / 1000000000;
      return r % 1 == 0 ? '${r.toInt()}b' : '${r.toStringAsFixed(1)}b';
    }
    if (value >= 1000000) {
      final r = value / 1000000;
      return r % 1 == 0 ? '${r.toInt()}m' : '${r.toStringAsFixed(1)}m';
    }
    if (value >= 1000) {
      final r = value / 1000;
      return r % 1 == 0 ? '${r.toInt()}k' : '${r.toStringAsFixed(1)}k';
    }
    return value.toString();
  }
}
