import 'package:intl/intl.dart';

class DateFormatter {
  static String short(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat("dd/MM HH:mm").format(dt);
  }

  static String date(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat("dd/MM").format(dt);
  }

  static String fullDate(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat("dd/MM/yyyy").format(dt);
  }

  static String monthYear(DateTime dt) {
    return DateFormat("MM/yyyy").format(dt);
  }

  static String time(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat("HH:mm").format(dt);
  }
}
