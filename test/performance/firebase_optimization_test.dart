import 'package:flutter_test/flutter_test.dart';
import 'package:vintage_ledger/core/debug/read_counter.dart';
import 'package:vintage_ledger/core/listeners/listener_manager.dart';

/// Performance benchmarks for Firebase read optimizations
void main() {
  group('Firebase Read Optimization Benchmarks', () {
    setUp(() {
      ReadCounter.reset();
      ListenerManager().clearAll();
    });

    test('Read counter tracks operations correctly', () {
      ReadCounter.trackQuery('getById', 'users', 1);
      ReadCounter.trackQuery('getAll', 'accounts', 5);
      ReadCounter.trackBatchRead('getMemberProfiles', ['users'], 3);

      expect(ReadCounter.count, equals(9)); // 1 + 5 + 3
      expect(ReadCounter.perOperation['getById'], equals(1));
      expect(ReadCounter.perOperation['getAll'], equals(5));
      expect(ReadCounter.perOperation['batch_getMemberProfiles'], equals(3));
      expect(ReadCounter.perCollection['users'], equals(4)); // 1 + 3
      expect(ReadCounter.perCollection['accounts'], equals(5));
    });

    test('Listener manager tracks listeners correctly', () {
      final manager = ListenerManager();

      // Mock subscription
      final subscription = Stream.empty().listen((_) {});

      manager.addListener('test_screen:wallets', subscription);
      expect(manager.activeListenerCount, equals(1));
      expect(manager.hasListener('test_screen:wallets'), isTrue);

      manager.removeListener('test_screen:wallets');
      expect(manager.activeListenerCount, equals(0));
      expect(manager.hasListener('test_screen:wallets'), isFalse);
    });

    test('Read counter efficiency score calculation', () {
      // Simulate inefficient operations (all single reads)
      ReadCounter.trackQuery('getById', 'users', 1);
      ReadCounter.trackQuery('getById', 'accounts', 1);
      ReadCounter.trackQuery('getById', 'wallets', 1);

      expect(ReadCounter.efficiencyScore, equals(1.0)); // All single ops

      ReadCounter.reset();

      // Simulate efficient operations (batch reads)
      ReadCounter.trackBatchRead('getAccounts', ['accounts'], 3);
      ReadCounter.trackBatchRead('getMemberProfiles', ['users'], 2);

      expect(ReadCounter.efficiencyScore, equals(0.0)); // All batch ops
    });

    test('Listener key generation is consistent', () {
      expect(
        ListenerManager.screenKey('home', 'wallets', 'wallet123'),
        equals('home:wallets:wallet123')
      );
      expect(
        ListenerManager.globalKey('transactions'),
        equals('global:transactions')
      );
    });

    group('Performance Assertions', () {
      test('Batch operations should be more efficient than N+1', () {
        ReadCounter.reset();

        // Simulate N+1 pattern (inefficient)
        for (int i = 0; i < 5; i++) {
          ReadCounter.trackQuery('getById', 'users', 1);
        }
        final inefficientCount = ReadCounter.count;
        final inefficientScore = ReadCounter.efficiencyScore;

        ReadCounter.reset();

        // Simulate batch operation (efficient)
        ReadCounter.trackBatchRead('getUsers', ['users'], 5);
        final efficientCount = ReadCounter.count;
        final efficientScore = ReadCounter.efficiencyScore;

        // Both should read same amount of data
        expect(efficientCount, equals(inefficientCount));
        // But batch should have better efficiency score
        expect(efficientScore, lessThan(inefficientScore));
      });
    });

    group('Memory Management', () {
      test('Listener manager cleans up properly', () {
        final manager = ListenerManager();
        final subscription1 = Stream.empty().listen((_) {});
        final subscription2 = Stream.empty().listen((_) {});

        manager.addListener('screen1:data', subscription1);
        manager.addListener('screen2:data', subscription2);
        expect(manager.activeListenerCount, equals(2));

        manager.clearAll();
        expect(manager.activeListenerCount, equals(0));
      });
    });
  });
}
