# R9: Firebase Read Optimization

## Overview

Optimize Firebase Firestore read operations to eliminate unnecessary reads and improve performance. Based on comprehensive codebase analysis, several critical N+1 query patterns and inefficient read operations have been identified.

## Problems Identified

### 🚨 Critical Issues - N+1 Query Patterns

1. **AccountService.getAccountsForUser()**
   - Current: Reads each account individually (1 + N reads)
   - Impact: High - called during bootstrap and account switching

2. **AccountService.getMemberProfiles()**
   - Current: Reads each user profile individually (N reads)
   - Impact: High - called for family accounts with multiple members

3. **NotificationService._getTokensForUsers()**
   - Current: Reads each user's FCM tokens individually (N reads)
   - Impact: Medium - called when sending notifications

4. **Bootstrap member profiles loading**
   - Current: Sequential reads for member profiles
   - Impact: High - affects app startup time

### ⚠️ Medium Priority Issues

5. **DebtRepository.deleteDebt()**
   - Current: Reads all payments before deletion
   - Impact: Low-Medium - unnecessary read operation

6. **Realtime listeners cleanup**
   - Current: Potential memory leaks from uncleaned listeners
   - Impact: Medium - affects app performance over time

7. **Inconsistent cache strategy**
   - Current: Some services have cache, others don't
   - Impact: Medium - missed optimization opportunities

## Solutions

### 1. Batch Read Operations
Replace N+1 patterns with Firestore batch reads using `getAll()` method.

### 2. Unified Cache Layer
Implement consistent caching strategy across all services.

### 3. Listener Management
Add proper cleanup and deduplication for realtime listeners.

### 4. Query Optimization
Optimize deletion operations and reduce unnecessary reads.

## Success Metrics

- **Read Reduction**: 50-70% fewer reads in multi-user scenarios
- **Bootstrap Time**: 30-40% faster app startup
- **Memory Usage**: Reduced memory footprint from better listener management
- **User Experience**: Faster account switching and family operations

## Implementation Priority

1. **Phase 1**: Fix N+1 patterns (Tasks 1-4)
2. **Phase 2**: Implement cache layer (Task 5)
3. **Phase 3**: Listener management and cleanup (Tasks 6-7)

## Technical Approach

- Use Firestore `getAll()` for batch reads
- Implement service-level caching with TTL
- Add listener lifecycle management
- Create read counter monitoring for production
- Maintain backward compatibility

## Risk Assessment

- **Low Risk**: Changes are mostly internal optimizations
- **High Impact**: Significant performance improvements
- **Easy Rollback**: Can revert individual optimizations if needed