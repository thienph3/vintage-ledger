# Feature: Transfer Transaction Type

## Vấn đề

Hiện tại chỉ có 2 loại giao dịch: `income` và `expense`. Khi user chuyển tiền giữa các ví (ví chính → ví tiết kiệm, hoặc ví cá nhân → ví chung family), phải tạo 2 giao dịch thủ công → dễ quên, dễ sai, làm lệch thống kê thu/chi.

## Giải pháp

Thêm `TransactionType.transfer` — 1 giao dịch trừ tiền ví nguồn, cộng tiền ví đích. Hỗ trợ cả **same-account** (ví A → ví B cùng sổ) và **cross-account** (ví cá nhân → ví chung family).

---

## 1. Hai loại Transfer

### 1.1 Same-account Transfer

Ví nguồn và ví đích cùng 1 account (cùng sổ).

- 1 transaction document duy nhất
- Atomic: trừ source + cộng dest trong 1 Firestore transaction
- Đơn giản, giống income/expense nhưng ảnh hưởng 2 wallets

### 1.2 Cross-account Transfer

Ví nguồn ở account A (personal), ví đích ở account B (family) — hoặc ngược lại.

- **2 transaction documents** — 1 ở mỗi account (vì transactions scoped theo account)
- Source account: transaction `type: transfer_out`, trừ tiền wallet
- Dest account: transaction `type: transfer_in`, cộng tiền wallet
- Linked bằng `linkedTransactionId` + `linkedAccountId`
- Atomic: cả 2 writes trong 1 Firestore batch/transaction

---

## 2. Data Model

### TransactionType

```dart
enum TransactionType {
  income,
  expense,
  transfer,      // same-account transfer
  transferOut,   // cross-account: phía source
  transferIn;    // cross-account: phía dest

  bool get isTransfer => this == transfer || this == transferOut || this == transferIn;
  bool get isTransferOut => this == transferOut;
  bool get isTransferIn => this == transferIn;
}
```

### TransactionModel

```dart
class TransactionModel {
  ...
  final String? toWalletId;          // ví đích (same-account transfer)
  final String? toAccountId;         // account đích (cross-account)
  final String? linkedTransactionId; // id của txn bên account kia (cross-account)
}
```

### Firestore — Same-account

```
accounts/{accountId}/transactions/{docId}
  type: "transfer"
  wallet_id: "source_wallet_id"
  to_wallet_id: "dest_wallet_id"
  amount: 500000
  category_id: ""
```

### Firestore — Cross-account

Source account:
```
accounts/{personalId}/transactions/{txnA}
  type: "transfer_out"
  wallet_id: "personal_wallet_id"
  to_account_id: "familyId"
  to_wallet_id: "family_wallet_id"
  linked_transaction_id: "txnB"
  amount: 500000
```

Dest account:
```
accounts/{familyId}/transactions/{txnB}
  type: "transfer_in"
  wallet_id: "family_wallet_id"
  to_account_id: "personalId"
  to_wallet_id: "personal_wallet_id"
  linked_transaction_id: "txnA"
  amount: 500000
```

---

## 3. Service Layer

### TransactionService.createTransfer()

**Same-account** (sourceAccountId == destAccountId):
1. Trừ source wallet
2. Cộng dest wallet
3. Tạo 1 transaction document

**Cross-account** (sourceAccountId ≠ destAccountId):
1. Tạo txnB doc ref (dest account) — lấy ID trước
2. Tạo txnA doc ref (source account) — lấy ID trước
3. Trong 1 Firestore batch:
   - Set txnA (transfer_out) với `linkedTransactionId: txnB.id`
   - Set txnB (transfer_in) với `linkedTransactionId: txnA.id`
   - Update source wallet balance (trừ)
   - Update dest wallet balance (cộng)

### deleteTransaction()

- `transfer`: revert cả 2 wallets
- `transfer_out`: revert source wallet + xóa linked txnB ở dest account + revert dest wallet
- `transfer_in`: revert dest wallet + xóa linked txnA ở source account + revert source wallet

### updateTransaction()

Transfer không hỗ trợ edit — chỉ delete + tạo mới. Đơn giản hóa logic, tránh edge cases.

---

## 4. UI

### TypeSelector

3 pills: `[ Thu ] [ Chi ] [ Chuyển ]`

### TransactionFormScreen — Transfer Mode

Khi `_type == transfer`:
- Ẩn category dropdown
- Ẩn recurring toggle, budget warning
- Hiện **account + wallet picker** cho source và dest:

```
Từ:  [ Sổ cá nhân ▾ ] → [ Ví chính ▾ ]
Sang: [ Sổ gia đình ▾ ] → [ Ví chung ▾ ]
```

- Mặc định: source = current account + last wallet, dest = trống
- Nếu user chỉ có 1 account → ẩn account picker, chỉ hiện wallet picker
- Validate: source wallet ≠ dest wallet (nếu cùng account)

### Wallet Picker cho Transfer

Cần load wallets từ **tất cả accounts** user là member:

```dart
// Load tất cả accounts + wallets
final accounts = await sl.accountService.getAccountsForUser(userId);
for (final a in accounts) {
  final wallets = await getWalletsForAccount(a.id);
  // Group: "Sổ cá nhân" → [Ví chính, Ví tiết kiệm]
  //        "Sổ gia đình" → [Ví chung]
}
```

### Transaction List / Feed

| Type | Display | Color |
|------|---------|-------|
| `transfer` | "Bạn chuyển 500k 💸 Ví A → Ví B" | `primary` |
| `transfer_out` | "Bạn chuyển 500k 💸 → Sổ gia đình" | `primary` |
| `transfer_in` | "Nhận 500k 💸 từ Sổ cá nhân" | `primary` |

---

## 5. Thống kê

- Tất cả transfer types **không** tính vào income/expense totals
- **Không** hiện trong breakdown chart
- **Có** hiện trong transaction list (filterable)

---

## 6. Security Rules

```
// Transactions
request.resource.data.type in ['income', 'expense', 'transfer', 'transfer_out', 'transfer_in']

// Cross-account write: user phải là member của cả source và dest account
// → Đã đảm bảo vì isMember() check cho mỗi account riêng
```

---

## 7. L10n Keys

| Key | vi | en |
|-----|----|----|
| `transfer` | `Chuyển` | `Transfer` |
| `fromWallet` | `Từ ví` | `From wallet` |
| `toWallet` | `Sang ví` | `To wallet` |
| `fromAccount` | `Từ sổ` | `From ledger` |
| `toAccount` | `Sang sổ` | `To ledger` |
| `sameWalletError` | `Không thể chuyển cùng ví` | `Cannot transfer to same wallet` |
| `transferOut` | `Chuyển đi` | `Transferred out` |
| `transferIn` | `Nhận chuyển` | `Received transfer` |

---

## 8. Ảnh hưởng

| File | Thay đổi |
|------|----------|
| `transaction_type.dart` | Thêm `transfer`, `transferOut`, `transferIn` + helpers |
| `transaction.dart` | Thêm `toWalletId`, `toAccountId`, `linkedTransactionId` |
| `transaction_repository.dart` | Serialize/deserialize 3 fields mới |
| `transaction_service.dart` | `createTransfer()` (same + cross), update `deleteTransaction()` cho transfer |
| `wallet_service.dart` | `getWalletsForAccount(accountId)` — load wallets từ account khác |
| `transaction_form_screen.dart` | Transfer mode: account+wallet pickers, validate |
| `type_selector.dart` | Thêm pill thứ 3 |
| `transaction_story.dart` | Transfer/transferOut/transferIn format |
| `transaction_feed_item.dart` | Transfer subtitle |
| `transaction_list_screen.dart` | Exclude transfers từ summary |
| `home_screen.dart` | Exclude transfers từ today expense |
| `dashboard_data.dart` / `transaction_service.dart` | Exclude transfers từ monthly totals |
| `firestore.rules` | Thêm 3 types mới |
| `app_vi.dart`, `app_en.dart` | 8 keys mới |
