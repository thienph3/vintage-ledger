# Code Review Round 4 — Vintage Ledger

> Ngày: Tháng 7/2025 | 82 file Dart | ~8.000 LOC
> Thay đổi lớn: Firebase Auth + Account system + Family + Firestore Sync

---

## 1. Tổng quan

Round 4 thêm 3 hệ thống lớn: Authentication (Firebase Auth), Account/Family management (Firestore), và Data Sync (SQLite ↔ Firestore). Codebase tăng từ ~71 → 82 files, ~5.900 → 8.000 LOC.

**Điểm tổng: 8/10** (giảm từ 9 ở R3 vì thêm nhiều code mới chưa polish)

| Tiêu chí | R3 | R4 | Ghi chú |
|---|---|---|---|
| Kiến trúc | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Feature-first giữ vững, account/sync tách rõ |
| Data layer | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Sync logic phức tạp, cần test |
| Auth + Account | — | ⭐⭐⭐⭐ | Hoạt động, cần error handling tốt hơn |
| Sync | — | ⭐⭐⭐⭐ | Push/pull/tombstone/conflict đầy đủ |
| Security | — | ⭐⭐⭐ | Rules có nhưng chưa deploy, API key exposed |
| Testing | ⭐⭐⭐ | ⭐⭐ | Test cũ có thể broken do model changes |
| Error handling | ⭐⭐⭐⭐ | ⭐⭐⭐ | Screens mới thiếu try-catch ở một số chỗ |

---

## 2. Vấn đề phát hiện

### 2.1 🔴 API key exposed trong `firebase_options.dart`

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyADGQc3HZk1ABM6zgDvqGU2_HtrEkvmfIg',
```

File này đã commit vào git. Mặc dù Firebase API key không phải secret (nó chỉ identify project), nhưng nên restrict key trong Firebase Console và thêm `firebase_options.dart` vào `.gitignore` nếu repo public.

### 2.2 🔴 `WelcomeScreen` không còn reachable

`main.dart` flow: `!skipped && user == null` → LoginScreen, `user != null` → AccountPicker, `skipped` → HomeScreen. `WelcomeScreen` import nhưng không bao giờ navigate tới. Dead code.

### 2.3 🔴 Services chưa truyền `accountId` khi query

Repositories đã thêm `accountId` param nhưng services (`WalletService.getWallets`, `TransactionService.getDashboard`, `CategoryService.getCategories`) vẫn gọi repo methods **không truyền accountId** → luôn dùng default `'local'`. Data của account khác sẽ không hiển thị.

### 2.4 🟡 `AccountService.deleteFamily` xóa subcollections bằng loop

```dart
for (final sub in ['wallets', 'transactions', 'categories']) {
  final docs = await _accounts.doc(accountId).collection(sub).get();
  for (final doc in docs.docs) {
    await doc.reference.delete();
  }
}
```

Nếu collection lớn → timeout. Nên dùng batch delete hoặc Cloud Functions (khi upgrade plan).

### 2.5 🟡 `_pushCollection` strip `balance` khi push wallets

```dart
data.remove('is_synced');
data.remove('account_id');
```

Nhưng không remove `balance` — push balance lên Firestore là thừa vì feature spec nói "không lưu computed fields". Và pull lại set `balance` từ Firestore thay vì recalculate.

### 2.6 🟡 Pull transactions dùng `wallet_id` từ Firestore (int) nhưng local wallet có thể có ID khác

Khi pull transaction từ cloud, `wallet_id` trong Firestore data là local ID từ device push. Device khác pull sẽ có local wallet ID khác → FK mismatch. Cần map wallet bằng `remote_id` thay vì local `id`.

### 2.7 🟡 `SettingScreen` hardcode string `'Account'`

```dart
Text('Account', style: AppTextStyles.title),
```

Không dùng `S.of(context, ...)` → vi phạm l10n convention.

### 2.8 🟡 `FamilyDetailScreen` reuse l10n keys sai context

```dart
confirmDelete: () => showDeleteConfirmation(context,
  titleKey: 'leaveFamily',
  contentKey: 'deleteCategoryConfirm',  // ← sai key
),
```

Dùng `deleteCategoryConfirm` cho confirm remove member — nên có key riêng.

### 2.9 🟡 `Account` model thiếu `copyWith`

Các model khác (Wallet, Transaction, Category) đều có `copyWith`, `==`, `hashCode`. `Account` chỉ có `toMap`/`fromMap`.

### 2.10 🟡 Không có index cho `account_id` và `is_synced`

Query sync dirty records: `WHERE account_id = ? AND is_synced = 0` — chạy trên 3 bảng nhưng không có index. Sẽ chậm khi data lớn.

### 2.11 🟡 `_maybeImportFromCloud` logic sai

```dart
final dirtyCount = await sl.syncService.getDirtyCount(accountId);
if (dirtyCount == 0) {
  await sl.syncService.syncAccount(accountId);
}
```

`dirtyCount == 0` nghĩa là không có dirty records, KHÔNG nghĩa là local empty. Fresh login với seed data cũng có `dirtyCount == 0` (vì seed data có `is_synced = 1`). Nên check wallet count thay vì dirty count.

### 2.12 🟢 `SyncService` gọi `AppDatabase.instance.database` trực tiếp

`_pushTransactions` gọi `await AppDatabase.instance.database` thay vì qua repository. Vi phạm layer architecture (service → repository → database).

### 2.13 🟢 Thiếu error handling trong `FamilyFormScreen`

`_save` catch exception nhưng không hiển thị error message cho user — chỉ `setState(() => _loading = false)`.

### 2.14 🟢 `RegisterScreen` không validate email format đúng

```dart
validator: (v) => v == null || !v.contains('@') ? S.of(context, 'email') : null,
```

`contains('@')` quá lỏng — `@` alone passes. Nên dùng regex hoặc ít nhất check `contains('@') && contains('.')`.

### 2.15 🟢 Test files có thể broken

Models đã thêm `accountId`, `isSynced`, `remoteId` fields nhưng test files (`models_test.dart`) chưa cập nhật.

---

## 3. Kết luận

Firebase integration hoạt động end-to-end: Auth → Account → Sync. Kiến trúc unified account đơn giản và mở rộng tốt. Sync logic (push/pull/tombstone/last-write-wins) đầy đủ cho app cá nhân/family.

Vấn đề chính cần fix ngay: **#2.3** (services không truyền accountId — data sẽ không hiển thị đúng) và **#2.6** (wallet_id mapping khi pull cross-device). Còn lại là polish.
