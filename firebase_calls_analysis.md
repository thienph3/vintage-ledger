# Firebase Calls Analysis - Vintage Ledger

## Tổng quan

Ứng dụng Vintage Ledger sử dụng Firebase với các service chính:
- **Firestore**: Database chính cho tất cả dữ liệu
- **Firebase Auth**: Xác thực người dùng (Anonymous, Google, Email)
- **Firebase Messaging**: Push notifications
- **Firebase Functions**: Cloud functions (có file index.js)

## Cấu trúc dữ liệu Firestore

```
/accounts/{accountId}/
├── wallets/{walletId}
│   └── goals/{goalId}
├── transactions/{txnId}
│   └── reactions/{userId}
├── categories/{categoryId}
├── budgets/{budgetId}
├── debts/{debtId}
│   └── payments/{paymentId}
├── recurring_rules/{ruleId}
├── activities/{activityId}
└── notification_events/{eventId}

/users/{userId}/
├── settings/{docId}
└── fcm_tokens/{tokenId}

/pending_invites/{inviteId}
/user_emails/{email}
/config/{docId}
```

## Phân tích Firebase Calls theo tính năng

### 1. Authentication (AuthService)
**Calls:**
- `signInAnonymously()` - 1 read
- `signInWithProvider()` - 1 read
- `linkWithProvider()` - 1 read
- `signInWithEmailAndPassword()` - 1 read
- `signOut()` - 0 reads

**Đánh giá:** ✅ Tối ưu, chỉ call khi cần thiết.

### 2. Account Management (AccountService)
**Calls:**
- `createUserWithPersonalAccount()`:
  - 1 write accounts
  - 1 write users
  - 1 write user_emails
  - N writes categories (seed data)
  - **Total: ~15-20 writes**

- `getAccountsForUser()`:
  - 1 read users doc
  - N reads accounts (theo account_ids)
  - **Potential issue: N+1 query pattern**

- `getAccount()`:
  - 1 read accounts + cache
  - **✅ Có cache tốt**

- `getMemberProfiles()`:
  - N reads users docs
  - **Potential issue: N+1 query pattern**

**Vấn đề phát hiện:**
🚨 **N+1 Query Pattern** trong `getAccountsForUser()` và `getMemberProfiles()`

### 3. Wallet Management (WalletRepository)
**Calls:**
- `watchWallets()` - 1 realtime listener
- `add()` - 1 write
- `update()` - 1 write
- `delete()` - 1 write

**Đánh giá:** ✅ Tối ưu, sử dụng realtime listeners hiệu quả.

### 4. Transaction Management (TransactionService)
**Calls:**
- `createTransaction()`:
  - 1 transaction (1 read wallet + 1 write txn + 1 write wallet)
  - 1 write activity log
  - 1 write notification_event
  - **Total: 1 read + 3 writes**

- `updateTransaction()`:
  - 1 transaction (2-3 reads wallets + 1 write txn + 1-2 writes wallets)
  - **Phức tạp nhưng atomic**

- `deleteTransaction()`:
  - 1 transaction (2-3 reads + 2-3 deletes + 1-2 writes)
  - **Phức tạp nhưng atomic**

- `watchRecent()` - 1 realtime listener với limit
- `watchByDateRange()` - 1 realtime listener với date filter

**Đánh giá:** ✅ Sử dụng Firestore transactions tốt, atomic operations.

### 5. Category Management (CategoryRepository)
**Calls:**
- `watchCategories()` - 1 realtime listener
- `watchByType()` - 1 realtime listener với filter
- `getByType()` - 1 read với filter

**Đánh giá:** ✅ Tối ưu.

### 6. Budget Management (BudgetRepository)
**Calls:**
- `watchBudgets()` - 1 realtime listener
- `getByCategoryId()` - 1 read với filter + limit(1)

**Đánh giá:** ✅ Tối ưu.

### 7. Debt Management (DebtRepository)
**Calls:**
- `getDebts()` - 1 read với orderBy
- `watchDebts()` - 1 realtime listener
- `deleteDebt()`:
  - 1 read payments subcollection
  - 1 batch write (delete payments + debt)
  - **Có thể tối ưu hơn**

**Vấn đề phát hiện:**
⚠️ `deleteDebt()` đọc tất cả payments trước khi xóa, có thể dùng batch delete trực tiếp.

### 8. Notification Service
**Calls:**
- `_registerToken()`:
  - 1 read fcm_tokens collection
  - 1 batch write (delete old + set new)

- `_acquireNotificationLock()`:
  - 1 transaction (1 read + 1 write notification_event)
  - **✅ Tốt cho deduplication**

- `_getTokensForUsers()`:
  - N reads fcm_tokens subcollections
  - **Potential issue: N+1 pattern**

**Vấn đề phát hiện:**
🚨 **N+1 Query Pattern** trong `_getTokensForUsers()`

### 9. Settings Service
**Calls:**
- `_ensureCache()` - 1 read settings doc + cache
- `_write()` - 1 write với merge

**Đánh giá:** ✅ Tối ưu với cache strategy.

### 10. Bootstrap Service
**Calls trong quá trình khởi động:**
- Auth check - 0-1 reads
- Account resolution - 1-3 reads
- Settings load - 1 read
- Data preload:
  - Categories - 1 read
  - Wallets - 1 read  
  - Account - 1 read (cached)
  - Member profiles - N reads (N+1 pattern)

**Vấn đề phát hiện:**
🚨 **N+1 Query Pattern** trong member profiles loading

## Các vấn đề thiết kế chính

### 1. N+1 Query Patterns 🚨

**Vị trí:**
- `AccountService.getAccountsForUser()`
- `AccountService.getMemberProfiles()`
- `NotificationService._getTokensForUsers()`
- Bootstrap member profiles loading

**Giải pháp:**
```dart
// Thay vì:
for (final id in accountIds) {
  final doc = await _accounts.doc(id).get(); // N reads
}

// Nên dùng:
final docs = await _firestore.getAll(accountIds.map((id) => _accounts.doc(id)));
```

### 2. Subcollection Reads không cần thiết

**Vị trí:**
- `DebtRepository.deleteDebt()` đọc tất cả payments

**Giải pháp:**
```dart
// Có thể dùng batch delete trực tiếp thay vì read trước
final batch = _firestore.batch();
// Delete debt doc trực tiếp, subcollections sẽ được cleanup bởi security rules
```

### 3. Realtime Listeners có thể dư thừa

**Cần kiểm tra:**
- Có bao nhiêu listeners đang active cùng lúc?
- Có listeners nào không được cleanup khi navigate?
- Có duplicate listeners cho cùng data không?

### 4. Cache Strategy chưa đồng nhất

**Hiện tại:**
- `AccountService` có cache cho accounts
- `SettingService` có cache cho settings
- Các service khác chưa có cache

**Đề xuất:** Implement cache layer thống nhất.

## Firestore Indexes

Các indexes đã được định nghĩa tốt trong `firestore.indexes.json`:
- Transactions by wallet_id + date
- Categories by type + name  
- Transactions by category_id + type + date
- Pending invites by user + status
- Recurring rules by enabled + next_run_at

## Security Rules

Rules được thiết kế tốt với:
- Member-based access control
- Field validation
- Proper read/write permissions

## Đề xuất tối ưu hóa

### 1. Ưu tiên cao 🔥
- **Fix N+1 patterns** trong AccountService và NotificationService
- **Implement batch operations** cho member profiles loading
- **Add connection pooling** cho multiple reads

### 2. Ưu tiên trung bình ⚠️
- **Audit realtime listeners** - đảm bảo cleanup đúng cách
- **Implement unified cache layer**
- **Optimize debt deletion** logic

### 3. Ưu tiên thấp 💡
- **Add read counter monitoring** trong production
- **Implement query result caching** cho static data
- **Consider pagination** cho large lists

## Kết luận

Nhìn chung, ứng dụng có thiết kế Firebase khá tốt với:
- ✅ Sử dụng Firestore transactions đúng cách
- ✅ Security rules được thiết kế tốt
- ✅ Indexes được định nghĩa đầy đủ
- ✅ Realtime listeners được sử dụng hiệu quả

**Vấn đề chính cần fix:**
- 🚨 N+1 query patterns (3-4 vị trí)
- ⚠️ Một số logic có thể tối ưu hơn

**Ước tính impact:** Fix N+1 patterns có thể giảm 50-70% số lượng reads không cần thiết trong các flow liên quan đến multiple users/accounts.