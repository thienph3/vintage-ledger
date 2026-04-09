# Implementation Plan: Goal Earmark Balance & Wallet Types

## Tổng quan

Triển khai cơ chế earmark balance cho mục tiêu tiết kiệm và hệ thống phân loại ví (normal/saving/debt). Các task được sắp xếp theo thứ tự: model → service → repository → UI, đảm bảo mỗi bước build trên bước trước.

## Tasks

- [x] 1. Cập nhật Wallet Model với WalletType
  - [x] 1.1 Thêm enum `WalletType` (normal, saving, debt) với `displayName` và `emoji` vào `lib/features/wallet/models/wallet.dart`, thêm trường `type` vào class `Wallet` với default `WalletType.normal`, cập nhật `copyWith` và `==`/`hashCode`
    - _Requirements: 9.1, 9.4_
  - [x] 1.2 Cập nhật `WalletRepository.fromFirestore` và `toFirestore` để serialize/deserialize trường `type`, backward compatible (ví cũ không có `type` → default `normal`)
    - _Requirements: 9.4_
  - [ ]* 1.3 Viết property test cho Wallet type serialization round-trip
    - **Property 9: Wallet type serialization round-trip**
    - **Validates: Requirements 9.1, 9.4**

- [x] 2. Thêm query goal theo wallet vào GoalRepository
  - [x] 2.1 Thêm `getActiveGoalsByWallet(String walletId)` và `watchActiveGoalsByWallet(String walletId)` vào `GoalRepository`, query theo `funding_wallet_id` + `status == active`
    - _Requirements: 3.1, 3.2_

- [x] 3. Refactor GoalService — loại bỏ transaction và thêm earmark logic
  - [x] 3.1 Refactor `napVaoMucTieu`: bỏ tạo transaction, bỏ thay đổi wallet balance, bỏ gọi `ensureSystemCategory`. Chỉ: validate amount > 0 và amount <= availableBalance, cập nhật `goal.currentAmount`, tạo contribution record, auto-complete nếu đạt target. Tất cả trong Firestore transaction
    - _Requirements: 1.1, 1.2, 1.3, 4.1, 4.2, 4.3, 8.1, 8.2_
  - [x] 3.2 Refactor `rutTuMucTieu`: bỏ tạo transaction, bỏ thay đổi wallet balance, bỏ gọi `ensureSystemCategory`. Chỉ: validate amount > 0 và amount <= currentAmount, giảm `goal.currentAmount`, tạo contribution âm. Tất cả trong Firestore transaction
    - _Requirements: 2.1, 2.2, 2.3, 8.1, 8.2_
  - [x] 3.3 Thêm `getEarmarkedAmount(String walletId)` và `watchEarmarkedAmount(String walletId)` — tính tổng `currentAmount` của goals active theo walletId
    - _Requirements: 3.1, 3.2, 3.3_
  - [x] 3.4 Thêm `getGoalsByWallet(String walletId)` và `watchGoalsByWallet(String walletId)` delegate tới repository
    - _Requirements: 5.3, 10.3_
  - [x] 3.5 Cập nhật `cancelGoal`: đặt `currentAmount = 0` trước khi set status cancelled
    - _Requirements: 6.1, 6.3_
  - [ ]* 3.6 Viết property test: goal operations không ảnh hưởng wallet balance
    - **Property 1: Goal operations không ảnh hưởng wallet balance và không tạo transaction**
    - **Validates: Requirements 1.1, 1.2, 2.1, 2.2, 6.3**
  - [ ]* 3.7 Viết property test: nạp tiền tăng currentAmount đúng
    - **Property 2: Nạp tiền tăng currentAmount đúng số tiền**
    - **Validates: Requirements 1.1**
  - [ ]* 3.8 Viết property test: rút tiền giảm currentAmount đúng
    - **Property 3: Rút tiền giảm currentAmount đúng số tiền**
    - **Validates: Requirements 2.1**
  - [ ]* 3.9 Viết property test: auto-complete khi đạt target
    - **Property 4: Mục tiêu tự động hoàn thành khi đạt target**
    - **Validates: Requirements 1.3**
  - [ ]* 3.10 Viết property test: earmarked amount tính đúng
    - **Property 5: Earmarked amount và available balance tính đúng**
    - **Validates: Requirements 3.1, 3.2, 3.3**
  - [ ]* 3.11 Viết property test: nạp tiền không hợp lệ bị từ chối
    - **Property 6: Nạp tiền không hợp lệ bị từ chối và không thay đổi state**
    - **Validates: Requirements 4.1, 4.2, 4.3**
  - [ ]* 3.12 Viết property test: rút tiền vượt currentAmount bị từ chối
    - **Property 7: Rút tiền vượt quá currentAmount bị từ chối**
    - **Validates: Requirements 2.3**
  - [ ]* 3.13 Viết property test: hủy mục tiêu giải phóng earmark
    - **Property 8: Hủy mục tiêu giải phóng earmark**
    - **Validates: Requirements 6.1**

- [ ] 4. Checkpoint — Đảm bảo tất cả tests pass
  - Đảm bảo tất cả tests pass, hỏi user nếu có thắc mắc.

- [x] 5. Cập nhật WalletFormScreen — cho phép chọn loại ví
  - [x] 5.1 Thêm dropdown chọn `WalletType` vào `WalletFormScreen`, default `normal`. Truyền `type` khi gọi `createWallet` và `updateWallet`
    - _Requirements: 9.2, 9.3_
  - [x] 5.2 Cập nhật `WalletService.createWallet` để nhận và lưu `type` parameter
    - _Requirements: 9.1_

- [x] 6. Cập nhật WalletDetailScreen — hiển thị earmark info và FAB theo type
  - [x] 6.1 Cập nhật balance card: khi ví có goal active liên kết, hiển thị tổng số dư, earmarked amount, available balance. Khi không có goal, giữ nguyên hiển thị hiện tại
    - _Requirements: 5.1, 5.2_
  - [x] 6.2 Thêm section danh sách mục tiêu liên kết (dùng `watchGoalsByWallet`) phía trên recent transactions, chỉ hiển thị khi ví có goal active
    - _Requirements: 5.3, 10.3_
  - [x] 6.3 Thêm FAB nạp mục tiêu cho ví type `saving`, điều hướng đến `GoalContributionScreen`
    - _Requirements: 10.1, 10.2_
  - [x] 6.4 Thêm FAB trả nợ cho ví type `debt`, tạo giao dịch chi tiêu với category `debt_payment`
    - _Requirements: 11.1, 11.2_
  - [x] 6.5 Cập nhật balance card cho ví debt: hiển thị nợ ban đầu và nợ còn lại
    - _Requirements: 11.3_

- [x] 7. Cập nhật WalletListScreen — hiển thị available balance và debt info
  - [x] 7.1 Cập nhật wallet list item: khi ví có goal active, hiển thị thêm dòng available balance bên dưới tổng balance
    - _Requirements: 5.4, 5.5_
  - [x] 7.2 Cập nhật wallet list item cho ví debt: hiển thị số nợ còn lại với màu đỏ
    - _Requirements: 11.4_

- [x] 8. Cập nhật GoalContributionScreen — hiển thị available balance
  - [x] 8.1 Khi chọn mục tiêu, fetch và hiển thị available balance của ví liên kết. Disable nút nạp và hiển thị cảnh báo khi số tiền nhập vượt quá available balance
    - _Requirements: 7.1, 7.2_

- [ ] 9. Final checkpoint — Đảm bảo tất cả tests pass
  - Đảm bảo tất cả tests pass, hỏi user nếu có thắc mắc.

## Ghi chú

- Tasks đánh dấu `*` là optional, có thể bỏ qua để tập trung vào core features trước
- Mỗi task tham chiếu đến requirements cụ thể để traceability
- Property tests validate tính đúng đắn tổng quát, unit tests validate ví dụ cụ thể và edge cases
- Không cần migration Firestore — tất cả thay đổi backward compatible
