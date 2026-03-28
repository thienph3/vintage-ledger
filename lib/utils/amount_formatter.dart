import 'package:intl/intl.dart';

class AmountFormatter {
  static final _formatter = NumberFormat('#,###', 'vi_VN');

  static String _dotFormat(int value) =>
      _formatter.format(value).replaceAll(',', '.');

  /// Full format: vi → 1.500.000đ | en → ₫1,500,000
  static String formatCurrency(int value, String locale) {
    if (locale == 'vi') return '${_dotFormat(value)}đ';
    return '₫${NumberFormat('#,###').format(value)}';
  }

  /// Compact: vi → 1tr5, 300k, 2 tỷ | en → 1.5m, 300k, 2b
  static String formatCompact(int value, String locale) {
    if (locale == 'vi') return _compactVi(value);
    return _compactEn(value);
  }

  /// Compact with currency: vi → 1tr5đ | en → ₫1.5m
  static String formatCompactCurrency(int value, String locale) {
    if (locale == 'vi') return _compactVi(value);
    return '₫${_compactEn(value)}';
  }

  /// Chart axis labels (compact, no currency symbol)
  static String formatChartAxis(double value, String locale) =>
      formatCompact(value.toInt(), locale);

  // ── Vietnamese compact: đời thường style ──

  static String _compactVi(int value) {
    // tỷ: 1.200.000.000 → 1 tỷ 2 (có khoảng trắng vì "tỷ" là từ đầy đủ)
    if (value >= 1000000000) {
      final ty = value ~/ 1000000000;
      final remainder = (value % 1000000000) ~/ 100000000;
      if (remainder == 0) return '$ty tỷ';
      return '$ty tỷ $remainder';
    }
    // triệu: 1.200.000 → 1tr2
    if (value >= 1000000) {
      final tr = value ~/ 1000000;
      final remainder = (value % 1000000) ~/ 100000;
      if (remainder == 0) return '${tr}tr';
      return '${tr}tr$remainder';
    }
    // nghìn: 500.000 → 500k
    if (value >= 1000) {
      final k = value ~/ 1000;
      return '${k}k';
    }
    return value.toString();
  }

  // ── English compact ──

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
