import 'dart:async';

class CacheEntry<T> {
  final T value;
  final DateTime createdAt;
  final Duration? ttl;

  CacheEntry(this.value, this.createdAt, this.ttl);

  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().difference(createdAt) > ttl!;
  }
}

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, CacheEntry> _cache = {};
  Timer? _cleanupTimer;

  static const Duration _defaultTtl = Duration(minutes: 5);
  static const Duration _cleanupInterval = Duration(minutes: 1);

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) => _cleanup());
  }

  void _cleanup() {
    final expiredKeys = <String>[];
    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.value as T?;
  }

  void set<T>(String key, T value, {Duration? ttl}) {
    if (_cleanupTimer == null) _startCleanupTimer();
    _cache[key] = CacheEntry(value, DateTime.now(), ttl ?? _defaultTtl);
  }

  void invalidate(String key) {
    _cache.remove(key);
  }

  void invalidatePattern(String pattern) {
    final regex = RegExp(pattern);
    final keysToRemove = _cache.keys.where((key) => regex.hasMatch(key)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  void clear() {
    _cache.clear();
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  int get size => _cache.length;

  // Convenience methods for common cache patterns
  Future<T> getOrSet<T>(String key, Future<T> Function() fetcher, {Duration? ttl}) async {
    final cached = get<T>(key);
    if (cached != null) return cached;
    
    final value = await fetcher();
    set(key, value, ttl: ttl);
    return value;
  }

  // Cache keys for different data types
  static String userProfileKey(String userId) => 'user_profile:$userId';
  static String accountKey(String accountId) => 'account:$accountId';
  static String walletKey(String walletId) => 'wallet:$walletId';
  static String categoriesKey(String accountId) => 'categories:$accountId';
  static String memberProfilesKey(String accountId) => 'member_profiles:$accountId';
}
