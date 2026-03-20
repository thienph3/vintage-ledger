import 'package:intl/intl.dart';

class AmountFormatter {

  static String formatAmount(int value) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(value).replaceAll(',', '.');
  }

  static String formatCurrency(int value) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(value).replaceAll(',', '.')}đ';
  }
}