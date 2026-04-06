# Feature: Funding Source (Nguồn tiền)

## Vấn đề

Khi user đang ở family account và tạo 1 giao dịch chi (ví dụ "ăn trưa 80k"), tiền luôn trừ từ ví family. Nhưng thực tế user thường **bỏ tiền túi ra trả** (tiền cá nhân) rồi ghi vào sổ chung.

Hiện tại user phải làm 3 bước thủ công:
1. Tạo transfer từ ví cá nhân → ví family (80k)
2. Tạo expense trong family (80k)
3. Hoặc quên bước 1 → số dư ví cá nhân sai

## Giải pháp

Thêm **"Nguồn tiền"** vào form tạo giao dịch. Khi tạo txn trong family account, user chọn:
- **Ví family** (mặc định) — trừ tiền ví family như bình thường
- **Ví cá nhân** — hệ thống tự động: transfer tiền từ personal → family, rồi tạo expense

---

## 1. Khi nào hiện "Nguồn tiền"

Chỉ hiện khi **tất cả** điều kiện sau:
- Đang ở **family account** (`sl.cache.currentAccount?.isFamily == true`)
- Đang tạo **expense** (không hiện cho income hay transfer)
- User có **personal account** với ít nhất 1 wallet

Nếu đang ở personal account → ẩn hoàn toàn (không có khái niệm nguồn tiền).

---

## 2. UI

### Transaction Form — Funding Source Selector

Nằm ngay dưới wallet dropdown, chỉ hiện khi điều kiện ở §1 thỏa:

```
Ví:         [ Ví chung ▾ ]
Nguồn tiền: [ 💳 Ví chung (mặc định) ▾ ]
```

Tap → SelectionSheet:
```
── Ví gia đình ──
  💳 Ví chung              ← mặc định, trừ tiền family
── Ví cá nhân ──
  💳 Ví chính (500k)       ← trừ tiền cá nhân, auto transfer
  💳 Ví phụ (200k)
```

- Hiện balance bên cạnh ví cá nhân (để user biết còn bao nhiêu)
- Mặc định: ví family đang chọn (= không dùng nguồn cá nhân)

### Visual Indicator

Khi user chọn nguồn cá nhân, hiện inline info:

```
ℹ️ Sẽ tự chuyển 80k từ Ví chính (cá nhân) sang Ví chung
```

Tone casual, không block.

---

## 3. Service Logic

### Khi nguồn = ví family (mặc định)

Không thay đổi gì — `createTransaction()` như bình thường.

### Khi nguồn = ví cá nhân

Hệ thống thực hiện **2 operations atomic**:

1. **Cross-account transfer**: personal wallet → family wallet (amount)
   - Personal account: `transfer_out` txn, trừ balance
   - Family account: `transfer_in` txn, cộng balance
   
2. **Expense transaction**: trong family account, trừ từ family wallet
   - Giao dịch expense bình thường với category, note, date

Cả 2 operations trong 1 Firestore batch để đảm bảo atomic.

### TransactionService.createWithFunding()

```dart
Future<String> createWithFunding({
  // Expense params (giống createTransaction)
  required String walletId,        // family wallet
  required String categoryId,
  required int amount,
  String? note,
  required int date,
  
  // Funding source
  required String fundingWalletId,   // personal wallet ID
  required String fundingAccountId,  // personal account ID
}) async {
  // 1. Cross-account transfer: personal → family
  // 2. Expense in family
  // All in 1 batch
}
```

### Linking

Expense txn lưu thêm:
```
funding_wallet_id: "personal_wallet_id"
funding_account_id: "personal_account_id"
funding_transfer_id: "transfer_out_txn_id"
```

Để khi delete expense → cũng delete/revert transfer.

---

## 4. Delete / Edit

### Delete expense có funding source

Khi xóa expense mà có `funding_transfer_id`:
1. Revert family wallet balance (cộng lại)
2. Xóa linked transfer_out ở personal account + revert personal wallet
3. Xóa linked transfer_in ở family account + revert family wallet
4. Xóa expense txn

### Edit expense có funding source

Không cho đổi funding source khi edit — quá phức tạp. Nếu cần đổi → delete + tạo mới.

Cho phép đổi amount:
- Nếu amount thay đổi → update cả transfer amount + expense amount

---

## 5. Feed Display

Expense có funding source hiện thêm badge nhỏ:

```
Bạn ăn trưa 80k 🍜  08:30
💳 từ Ví chính (cá nhân)          ← subtitle nhỏ, caption style
```

Transfer tự động **không hiện riêng** trong family feed (tránh noise). Chỉ hiện trong personal account feed như `transfer_out` bình thường.

---

## 6. Data Model

### TransactionModel — thêm fields

```dart
class TransactionModel {
  ...
  final String? fundingWalletId;     // ví cá nhân đã dùng
  final String? fundingAccountId;    // account cá nhân
  final String? fundingTransferId;   // ID của transfer_out txn (để delete/revert)
}
```

### Firestore

```
accounts/{familyId}/transactions/{expenseId}
  type: "expense"
  wallet_id: "family_wallet_id"
  category_id: "food"
  amount: 80000
  funding_wallet_id: "personal_wallet_id"      ← NEW
  funding_account_id: "personalAccountId"      ← NEW
  funding_transfer_id: "transfer_out_txn_id"   ← NEW
```

---

## 7. L10n Keys

| Key | vi | en |
|-----|----|----|
| `fundingSource` | `Nguồn tiền` | `Funding source` |
| `fundingDefault` | `Ví gia đình (mặc định)` | `Family wallet (default)` |
| `fundingPersonal` | `Ví cá nhân` | `Personal wallet` |
| `fundingAutoTransfer` | `Sẽ tự chuyển {amount} từ {wallet}` | `Will auto-transfer {amount} from {wallet}` |

---

## 8. Ảnh hưởng

| File | Thay đổi |
|------|----------|
| `transaction.dart` | Thêm `fundingWalletId`, `fundingAccountId`, `fundingTransferId` |
| `transaction_repository.dart` | Serialize/deserialize 3 fields mới |
| `transaction_service.dart` | `createWithFunding()` — batch: cross-account transfer + expense. Update `deleteTransaction()` xử lý funding revert |
| `transaction_form_screen.dart` | Funding source selector (InlineSelector → SelectionSheet). Load personal wallets. Inline info khi chọn personal |
| `transaction_feed_item.dart` | Subtitle "💳 từ Ví chính (cá nhân)" khi có funding |
| `wallet_service.dart` | Reuse `getWalletsForAccount()` từ transfer feature |
| `app_vi.dart`, `app_en.dart` | 4 keys mới |

---

## 9. Dependency

Feature này **phụ thuộc** vào [Transfer Transaction](transfer_transaction.md) — dùng cross-account transfer infrastructure (transfer_out/transfer_in, linked transactions, batch writes).

Thứ tự implement: Transfer Transaction → Funding Source.
