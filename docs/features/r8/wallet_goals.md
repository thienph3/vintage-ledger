# Feature: Wallet Types & Savings Goals

## Vấn đề

Tất cả ví hiện tại đều giống nhau — không phân biệt ví chi tiêu hàng ngày và ví tiết kiệm. User không có cách đặt mục tiêu tiết kiệm (mua laptop, du lịch, quỹ khẩn cấp) và theo dõi tiến độ.

## Giải pháp

1. **Wallet Type** — phân loại ví: `spending` (chi tiêu) và `savings` (tiết kiệm)
2. **Goals** — mỗi ví savings có thể có nhiều goal, mỗi goal có target amount + deadline

---

## 1. Wallet Type

### Model

```dart
enum WalletType { spending, savings }

class Wallet {
  ...
  final WalletType type;  // NEW — default: spending
}
```

### Firestore

```
accounts/{accountId}/wallets/{docId}
  type: "spending" | "savings"    ← NEW (default "spending" cho ví cũ)
  name: "Tiết kiệm"
  balance: 2000000
  ...
```

### Behavior

| | Spending | Savings |
|---|---|---|
| Mục đích | Chi tiêu hàng ngày | Tích lũy cho mục tiêu |
| QuickAdd | Có | Không (chỉ nhận transfer) |
| Default wallet | Có thể | Không |
| Goals | Không | Có (0 hoặc nhiều) |
| Icon | 💳 | 🏦 |
| Hiển thị | Balance | Balance + progress bar tổng goals |

### Migration

Ví cũ không có field `type` → default `spending`. Không cần migration script.

---

## 2. Goals

### Model

```dart
class WalletGoal {
  final String? id;
  final String name;          // "Mua laptop", "Du lịch Đà Lạt"
  final int targetAmount;     // 15,000,000
  final int? deadline;        // timestamp (nullable — không bắt buộc)
  final String? emoji;        // "💻", "✈️" (nullable)
  final int savedAmount;      // computed: phần balance phân bổ cho goal này
  final int createdAt;
}
```

### Firestore

```
accounts/{accountId}/wallets/{walletId}/goals/{goalId}
  name: "Mua laptop"
  target_amount: 15000000
  deadline: 1735689600000       ← nullable
  emoji: "💻"                   ← nullable
  saved_amount: 5000000         ← user tự phân bổ
  created_at: ...
```

### Cách hoạt động

- `savedAmount` là số tiền user **tự phân bổ** cho goal này (không tự động)
- Tổng `savedAmount` của tất cả goals ≤ wallet balance
- Phần balance chưa phân bổ = `balance - sum(goals.savedAmount)` → hiển thị là "Chưa phân bổ"
- Khi user transfer tiền vào ví savings → balance tăng → user có thể phân bổ thêm cho goals
- Khi goal đạt target → hiện celebration 🎉

### Tại sao không tự động?

- User có thể có 1 ví savings với nhiều goals
- Mỗi lần nhận tiền, user quyết định phân bổ cho goal nào
- Đơn giản hơn việc tự động chia tiền

---

## 3. UI

### Wallet List

```
💳 Ví chính          500k
💳 Ví phụ            200k
─────────────────────────
🏦 Tiết kiệm        2tr
   ████████░░  13/15tr (Mua laptop 💻)
   ██░░░░░░░░  2/10tr  (Du lịch ✈️)
```

- Savings wallets hiện mini progress bars cho goals bên dưới

### Wallet Detail (Savings)

```
🏦 Tiết kiệm — 5,000,000đ

── Mục tiêu ──
💻 Mua laptop          3,000,000 / 15,000,000
   ████████████░░░░░░░░░░░░░░░░░░  20%
   Còn 180 ngày

✈️ Du lịch Đà Lạt     1,500,000 / 10,000,000
   ████░░░░░░░░░░░░░░░░░░░░░░░░░░  15%

💰 Chưa phân bổ: 500,000đ

[ + Thêm mục tiêu ]
```

- Tap goal → edit (name, target, deadline, emoji, savedAmount)
- Swipe goal → delete
- Progress bar: `savedAmount / targetAmount`
- Deadline: "Còn X ngày" hoặc "Quá hạn X ngày"

### Goal Form

```
Tên mục tiêu:  [ Mua laptop          ]
Emoji:         [ 💻 ]  (optional, tap to pick)
Mục tiêu:     [ 15,000,000đ          ]
Hạn chót:     [ 31/12/2025           ]  (optional)
Đã tiết kiệm: [ 3,000,000đ          ]
               [ Lưu ]
```

### Wallet Form

Thêm type picker:
```
Loại ví:  [ 💳 Chi tiêu ]  [ 🏦 Tiết kiệm ]
```

---

## 4. L10n Keys

| Key | vi | en |
|-----|----|----|
| `walletTypeSpending` | `Chi tiêu` | `Spending` |
| `walletTypeSavings` | `Tiết kiệm` | `Savings` |
| `goals` | `Mục tiêu` | `Goals` |
| `addGoal` | `Thêm mục tiêu` | `Add goal` |
| `editGoal` | `Sửa mục tiêu` | `Edit goal` |
| `deleteGoal` | `Xóa mục tiêu` | `Delete goal` |
| `deleteGoalConfirm` | `Xóa mục tiêu này luôn hả?` | `Delete this goal?` |
| `targetAmount` | `Mục tiêu` | `Target` |
| `savedAmount` | `Đã tiết kiệm` | `Saved` |
| `deadline` | `Hạn chót` | `Deadline` |
| `daysLeft` | `Còn {n} ngày` | `{n} days left` |
| `overdue` | `Quá hạn {n} ngày` | `{n} days overdue` |
| `unallocated` | `Chưa phân bổ` | `Unallocated` |
| `goalReached` | `Đạt mục tiêu rồi 🎉` | `Goal reached 🎉` |
| `goalName` | `Tên mục tiêu` | `Goal name` |
| `goalNameRequired` | `Nhập tên mục tiêu nhé` | `Enter a goal name` |
| `selectEmoji` | `Chọn emoji` | `Pick an emoji` |

---

## 5. Security Rules

```
match /wallets/{walletId}/goals/{goalId} {
  allow read: if isMember(accountId);
  allow create: if isMember(accountId) &&
    request.resource.data.name is string &&
    request.resource.data.name.size() > 0 &&
    request.resource.data.target_amount is int &&
    request.resource.data.target_amount > 0;
  allow update: if isMember(accountId);
  allow delete: if isMember(accountId);
}
```

---

## 6. Ảnh hưởng

| File | Thay đổi |
|------|----------|
| `wallet.dart` | Thêm `WalletType type` field |
| `wallet_repository.dart` | Serialize/deserialize `type` |
| `wallet_form_screen.dart` | Type picker (spending/savings) |
| `wallet_detail_screen.dart` | Goals section cho savings wallets |
| `wallet_list_screen.dart` | Mini progress bars cho savings |
| **NEW** `wallet_goal.dart` | WalletGoal model |
| **NEW** `goal_repository.dart` | CRUD cho goals subcollection |
| **NEW** `goal_service.dart` | Validate savedAmount ≤ balance |
| **NEW** `goal_form_screen.dart` | Goal create/edit form |
| **NEW** `goal_progress_bar.dart` | Reusable progress bar widget |
| `firestore.rules` | Goals subcollection rules |
| `app_vi.dart`, `app_en.dart` | ~17 keys mới |
