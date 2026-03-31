# Code Review Round 6 — Vintage Ledger

> Ngày: Tháng 7/2025 | 81 file Dart | ~8.060 LOC
> Round 5 fixes applied: accountId copy, l10n, balance strip, deploy config

---

## 1. Tổng quan

**Điểm tổng: 9.5/10**

Codebase sạch, ổn định. Không còn bug data integrity. Chỉ còn dead code cleanup và minor polish.

| Tiêu chí | R5 | R6 |
|---|---|---|
| Kiến trúc | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Data layer | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Sync | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Code hygiene | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Testing | ⭐⭐ | ⭐⭐ |

---

## 2. Vấn đề phát hiện

### 2.1 🟡 `onboarding/` feature dead code

`WelcomeScreen` đã xóa nhưng `onboarding/screens/` dir rỗng vẫn tồn tại. `SampleDataService` không còn ai import (WelcomeScreen là caller duy nhất). Toàn bộ `onboarding/` feature là dead code.

### 2.2 🟡 `SizedBox(height: 80)` hardcode trong HomeScreen

```dart
const SizedBox(height: 80),
```

Bottom padding cho FAB — nên dùng `AppSpacing` hoặc ít nhất comment giải thích.

### 2.3 🟡 `_pushTransactions` strip `account_id` nhưng không strip `wallet_id` local int

Push transactions convert `wallet_id` → remote_id, nhưng `data.remove('account_id')` chạy trước convert. Nếu convert fail (wallet chưa có remote_id) → push local int lên Firestore → device khác pull sẽ nhận int thay string → type mismatch trong resolve logic.

Nên handle case `walletRemoteId == null` → skip record thay vì push local int.

### 2.4 🟡 `_pushTransactions` cũng strip `account_id` nhưng không strip `balance`

`_pushCollection` strip `balance`, nhưng `_pushTransactions` có logic riêng và không strip `balance` (transactions không có balance field nên không ảnh hưởng, nhưng inconsistent).

### 2.5 🟢 `SyncService.syncAccount` try-catch rethrow không cần thiết

```dart
try {
  await _pushAccount(accountId);
} catch (e) {
  rethrow;
}
```

`try { ... } catch (e) { rethrow; }` tương đương không có try-catch. Bỏ cho gọn.

### 2.6 🟢 Thiếu test cho sync logic

Sync là phần phức tạp nhất nhưng không có test. Ít nhất cần unit test cho `SyncRepository.upsertByRemoteId` (last-write-wins logic).

### 2.7 🟢 `onboarding/screens/` empty directory

Directory rỗng sau khi xóa WelcomeScreen. Cleanup.

### 2.8 🟢 `WalletFormScreen` tạo `Wallet` thủ công trong save thay vì dùng service

```dart
final created = Wallet(name: name, balance: balance,
  createdAt: DateTime.now().millisecondsSinceEpoch);
await sl.walletService.createWallet(created.name, created.balance);
```

Tạo Wallet object rồi chỉ truyền name + balance cho service — Wallet object thừa.

---

## 3. Kết luận

Codebase production-ready. Các vấn đề còn lại đều là cleanup nhỏ và code hygiene. Ưu tiên #2.1 (dead code) và #2.3 (push safety) rồi có thể ship MVP.
