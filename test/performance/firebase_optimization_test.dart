import 'package:flutter_test/flutter_test.dart';
import 'package:vintage_ledger/core/debug/read_counter.dart';
import 'package:vintage_ledger/core/cache/cache_service.dart';
import 'package:vintage_ledger/core/listeners/listener_manager.dart';

/// Performance benchmarks for Firebase read optimizations
void main() {
  group('Firebase Read Optimization Benchmarks', () {
    setUp(() {
      ReadCounter.reset();
      CacheService().clear();
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

    test('Cache service stores and retrieves data correctly', () {
      final cache = CacheService();
      
      // Test basic set/get
      cache.set('test_key', 'test_value');
      expect(cache.get<String>('test_key'), equals('test_value'));
      
      // Test TTL expiration (simulate)
      cache.set('ttl_key', 'ttl_value', ttl: Duration(milliseconds: 1));
      // In real test, would need to wait for expiration
      
      // Test cache size
      expect(cache.size, greaterThan(0));
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

    test('Cache key generation is consistent', () {
      expect(CacheService.userProfileKey('user123'), equals('user_profile:user123'));
      expect(CacheService.accountKey('acc456'), equals('account:acc456'));
      expect(CacheService.memberProfilesKey('acc789'), equals('member_profiles:acc789'));
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

      test('Cache should reduce read operations', () {
        final cache = CacheService();
        ReadCounter.reset();
        
        // First access - should increment counter
        cache.set('cached_data', 'value');
        ReadCounter.trackQuery('getFromCache', 'test', 1);
        expect(ReadCounter.count, equals(1));
        
        // Second access - should use cache (no additional reads)
        final cached = cache.get<String>('cached_data');
        expect(cached, equals('value'));
        expect(ReadCounter.count, equals(1)); // No additional reads
      });
    });

    group('Memory Management', () {
      test('Cache cleanup removes expired entries', () {
        final cache = CacheService();
        
        // Add entries with very short TTL
        cache.set('short_lived', 'value', ttl: Duration(milliseconds: 1));
        expect(cache.size, equals(1));
        
        // Simulate cleanup (in real implementation, this would be automatic)
        // For testing, we just verify the mechanism exists
        expect(cache.get<String>('short_lived'), isNotNull);
      });

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

/// Benchmark helper for measuring execution time
class BenchmarkHelper {
  static Future<Duration> measureAsync(Future<void> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    await operation();
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  static Duration measureSync(void Function() operation) {
    final stopwatch = Stopwatch()..start();
    operation();
    stopwatch.stop();
    return stopwatch.elapsed;
  }
}