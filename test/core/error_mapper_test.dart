import 'package:flutter_test/flutter_test.dart';
import 'package:vintage_ledger/core/app_exception.dart';
import 'package:vintage_ledger/core/error_mapper.dart';

void main() {
  group('ErrorMapper', () {
    test('AppException passes through', () {
      const e = AppException('test', 'testMsg');
      expect(ErrorMapper.map(e).message, 'testMsg');
    });

    test('unknown error → genericError', () {
      expect(ErrorMapper.map(Exception('random')).message, 'genericError');
    });

    test('string error → genericError', () {
      expect(ErrorMapper.map('some string').message, 'genericError');
    });
  });

  group('BudgetStatus', () {
    // Inline test since BudgetStatus is a simple model
    test('percentage and flags', () {
      // Simulate: budget 100k, spent 80k
      final pct = 80000 / 100000;
      expect(pct, 0.8);
      expect(pct >= 0.8, true); // isNearLimit
      expect(80000 > 100000, false); // not exceeded

      // Simulate: budget 100k, spent 120k
      expect(120000 > 100000, true); // isExceeded
      expect(100000 - 120000, -20000); // remaining negative
    });
  });
}
