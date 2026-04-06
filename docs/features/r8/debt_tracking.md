# Feature: Debt Tracking (Vay & Cho vay)

## Vấn đề

User thường có các khoản nợ:
- Nợ ngân hàng (trả góp mua nhà, mua xe)
- Cho bạn X mượn tiền
- Mượn tiền đồng nghiệp

Hiện tại không có cách nào theo dõi "ai đang nợ ai bao nhiêu" — phải nhớ trong đầu hoặc ghi note.

## Giải pháp

Thêm module **Debt** — quản lý các khoản vay/cho vay với **bất kỳ ai** (người trong app, người ngoài app, tổ chức).

---

## 1. Concepts

### Debt = 1 khoản nợ

- **Lend** (cho vay): user cho người khác mượn tiền → họ nợ user
- **Borrow** (vay): user mượn tiền người khác → user nợ họ

### Party = đối tác nợ

Có thể là:
- **Người trong app** (family member) → link bằng userId
- **Người ngoài app** → chỉ lưu tên (free text)
- **Tổ chức** → tên (ngân hàng, công ty)

### Payment = 1 lần trả nợ

Mỗi debt có nhiều payments (trả dần). Mỗi payment tạo 1 transaction thật (income/expense) trong wallet.

---

## 2. Data Model

### Debt

```dart
enum DebtType { lend, borrow }

class Debt {
  final String? id;
  final DebtType type;          // lend | borrow
  final String partyName;       // "Ngân hàng ACB", "Minh", "Chị Lan"
  final String? partyUserId;    // nullable — link nếu là member trong app
  final int totalAmount;        // tổng nợ ban đầu
  final int paidAmount;         // đã trả (computed from payments)
  final int? walletId;          // ví liên kết (nullable)
  final String? note;
  final int? dueDate;           // hạn trả (nullable)
  final int createdAt;
  final bool settled;           // đã tất toán
}
```

### Firestore

```
accounts/{accountId}/debts/{debtId}
  type: "lend" | "borrow"
  party_name: "Ngân hàng ACB"
  party_user_id: null | "userId123"
  total_amount: 50000000
  paid_amount: 10000000
  wallet_id: null | "walletId"
  note: "Trả góp mua xe"
  due_date: 1735689600000
  created_at: ...
  settled: false
```

### Payment (embedded trong debt hoặc subcollection)

Dùng **subcollection** vì có thể nhiều payments:

```
accounts/{accountId}/debts/{debtId}/payments/{paymentId}
  amount: 5000000
  date: 1720000000000
  note: "Trả tháng 7"
  transaction_id: "txnId"     ← link đến transaction thật (nullable)
  created_at: ...
```

---

## 3. Flow

### Tạo khoản cho vay (Lend)

1. User tạo debt: type=lend, partyName="Minh", totalAmount=5tr
2. Optionally: tạo expense transaction "Cho Minh mượn 5tr" từ wallet
3. Debt hiện trong danh sách: "Minh nợ bạn 5tr"

### Nhận trả nợ (Lend payment)

1. User ghi nhận payment: 2tr
2. Tạo income transaction "Minh trả nợ 2tr" vào wallet
3. Debt update: paidAmount += 2tr → "Minh còn nợ 3tr"

### Tạo khoản vay (Borrow)

1. User tạo debt: type=borrow, partyName="Ngân hàng ACB", totalAmount=500tr
2. Optionally: tạo income transaction "Vay ngân hàng 500tr" vào wallet
3. Debt hiện: "Bạn nợ Ngân hàng ACB 500tr"

### Trả nợ (Borrow payment)

1. User ghi nhận payment: 10tr
2. Tạo expense transaction "Trả nợ ngân hàng 10tr" từ wallet
3. Debt update: paidAmount += 10tr → "Còn nợ 490tr"

### Tất toán

Khi paidAmount >= totalAmount → auto mark `settled: true` → hiện 🎉

---

## 4. UI

### Debt List Screen

Tab trong Insights hoặc entry riêng từ Settings:

```
── Cho vay ──
👤 Minh              còn nợ 3,000,000đ
   ██████████░░░░░  2/5tr  (40%)

👤 Chị Lan           còn nợ 500,000đ
   █████████████░░  500k/1tr  (50%)

── Đang vay ──
🏦 Ngân hàng ACB     còn nợ 490,000,000đ
   █░░░░░░░░░░░░░░  10/500tr  (2%)
   Hạn: 15/06/2030

[ + Thêm khoản nợ ]
```

### Debt Detail Screen

```
👤 Minh nợ bạn 5,000,000đ
██████████░░░░░░░░░░  40%
Đã trả: 2,000,000đ  ·  Còn: 3,000,000đ

── Lịch sử trả ──
  01/07  Trả 1,000,000đ
  15/06  Trả 1,000,000đ

[ Ghi nhận trả nợ ]
```

### Debt Form

```
Loại:     [ Cho vay ]  [ Đi vay ]
Ai:       [ Minh                    ]  ← free text hoặc chọn member
Số tiền:  [ 5,000,000đ             ]
Ví:       [ Ví chính ▾ ]              ← optional, link wallet
Hạn trả:  [ 31/12/2025 ]              ← optional
Ghi chú:  [ Mượn mua laptop        ]
          [ Lưu ]
```

### Payment Form

```
Số tiền:  [ 1,000,000đ ]
Ghi chú:  [ Trả tháng 7 ]
Tạo giao dịch:  [✓]       ← toggle: tạo income/expense transaction
Ví:       [ Ví chính ▾ ]  ← nếu toggle on
          [ Ghi nhận ]
```

### Party Picker

Khi nhập tên đối tác:
- Gợi ý từ family members (nếu có)
- Gợi ý từ các debt cũ (tên đã dùng)
- Cho phép nhập free text (người ngoài app)

---

## 5. Tích hợp với Transaction

Khi tạo payment với toggle "Tạo giao dịch":
- **Lend payment** (nhận trả nợ) → tạo `income` transaction
- **Borrow payment** (trả nợ) → tạo `expense` transaction
- Transaction có `note` = "Trả nợ: {partyName}" hoặc "{partyName} trả nợ"
- Payment lưu `transactionId` để link

Khi tạo debt ban đầu (optional):
- **Lend** → tạo `expense` "Cho {partyName} mượn {amount}"
- **Borrow** → tạo `income` "Vay {partyName} {amount}"

---

## 6. Summary trên Home

Thêm section nhỏ trên home (nếu có debts):

```
── Nợ ──
Người khác nợ bạn: 3,500,000đ
Bạn đang nợ: 490,000,000đ
```

---

## 7. L10n Keys

| Key | vi | en |
|-----|----|----|
| `debts` | `Nợ` | `Debts` |
| `lend` | `Cho vay` | `Lend` |
| `borrow` | `Đi vay` | `Borrow` |
| `addDebt` | `Thêm khoản nợ` | `Add debt` |
| `editDebt` | `Sửa khoản nợ` | `Edit debt` |
| `deleteDebt` | `Xóa khoản nợ` | `Delete debt` |
| `deleteDebtConfirm` | `Xóa khoản nợ này luôn hả?` | `Delete this debt?` |
| `partyName` | `Ai` | `Who` |
| `partyNameRequired` | `Nhập tên nhé` | `Enter a name` |
| `dueDate` | `Hạn trả` | `Due date` |
| `recordPayment` | `Ghi nhận trả nợ` | `Record payment` |
| `createTransaction` | `Tạo giao dịch` | `Create transaction` |
| `remaining` | `Còn lại` | `Remaining` |
| `paid` | `Đã trả` | `Paid` |
| `settled` | `Đã tất toán` | `Settled` |
| `owesYou` | `nợ bạn` | `owes you` |
| `youOwe` | `bạn nợ` | `you owe` |
| `othersOweYou` | `Người khác nợ bạn` | `Others owe you` |
| `youOweOthers` | `Bạn đang nợ` | `You owe` |
| `paymentHistory` | `Lịch sử trả` | `Payment history` |
| `debtSettled` | `Tất toán rồi 🎉` | `Settled 🎉` |

---

## 8. Security Rules

```
match /debts/{debtId} {
  allow read: if isMember(accountId);
  allow create: if isMember(accountId) &&
    request.resource.data.type in ['lend', 'borrow'] &&
    request.resource.data.total_amount is int &&
    request.resource.data.total_amount > 0 &&
    request.resource.data.party_name is string &&
    request.resource.data.party_name.size() > 0;
  allow update: if isMember(accountId);
  allow delete: if isMember(accountId);

  match /payments/{paymentId} {
    allow read: if isMember(accountId);
    allow create: if isMember(accountId) &&
      request.resource.data.amount is int &&
      request.resource.data.amount > 0;
    allow update: if isMember(accountId);
    allow delete: if isMember(accountId);
  }
}
```

---

## 9. Ảnh hưởng

| File | Thay đổi |
|------|----------|
| **NEW** `features/debt/models/debt.dart` | Debt model + DebtType enum |
| **NEW** `features/debt/models/payment.dart` | Payment model |
| **NEW** `features/debt/repositories/debt_repository.dart` | Firestore CRUD cho debts |
| **NEW** `features/debt/repositories/payment_repository.dart` | Firestore CRUD cho payments subcollection |
| **NEW** `features/debt/services/debt_service.dart` | Create/settle debt, record payment + optional transaction |
| **NEW** `features/debt/screens/debt_list_screen.dart` | List cho vay + đi vay với progress |
| **NEW** `features/debt/screens/debt_detail_screen.dart` | Detail + payment history |
| **NEW** `features/debt/screens/debt_form_screen.dart` | Create/edit debt form |
| **NEW** `features/debt/screens/payment_form_screen.dart` | Record payment form |
| **NEW** `features/debt/widgets/debt_progress_bar.dart` | Reusable progress bar |
| **NEW** `features/debt/widgets/debt_summary_card.dart` | Summary cho home screen |
| `home_screen.dart` | Thêm debt summary section |
| `main_shell.dart` hoặc `settings` | Entry point đến debt list |
| `firestore.rules` | Debts + payments subcollection rules |
| `service_locator.dart` | Thêm DebtService |
| `app_vi.dart`, `app_en.dart` | ~21 keys mới |
