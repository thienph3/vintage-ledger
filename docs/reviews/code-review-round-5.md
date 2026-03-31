# Code Review Round 5 — Vintage Ledger

> Ngày: Tháng 7/2025 | 82 file Dart | ~8.200 LOC
> Round 4 fixes applied: accountId routing, wallet_id mapping, dead code cleanup, sync polish

---

## 1. Tổng quan

**Điểm tổng: 9/10** (lên từ 8 ở R4)

Codebase ổn định. Các vấn đề critical từ R4 (accountId routing, cross-device wallet_id mapping) đã fix. Sync flow hoàn chỉnh end-to-end. Còn lại chủ yếu là cleanup và hardening.

| Tiêu chí | R4 | R5 | Ghi chú |
|---|---|---|---|
| Kiến trúc | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Giữ vững |
| Data layer | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | accountId routing fix, ID mapping fix |
| Auth + Account | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Giữ nguyên |
| Sync | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Push/pull/tombstone/conflict/cleanup hoàn chỉnh |
| Testing | ⭐⭐ | ⭐⭐ | Tests cập nhật nhưng chưa có integration test |
| Error handling | ⭐⭐⭐ | ⭐⭐⭐⭐ | FamilyForm error display, sync error handling |

---

## 2. Vấn đề phát hiện

### 2.1 🟡 `WelcomeScreen` file vẫn tồn tại

`main.dart` đã xóa import nhưng file `onboarding/screens/welcome_screen.dart` vẫn còn trên disk. Dead file.

### 2.2 🟡 `WalletFormScreen` dùng hardcode padding `16` thay `AppSpacing.md`

```dart
padding: const EdgeInsets.all(16),
```

Đã fix ở round trước cho SettingScreen nhưng WalletFormScreen vẫn còn.

### 2.3 🟡 `WalletService.updateWallet` không set `accountId` cho updated wallet

```dart
final updated = Wallet(
  id: id, name: name, balance: balance,
  createdAt: wallet.createdAt,
  // thiếu accountId: wallet.accountId
);
```

Wallet mới tạo trong `updateWallet` không copy `accountId` từ existing → default `'local'` → mất account context.

### 2.4 🟡 `CategoryService.updateCategory` tương tự

```dart
return await _repo.update(
  Category(id: id, name: name, type: type, icon: icon));
  // thiếu accountId
```

### 2.5 🟡 `FamilyFormScreen` error text dùng inline `TextStyle` thay `AppTextStyles.error`

```dart
child: Text(_error!, style: const TextStyle(color: Colors.red)),
```

Vi phạm style guide.

### 2.6 🟡 `FamilyDetailScreen` dùng `deleteWalletConfirm` cho leave/delete family confirm

```dart
contentKey: 'deleteWalletConfirm',  // nên có key riêng
```

Nên có `leaveFamilyConfirm` và `deleteFamilyConfirm`.

### 2.7 🟡 `_pullWallets` vẫn set `balance` từ Firestore

```dart
'balance': data['balance'] ?? 0,
```

Push đã strip `balance` (#4 R4), nhưng pull vẫn đọc `balance` từ Firestore (sẽ là null/0). Nên bỏ field này trong pull data vì `recalculateBalance` đã chạy sau.

### 2.8 🟢 `SampleDataService` vẫn tạo `WalletService()` mới thay vì dùng `sl`

Đã fix `SampleDataService` dùng `sl` cho `walletService` và `categoryService`, nhưng nó vẫn truy cập `AppDatabase.instance.database` trực tiếp cho batch insert.

### 2.9 🟢 `TransactionService.createTransaction` không set `account_id` trong insert map

```dart
return await txn.insert('transactions', {
  'wallet_id': walletId,
  ...
  'is_synced': 0,
  // thiếu 'account_id': _accountId
});
```

Transaction mới sẽ có `account_id = 'local'` (default) thay vì current account.

### 2.10 🟢 Không có Firestore index cho `updated_at` query

Sync pull query `WHERE updated_at > lastPullAt` trên 3 subcollections. Firestore cần composite index cho query này. Chưa có `firestore.indexes.json`.

### 2.11 🟢 `firestore.rules` chưa deploy

File `firestore.rules` tạo nhưng chưa có trong `firebase.json` deploy config.

---

## 3. Kết luận

Codebase đã production-ready cho MVP. Các vấn đề còn lại đều là polish nhỏ — không có bug critical. Ưu tiên fix #2.3 và #2.9 (accountId missing khi update/create) vì ảnh hưởng data integrity khi dùng multi-account.
