# Tài liệu Yêu cầu — Sửa lỗi thiết kế Firestore

## Giới thiệu

Tài liệu này mô tả tất cả các vấn đề thiết kế Firestore đã được phát hiện trong ứng dụng vintage_ledger (Flutter). Ứng dụng quản lý tài chính cá nhân/gia đình với wallets, transactions, goals, debts, transfers, budgets, categories và recurring rules. Tất cả dữ liệu nằm dưới `accounts/{accountId}/...`. Các vấn đề bao gồm: thiếu tính atomic trong các thao tác ghi, collection dư thừa, security rules sai/thiếu, index không đúng, và logic xóa không đầy đủ.

## Thuật ngữ

- **GoalService**: Service xử lý logic mục tiêu tiết kiệm (goals_v2 collection)
- **DebtService**: Service xử lý logic công nợ (debts_v2 collection)
- **TransactionService**: Service xử lý logic giao dịch thu/chi/chuyển khoản (transactions collection)
- **TransferService**: Service xử lý chuyển khoản qua transfers_v2 collection (dư thừa)
- **AccountService**: Service xử lý tài khoản, lời mời, xóa tài khoản
- **Firestore_Transaction**: Firestore `runTransaction` — đảm bảo tất cả reads và writes trong một atomic operation
- **WriteBatch**: Firestore `WriteBatch` — ghi nhiều documents atomic nhưng không đọc dữ liệu bên trong
- **Wallet_Balance**: Trường `balance` trong document wallet, đại diện số dư hiện tại
- **Security_Rules**: File `firestore.rules` định nghĩa quyền truy cập Firestore
- **Composite_Index**: Index Firestore kết hợp nhiều fields để tối ưu query

## Yêu cầu

### Yêu cầu 1: GoalContribution atomic với Transaction và wallet balance

**User Story:** Là một người dùng, tôi muốn khi nạp tiền vào mục tiêu tiết kiệm, hệ thống tạo giao dịch chi, trừ số dư ví, tạo contribution và cập nhật goal trong một thao tác atomic, để dữ liệu luôn nhất quán.

#### Tiêu chí chấp nhận

1. WHEN người dùng nạp tiền vào mục tiêu (napVaoMucTieu), THE GoalService SHALL thực hiện trong một Firestore_Transaction duy nhất: tạo expense transaction từ funding wallet, trừ Wallet_Balance, tạo contribution, và cập nhật current_amount của goal
2. WHEN người dùng rút tiền từ mục tiêu (rutTuMucTieu), THE GoalService SHALL thực hiện trong một Firestore_Transaction duy nhất: tạo income transaction vào funding wallet, cộng Wallet_Balance, tạo contribution (amount âm), và cập nhật current_amount của goal
3. IF Firestore_Transaction thất bại ở bất kỳ bước nào, THEN THE GoalService SHALL rollback toàn bộ thay đổi và không có document nào bị thay đổi
4. WHEN current_amount đạt hoặc vượt target_amount sau khi nạp, THE GoalService SHALL cập nhật status của goal thành completed trong cùng Firestore_Transaction

### Yêu cầu 2: DebtPayment atomic với Transaction và wallet balance

**User Story:** Là một người dùng, tôi muốn khi ghi nhận thanh toán công nợ, hệ thống tạo giao dịch tương ứng, cập nhật số dư ví, tạo payment và cập nhật debt trong một thao tác atomic, để dữ liệu luôn nhất quán.

#### Tiêu chí chấp nhận

1. WHEN người dùng nhận tiền trả nợ cho khoản cho vay (nhanTienTra), THE DebtService SHALL thực hiện trong một Firestore_Transaction duy nhất: tạo income transaction, cộng Wallet_Balance, tạo payment, và cập nhật paid_amount của debt
2. WHEN người dùng trả nợ cho khoản vay mượn (traNop), THE DebtService SHALL thực hiện trong một Firestore_Transaction duy nhất: tạo expense transaction, trừ Wallet_Balance, tạo payment, và cập nhật paid_amount của debt
3. IF paid_amount đạt hoặc vượt total_amount sau khi thanh toán, THEN THE DebtService SHALL cập nhật status của debt thành completed trong cùng Firestore_Transaction
4. IF Firestore_Transaction thất bại ở bất kỳ bước nào, THEN THE DebtService SHALL rollback toàn bộ thay đổi và không có document nào bị thay đổi

### Yêu cầu 3: Cross-account transfer dùng runTransaction thay vì batch

**User Story:** Là một người dùng, tôi muốn chuyển khoản cross-account sử dụng Firestore_Transaction thay vì WriteBatch, để đảm bảo đọc số dư ví bên trong transaction và tránh race condition.

#### Tiêu chí chấp nhận

1. WHEN người dùng tạo cross-account transfer (createTransfer với destAccountId khác sourceAccountId), THE TransactionService SHALL sử dụng Firestore_Transaction thay vì WriteBatch
2. WHEN thực hiện cross-account transfer, THE TransactionService SHALL đọc Wallet_Balance của cả source và destination wallet bên trong Firestore_Transaction trước khi cập nhật
3. WHEN người dùng tạo funded expense (createWithFunding), THE TransactionService SHALL sử dụng Firestore_Transaction thay vì WriteBatch, đọc Wallet_Balance bên trong transaction
4. IF Firestore_Transaction thất bại, THEN THE TransactionService SHALL rollback toàn bộ và không có document nào bị thay đổi

### Yêu cầu 4: Loại bỏ transfers_v2 collection dư thừa

**User Story:** Là một developer, tôi muốn loại bỏ transfers_v2 collection dư thừa vì TransactionService đã lưu transfer data trong transactions collection, để tránh dữ liệu bị lệch giữa hai nơi.

#### Tiêu chí chấp nhận

1. THE TransferService SHALL không còn ghi dữ liệu vào transfers_v2 collection
2. THE TransferRepository SHALL không còn đọc dữ liệu từ transfers_v2 collection
3. WHEN cần truy vấn lịch sử chuyển khoản, THE TransactionService SHALL cung cấp query từ transactions collection với type transfer_out hoặc transfer_in
4. THE Security_Rules SHALL khóa transfers_v2 collection bằng cách đặt `allow read, write: if false`
5. THE TransferService SHALL chỉ giữ lại chức năng quản lý transfer_shortcuts (nếu vẫn được sử dụng)

### Yêu cầu 5: Sửa validate field trong transfer_shortcuts rule

**User Story:** Là một developer, tôi muốn security rule của transfer_shortcuts validate đúng field name mà model sử dụng, để rule không block các request hợp lệ.

#### Tiêu chí chấp nhận

1. THE Security_Rules SHALL validate `request.resource.data.name` thay vì `request.resource.data.label` trong create rule của transfer_shortcuts collection

### Yêu cầu 6: Validate created_by khi tạo debts và goals

**User Story:** Là một developer, tôi muốn security rules enforce rằng created_by phải bằng auth.uid khi tạo debts_v2 và goals_v2, để ngăn người dùng tạo document với created_by của người khác.

#### Tiêu chí chấp nhận

1. WHEN tạo document trong debts_v2, THE Security_Rules SHALL yêu cầu `request.resource.data.created_by == request.auth.uid`
2. WHEN tạo document trong goals_v2, THE Security_Rules SHALL yêu cầu `request.resource.data.created_by == request.auth.uid`

### Yêu cầu 7: Validate wallet_id trong transaction rules

**User Story:** Là một developer, tôi muốn security rules validate rằng wallet_id là string không rỗng khi tạo hoặc cập nhật transaction, để ngăn dữ liệu không hợp lệ.

#### Tiêu chí chấp nhận

1. WHEN tạo transaction, THE Security_Rules SHALL yêu cầu `wallet_id` là string có độ dài lớn hơn 0
2. WHEN cập nhật transaction, THE Security_Rules SHALL yêu cầu `wallet_id` là string có độ dài lớn hơn 0

### Yêu cầu 8: Thêm composite index cho debts_v2 queries

**User Story:** Là một developer, tôi muốn có đúng composite indexes cho các query debts_v2, để Firestore không reject query do thiếu index.

#### Tiêu chí chấp nhận

1. THE Composite_Index cho getDebtsByType SHALL bao gồm các fields: created_by (ASC), type (ASC), status (ASC), created_at (DESC)
2. THE Composite_Index cho getOverdueDebts SHALL bao gồm các fields: created_by (ASC), status (ASC), due_date (ASC)

### Yêu cầu 9: Loại bỏ index dư cho contributions và payments subcollections

**User Story:** Là một developer, tôi muốn loại bỏ các composite index không cần thiết cho contributions và payments subcollections, vì query đã được scope bởi parent document và không cần filter theo goal_id hoặc debt_id.

#### Tiêu chí chấp nhận

1. THE Composite_Index cho contributions với fields (goal_id, date) SHALL bị loại bỏ khỏi firestore.indexes.json
2. THE Composite_Index cho payments với fields (debt_id, date) SHALL bị loại bỏ khỏi firestore.indexes.json

### Yêu cầu 10: acceptInvite atomic với WriteBatch

**User Story:** Là một người dùng, tôi muốn khi chấp nhận lời mời, hệ thống cập nhật account.member_ids, user.account_ids và invite.status trong một thao tác atomic, để tránh trạng thái không nhất quán.

#### Tiêu chí chấp nhận

1. WHEN người dùng chấp nhận lời mời (acceptInvite), THE AccountService SHALL thực hiện cả 3 writes (update account.member_ids, update user.account_ids, update invite.status) trong một WriteBatch duy nhất
2. IF WriteBatch thất bại, THEN THE AccountService SHALL rollback toàn bộ và không có document nào bị thay đổi

### Yêu cầu 11: deleteFamily và deleteAccount xóa đầy đủ subcollections

**User Story:** Là một developer, tôi muốn deleteFamily và deleteAccount xóa tất cả subcollections liên quan, để không còn dữ liệu orphan sau khi xóa.

#### Tiêu chí chấp nhận

1. WHEN xóa family account (deleteFamily), THE AccountService SHALL xóa tất cả subcollections: wallets, transactions, categories, activities, budgets, debts_v2, goals_v2, auto_saving_rules, transfers_v2, transfer_shortcuts, recurring_rules, notification_events
2. WHEN xóa account (deleteAccount), THE AccountService SHALL xóa tất cả subcollections: wallets, transactions, categories, activities, budgets, debts_v2, goals_v2, auto_saving_rules, transfers_v2, transfer_shortcuts, recurring_rules, notification_events

### Yêu cầu 12: Khóa legacy debts collection

**User Story:** Là một developer, tôi muốn khóa legacy debts collection (đã migrate sang debts_v2), để ngăn mọi truy cập vào dữ liệu cũ.

#### Tiêu chí chấp nhận

1. THE Security_Rules SHALL đặt `allow read, write: if false` cho debts collection và payments subcollection của debts

### Yêu cầu 13: Loại bỏ wallets/goals subcollection rules dư

**User Story:** Là một developer, tôi muốn loại bỏ hoặc khóa rules cho wallets/{walletId}/goals subcollection vì code đã dùng goals_v2 collection, để tránh nhầm lẫn.

#### Tiêu chí chấp nhận

1. THE Security_Rules SHALL đặt `allow read, write: if false` cho wallets/{walletId}/goals/{goalId} subcollection
