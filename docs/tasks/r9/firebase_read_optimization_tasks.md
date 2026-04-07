# R9: Firebase Read Optimization Tasks

## Phase 1: Fix N+1 Query Patterns (Critical)

### Task 1: Optimize AccountService.getAccountsForUser()
**Priority**: 🔥 Critical  
**Effort**: 2 hours  
**Files**: `lib/features/account/services/account_service.dart`

Replace individual account reads with batch operation:
```dart
// Before: 1 + N reads
for (final id in accountIds) {
  final doc = await _accounts.doc(id).get();
}

// After: 1 + 1 batch read
final accountRefs = accountIds.map((id) => _accounts.doc(id)).toList();
final docs = await _firestore.getAll(accountRefs);
```

### Task 2: Optimize AccountService.getMemberProfiles()
**Priority**: 🔥 Critical  
**Effort**: 2 hours  
**Files**: `lib/features/account/services/account_service.dart`

Replace individual user profile reads with batch operation:
```dart
// Before: N reads
for (final id in memberIds) {
  final doc = await _users.doc(id).get();
}

// After: 1 batch read
final userRefs = memberIds.map((id) => _users.doc(id)).toList();
final docs = await _firestore.getAll(userRefs);
```

### Task 3: Optimize NotificationService._getTokensForUsers()
**Priority**: 🔥 Critical  
**Effort**: 3 hours  
**Files**: `lib/features/notification/services/notification_service.dart`

Use collection group query or batch reads for FCM tokens:
```dart
// Option 1: Collection group query (if possible)
final tokens = await _firestore.collectionGroup('fcm_tokens')
  .where('user_id', whereIn: userIds).get();

// Option 2: Batch subcollection reads
final futures = userIds.map((id) => 
  _firestore.collection('users').doc(id).collection('fcm_tokens').get()
);
final results = await Future.wait(futures);
```

### Task 4: Optimize Bootstrap member profiles loading
**Priority**: 🔥 Critical  
**Effort**: 1 hour  
**Files**: `lib/core/bootstrap/bootstrap_service.dart`

Update bootstrap to use optimized getMemberProfiles():
```dart
// Use the optimized batch read from Task 2
final profiles = await sl.accountService.getMemberProfiles(memberIds);
```

## Phase 2: Implement Unified Cache Layer

### Task 5: Create unified cache service
**Priority**: ⚠️ Medium  
**Effort**: 4 hours  
**Files**: 
- `lib/core/cache/cache_service.dart` (new)
- Update all repository classes

Create a unified cache layer with TTL support:
```dart
class CacheService {
  final Map<String, CacheEntry> _cache = {};
  
  T? get<T>(String key);
  void set<T>(String key, T value, {Duration? ttl});
  void invalidate(String key);
  void clear();
}
```

### Task 6: Implement cache in repositories
**Priority**: ⚠️ Medium  
**Effort**: 3 hours  
**Files**: All repository files

Add caching to frequently accessed data:
- User profiles
- Account details  
- Categories
- Wallet names

## Phase 3: Listener Management & Cleanup

### Task 7: Add listener lifecycle management
**Priority**: ⚠️ Medium  
**Effort**: 3 hours  
**Files**: 
- `lib/core/firestore/firestore_repository.dart`
- All screen files using streams

Implement proper listener cleanup:
```dart
class ListenerManager {
  final Map<String, StreamSubscription> _subscriptions = {};
  
  void addListener(String key, StreamSubscription subscription);
  void removeListener(String key);
  void clearAll();
}
```

### Task 8: Optimize DebtRepository.deleteDebt()
**Priority**: 💡 Low  
**Effort**: 1 hour  
**Files**: `lib/features/debt/repositories/debt_repository.dart`

Remove unnecessary read before deletion:
```dart
// Before: Read all payments then delete
final payments = await _payments(id).get();
// Delete logic...

// After: Direct batch delete
final batch = _firestore.batch();
batch.delete(_debts.doc(id));
// Subcollections will be handled by security rules or cloud functions
```

## Phase 4: Monitoring & Analytics

### Task 9: Enhanced read counter monitoring
**Priority**: 💡 Low  
**Effort**: 2 hours  
**Files**: `lib/core/debug/read_counter.dart`

Add detailed monitoring:
```dart
class ReadCounter {
  static void trackQuery(String operation, String collection, int count);
  static Map<String, int> getOperationBreakdown();
  static void exportMetrics();
}
```

### Task 10: Add performance benchmarks
**Priority**: 💡 Low  
**Effort**: 2 hours  
**Files**: `test/performance/` (new directory)

Create performance tests to measure improvements:
- Bootstrap time benchmarks
- Read count assertions
- Memory usage tests

## Implementation Order

1. **Week 1**: Tasks 1-4 (Fix N+1 patterns)
2. **Week 2**: Task 5-6 (Cache layer)  
3. **Week 3**: Tasks 7-8 (Cleanup & optimization)
4. **Week 4**: Tasks 9-10 (Monitoring)

## Testing Strategy

- Unit tests for each optimized method
- Integration tests for bootstrap flow
- Performance benchmarks before/after
- Read counter validation in debug mode

## Rollback Plan

Each task can be rolled back independently:
- Keep original methods as fallback
- Feature flags for new implementations
- Gradual rollout with monitoring