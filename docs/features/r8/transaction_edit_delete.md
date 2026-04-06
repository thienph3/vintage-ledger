# Feature: Transaction Edit & Delete UX

## Hiện trạng

### Đã có (service layer)
- `TransactionService.updateTransaction()` — atomic: revert old balance → apply new balance, hỗ trợ đổi type, đổi wallet, đổi amount
- `TransactionService.deleteTransaction()` — atomic: revert balance + xóa document
- `TransactionFormScreen` — form edit cho phép thay đổi tất cả fields (type, wallet, category, amount, date, note, items, createdBy)

### Thiếu (UX)
1. **Không có cách xóa transaction** — service có `deleteTransaction` nhưng không có UI trigger (không swipe, không delete button)
2. **Edit flow không rõ ràng** — tap feed item mở form nhưng không có visual cue nào cho biết item tappable
3. **Không có undo sau delete** — xóa là mất luôn
4. **Đổi type khi edit** — form cho phép đổi income ↔ expense nhưng không có warning về ảnh hưởng balance
5. **Đổi wallet khi edit** — hoạt động nhưng không có confirmation khi chuyển sang wallet khác

## Giải pháp

Chuẩn hóa UX cho edit/delete theo gesture map trong style guide.

---

## 1. Delete Transaction

### Trigger (2 cách)

**Cách 1: Swipe left trên feed item** (primary — theo gesture map)
- Swipe feed item → lộ background đỏ + icon delete
- Thả → hiện `DeleteConfirmation` dialog
- Confirm → delete + undo snackbar

**Cách 2: Delete button trong form screen** (secondary)
- Khi edit (`isEdit == true`), hiện nút "Xóa" ở cuối form
- Tap → `DeleteConfirmation` dialog
- Confirm → delete + pop + undo snackbar

### Undo

Sau khi delete thành công:
- Hiện snackbar: "Đã xóa ✓" + nút "Hoàn tác"
- Undo window: 5 giây
- Undo = `createTransaction` lại với cùng data (tạo mới, không restore ID cũ)
- Sau 5 giây hoặc navigate away → undo hết hạn

### Service

`deleteTransaction` đã hoạt động đúng. Chỉ cần:
- Trả về `TransactionWithItems` trước khi xóa (để undo có data)
- Hoặc caller lưu data trước khi gọi delete

---

## 2. Edit Transaction

### Trigger

**Tap feed item** → mở `TransactionFormScreen(existing: txn)` (đã có)

### Cải thiện UX

#### 2.1 Visual cue cho tappable items

Feed item hiện tại không có indicator nào cho biết tappable. Thêm:
- Subtle chevron `›` bên phải (AppColors.textSecondary, size 14)
- Hoặc: ripple effect khi tap (InkWell thay GestureDetector)

#### 2.2 Đổi type warning

Khi user đổi type (income → expense hoặc ngược lại) trong edit mode:
- Hiện inline warning: "Đổi loại sẽ ảnh hưởng số dư ví"
- Không block — chỉ inform
- Warning tự ẩn sau 3 giây hoặc khi user tiếp tục edit

#### 2.3 Đổi wallet trong edit

Khi user chọn wallet khác trong edit mode:
- Hiện inline info: "Giao dịch sẽ chuyển sang ví {name}"
- Không cần confirmation — service đã handle atomic revert/apply

#### 2.4 Form screen title

- Create: "Ghi thu chi mới"
- Edit: "Sửa thu chi" (đã có)
- Thêm subtitle nhỏ khi edit: ngày + số tiền gốc (để user biết đang sửa cái nào)

---

## 3. Delete trong các context khác

### Transaction List Screen (day group expanded)

Feed items trong expanded day group → swipe left to delete (cùng pattern)

### Home Screen (today feed)

Feed items trong today feed → swipe left to delete

### Wallet Detail Screen

Feed items trong wallet detail → swipe left to delete

### Tất cả dùng chung `TransactionFeedItem` → chỉ cần sửa 1 chỗ

---

## 4. Ảnh hưởng

| File | Thay đổi |
|------|----------|
| `transaction_feed_item.dart` | Wrap trong `SwipeListItem` cho swipe-to-delete. Thêm `onDelete` callback. Thêm chevron hoặc InkWell |
| `feed_item.dart` | Đổi `GestureDetector` → `InkWell` cho ripple feedback |
| `transaction_form_screen.dart` | Thêm delete button khi `isEdit`. Inline warning khi đổi type/wallet |
| `transaction_list_screen.dart` | Truyền `onDelete` cho feed items, hiện undo snackbar |
| `home_screen.dart` | Truyền `onDelete` cho feed items, hiện undo snackbar |
| `wallet_detail_screen.dart` | Truyền `onDelete` cho feed items |
| `transaction_service.dart` | `deleteTransaction` trả về deleted data (cho undo) |
| `app_vi.dart`, `app_en.dart` | Keys: `deleted`, `typeChangeWarning`, `walletChangeInfo` |

---

## 5. L10n Keys

| Key | vi | en |
|-----|----|----|
| `deleted` | `Đã xóa ✓` | `Deleted ✓` |
| `typeChangeWarning` | `Đổi loại sẽ ảnh hưởng số dư ví` | `Changing type will affect wallet balance` |
| `walletChangeInfo` | `Giao dịch sẽ chuyển sang ví {name}` | `Transaction will move to {name}` |

---

## 6. Edge Cases

| Case | Behavior |
|------|----------|
| Delete txn đã bị xóa (race condition family) | Service catch "not found" → ignore silently |
| Undo sau khi wallet bị xóa | Undo fail → snackbar "Không thể hoàn tác" |
| Edit txn mà wallet đã bị xóa | Form load → wallet dropdown không có wallet cũ → user phải chọn wallet mới |
| Đổi type income → expense khi balance = 0 | Cho phép — balance có thể âm (user tự quản lý) |
| Delete transfer txn | Revert cả 2 wallets (đã handle trong service) |
| Undo delete transfer | Tạo lại transfer (gọi createTransfer thay createTransaction) |
