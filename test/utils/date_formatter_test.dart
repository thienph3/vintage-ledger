import 'package:flutter_test/flutter_test.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';

void main() {
  // 2025-01-15 14:30:00
  final timestamp = DateTime(2025, 1, 15, 14, 30).millisecondsSinceEpoch;

  group('DateFormatter', () {
    test('short returns dd/MM HH:mm', () {
      expect(DateFormatter.short(timestamp), '15/01 14:30');
    });

    test('date returns dd/MM', () {
      expect(DateFormatter.date(timestamp), '15/01');
    });

    test('fullDate returns dd/MM/yyyy', () {
      expect(DateFormatter.fullDate(timestamp), '15/01/2025');
    });

    test('monthYear returns MM/yyyy', () {
      expect(DateFormatter.monthYear(DateTime(2025, 1)), '01/2025');
    });

    test('time returns HH:mm', () {
      expect(DateFormatter.time(timestamp), '14:30');
    });
  });
}
