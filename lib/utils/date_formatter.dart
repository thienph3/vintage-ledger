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

  /// Relative time: "vừa xong", "5 phút trước", "2 giờ trước", "hôm qua", "3 ngày trước"
  static String relative(dynamic timestamp) {
    if (timestamp == null) return '';
    final DateTime dt;
    if (timestamp is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else {
      return '';
    }

    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays == 1) return 'hôm qua';
    if (diff.inDays < 30) return '${diff.inDays} ngày trước';
    return fullDate(dt.millisecondsSinceEpoch);
  }
}
