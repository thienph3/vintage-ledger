# Implementation Plan: Firestore Design Fixes

## Overview

Sửa 13 vấn đề thiết kế Firestore trong vintage_ledger. Thực hiện theo thứ tự: security rules & indexes trước (ít rủi ro), sau đó atomic operations, cuối cùng loại bỏ collection dư thừa.

## Tasks

- [x] 1. Sửa Security Rules (Issues #5, #6, #7, #12, #13)
  - [x] 1.1 Sửa transfer_shortcuts rule: đổi `label` thành `name` trong create rule
    - File: `firestore.rules`, block `transfer_shortcuts/{shortcutId}`
    - Đổi `request.resource.data.label` thành `request.resource.data.name`
    - _Requirements: 5.1_
  - [x] 1.2 Thêm `created_by == request.auth.uid` vào create rules cho debts_v2 và goals_v2
    - File: `firestore.rules`, blocks `debts_v2/{debtId}` và `goals_v2/{goalId}`
    - Thêm `request.resource.data.created_by == request.auth.uid` vào điều kiện `allow create`
    - _Requirements: 6.1, 6.2_
  - [x] 1.3 Thêm validate `wallet_id` non-empty trong transaction create/update rules
    - File: `firestore.rules`, block `transactions/{docId}`
    - Thêm `request.resource.data.wallet_id is string && request.resource.data.wallet_id.size() > 0`
    - _Requirements: 7.1, 7.2_
  - [x] 1.4 Khóa legacy debts collection và wallets/goals subcollection
    - File: `firestore.rules`
    - Đổi `debts/{debtId}` và `debts/{debtId}/payments/{paymentId}` thành `allow read, write: if false`
    - Đổi `wallets/{walletId}/goals/{goalId}` thành `allow read, write: if false`
    - _Requirements: 12.1, 13.1_
  - [ ]* 1.5 Viết unit tests cho security rules changes
    - Test transfer_shortcuts create với field `name` được accept
    - Test debts_v2/goals_v2 create với sai created_by bị reject
    - Test transaction create/update với empty wallet_id bị reject
    - Test legacy debts và wallets/goals bị locked
    - **Property 5: created_by enforcement for debts_v2 and goals_v2**
    - **Property 6: wallet_id non-empty enforcement for transactions**
    - **Validates: Requirements 5.1, 6.1, 6.2, 7.1, 7.2, 12.1, 13.1**

- [x] 2. Sửa Firestore Indexes (Issues #8, #9)
  - [x] 2.1 Thêm composite index cho getDebtsByType query
    - File: `firestore.indexes.json`
    - Thêm index: debts_v2 (created_by ASC, type ASC, status ASC, created_at DESC)
    - _Requirements: 8.1_
  - [x] 2.2 Cập nhật composite index cho getOverdueDebts query
    - File: `firestore.indexes.json`
    - Sửa index debts_v2 hiện tại (created_by, due_date) thành (created_by ASC, status ASC, due_date ASC)
    - _Requirements: 8.2_
  - [x] 2.3 Loại bỏ index dư cho contributions và payments subcollections
    - File: `firestore.indexes.json`
    - Xóa index contributions (goal_id ASC, date DESC)
    - Xóa index payments (debt_id ASC, date DESC)
    - _Requirements: 9.1, 9.2_

- [x] 3. Checkpoint — Verify rules và indexes
  - Ensure firestore.rules và firestore.indexes.json hợp lệ, ask the user if questions arise.

- [x] 4. GoalService atomic operations (Issue #1)
  - [x] 4.1 Refactor `napVaoMucTieu()` dùng `runTransaction`
    - File: `lib/features/goal/services/goal_service.dart`
    - Trong một `runTransaction`: read goal + wallet, create expense txn, deduct wallet balance, create contribution, update goal.current_amount (+ status nếu completed)
    - Cần access FirebaseFirestore instance và accountId
    - _Requirements: 1.1, 1.4_
  - [x] 4.2 Refactor `rutTuMucTieu()` dùng `runTransaction`
    - File: `lib/features/goal/services/goal_service.dart`
    - Trong một `runTransaction`: read goal + wallet, create income txn, add wallet balance, create contribution (amount âm), update goal.current_amount
    - _Requirements: 1.2_
  - [ ]* 4.3 Viết property test cho goal operation balance conservation
    - **Property 1: Goal operation balance conservation**
    - **Validates: Requirements 1.1, 1.2**

- [x] 5. DebtService atomic operations (Issue #2)
  - [x] 5.1 Refactor `nhanTienTra()` dùng `runTransaction`, thêm `walletId` parameter
    - File: `lib/features/debt/services/debt_service.dart`
    - Trong một `runTransaction`: read debt + wallet, create income txn, add wallet balance, create payment, update debt.paid_amount (+ status nếu completed)
    - Thêm `required String walletId` parameter
    - _Requirements: 2.1, 2.3_
  - [x] 5.2 Refactor `traNop()` dùng `runTransaction`, thêm `walletId` parameter
    - File: `lib/features/debt/services/debt_service.dart`
    - Trong một `runTransaction`: read debt + wallet, create expense txn, deduct wallet balance, create payment, update debt.paid_amount (+ status nếu completed)
    - Thêm `required String walletId` parameter
    - _Requirements: 2.2, 2.3_
  - [x] 5.3 Cập nhật tất cả call sites của `nhanTienTra` và `traNop` để truyền `walletId`
    - Tìm tất cả nơi gọi `nhanTienTra` và `traNop`, thêm `walletId` argument
    - _Requirements: 2.1, 2.2_
  - [ ]* 5.4 Viết property test cho debt payment balance consistency
    - **Property 2: Debt payment balance consistency**
    - **Validates: Requirements 2.1, 2.2**

- [x] 6. Checkpoint — Verify goal và debt atomic operations
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. TransactionService atomic cross-account operations (Issue #3)
  - [x] 7.1 Refactor `createTransfer()` cross-account path dùng `runTransaction`
    - File: `lib/features/transaction/services/transaction_service.dart`
    - Thay `batch` bằng `runTransaction`, đọc wallet balances bên trong transaction
    - Giữ nguyên same-account path (đã dùng runTransaction)
    - _Requirements: 3.1, 3.2_
  - [x] 7.2 Refactor `createWithFunding()` dùng `runTransaction`
    - File: `lib/features/transaction/services/transaction_service.dart`
    - Thay `batch` bằng `runTransaction`, đọc wallet balance bên trong transaction
    - _Requirements: 3.3_
  - [ ]* 7.3 Viết property test cho cross-account operation balance consistency
    - **Property 3: Cross-account operation balance consistency**
    - **Validates: Requirements 3.2, 3.3**

- [x] 8. Loại bỏ transfers_v2 collection (Issue #4)
  - [x] 8.1 Refactor TransferRepository: loại bỏ `_transfers` methods, giữ lại `_shortcuts` methods
    - File: `lib/features/transfer/repositories/transfer_repository.dart`
    - Xóa: `getTransfers`, `getTransfersByType`, `getPendingTransfers`, `watchRecentTransfers`, `getTransfer`, `addTransfer`, `updateTransfer`, `deleteTransfer`
    - Giữ: `getShortcuts`, `watchShortcuts`, `addShortcut`, `deleteShortcut`
    - _Requirements: 4.1, 4.2_
  - [x] 8.2 Refactor TransferService: loại bỏ methods ghi transfers_v2, giữ shortcuts
    - File: `lib/features/transfer/services/transfer_service.dart`
    - Xóa: `chuyenGiuaCacVi`, `napVaoViGiaDinh`, `napChoChiTieu`, `guiChoThanhVien`, `getLichSuChuyenTien`, `getTransfersByType`, `getPendingTransfers`, `watchRecentTransfers`, `getTransfer`, `updateTransferStatus`, `deleteTransfer`
    - Giữ: `getQuickTransferOptions`, `watchShortcuts`, `saveTransferShortcut`, `deleteShortcut`
    - _Requirements: 4.1, 4.5_
  - [x] 8.3 Khóa transfers_v2 trong security rules
    - File: `firestore.rules`
    - Đổi `transfers_v2/{transferId}` thành `allow read, write: if false`
    - _Requirements: 4.4_
  - [x] 8.4 Xóa transfers_v2 index từ firestore.indexes.json
    - Xóa index: transfers_v2 (created_by ASC, type ASC, date DESC)
    - _Requirements: 4.4_
  - [x] 8.5 Cập nhật tất cả call sites sử dụng TransferService methods đã xóa
    - Tìm và thay thế bằng TransactionService.createTransfer() tương ứng
    - _Requirements: 4.3_
  - [ ]* 8.6 Viết unit test verify transfer history queryable từ transactions
    - **Property 4: Transfer history queryable from transactions collection**
    - **Validates: Requirements 4.3**

- [x] 9. AccountService fixes (Issues #10, #11)
  - [x] 9.1 Refactor `acceptInvite()` dùng WriteBatch
    - File: `lib/features/account/services/account_service.dart`
    - Gom 3 writes (account.member_ids, user.account_ids, invite.status) vào một `WriteBatch`
    - _Requirements: 10.1_
  - [x] 9.2 Cập nhật `deleteFamily()` xóa đầy đủ subcollections
    - File: `lib/features/account/services/account_service.dart`
    - Thêm subcollections thiếu: budgets, debts_v2, goals_v2, auto_saving_rules, transfers_v2, transfer_shortcuts, recurring_rules, notification_events
    - _Requirements: 11.1_
  - [x] 9.3 Cập nhật `deleteAccount()` xóa đầy đủ subcollections
    - File: `lib/features/account/services/account_service.dart`
    - Thêm subcollections thiếu: debts_v2, goals_v2, auto_saving_rules, transfers_v2, transfer_shortcuts, recurring_rules
    - _Requirements: 11.2_
  - [ ]* 9.4 Viết unit tests cho acceptInvite atomicity và deletion completeness
    - **Property 7: acceptInvite atomicity**
    - **Property 8: Account deletion completeness**
    - **Validates: Requirements 10.1, 11.1, 11.2**

- [x] 10. Final checkpoint — Verify toàn bộ
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
