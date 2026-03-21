import 'package:intl/intl.dart';

class AmountFormatter {
  static final _formatter = NumberFormat('#,###', 'vi_VN');

  static String _dotFormat(int value) =>
      _formatter.format(value).replaceAll(',', '.');

  /// Full format: 1.500.000
  static String formatAmount(int value) => _dotFormat(value);

  /// Full format with suffix: 1.500.000đ
  static String formatCurrency(int value) => '${_dotFormat(value)}đ';

  /// Compact: 1.5m, 500k, 1.2b — for tight spaces
  static String formatCompact(int value) {
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

  /// Compact with suffix: 1.5mđ, 500kđ
  static String formatCompactCurrency(int value) =>
      '${formatCompact(value)}đ';

  /// For chart axis labels (accepts double from fl_chart)
  static String formatChartAxis(double value) =>
      formatCompact(value.toInt());
}
