# Kế hoạch Triển khai: Nợ Liên kết (Linked Debt)

## Tổng quan

Triển khai tính năng nợ liên kết theo thiết kế, bắt đầu từ mở rộng model, service, rồi UI. Mỗi bước xây dựng trên bước trước và kết thúc bằng tích hợp toàn bộ.

## Tasks

- [x] 1. Mở rộng Debt Model
  - [x] 1.1 Thêm 3 trường nullable mới vào class Debt
    - Thêm `linkedDebtId` (String?), `linkedAccountId` (String?), `partyUserId` (String?) vào class `Debt` tại `lib/features/debt/models/debt.dart`
    - Cập nhật constructor, `fromMap()`, `toMap()`, `copyWith()`, `toString()`
    - Thêm computed property `isLinked` trả về `linkedDebtId != null`
    - Đảm bảo `fromMap()` gán null khi document cũ không có các trường mới (backward compatible)
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

  - [ ]* 1.2 Viết property test cho Debt model serialization
    - **Property 8: Round-trip serialization của Debt model**
    - Generate random Debt objects (có và không có trường liên kết), verify `Debt.fromMap(id, debt.toMap())` tương đương
    - **Validates: Requirements 7.2**

  - [ ]* 1.3 Viết property test cho isLinked computed property
    - **Property 9: isLinked computed property**
    - Generate random Debt objects, verify `debt.isLinked == (debt.linkedDebtId != null)`
    - **Validates: Requirements 7.4**

- [x] 2. Mở rộng AccountService — expose findUserIdByEmail
  - [x] 2.1 Đổi `_findUserIdByEmail` thành public method `findUserIdByEmail`
    - Tại `lib/features/account/services/account_service.dart`, đổi tên method từ `_findUserIdByEmail` thành `findUserIdByEmail`
    - Cập nhật tất cả call sites hiện tại (sendInviteByEmail) để dùng tên mới
    - Thêm method `getAccountNameForUser(String userId)` để lấy tên account/user hiển thị
    - _Requirements: 1.1_

- [x] 3. Mở rộng NotificationService — thêm notification cho nợ liên kết
  - [x] 3.1 Thêm 3 method notification mới vào NotificationService
    - Tại `lib/features/notification/services/notification_service.dart`, thêm:
      - `notifyDebtCreated({targetUserId, creatorName, amount, debtType})`
      - `notifyDebtPayment({targetUserId, payerName, amount, remainingAmount})`
      - `notifyDebtCompleted({targetUserId, partyName, totalAmount})`
    - Sử dụng pattern hiện có: `_getTokensForUsers()` → `_sendPush()`
    - Nội dung tiếng Việt phù hợp
    - _Requirements: 4.1, 4.2, 4.3_

- [x] 4. Mở rộng DebtService — tạo nợ liên kết
  - [x] 4.1 Implement `choVayLienKet()` và `vayMuonLienKet()` trong DebtService
    - Tại `lib/features/debt/services/debt_service.dart`, thêm 2 method mới
    - Sử dụng Firestore transaction để tạo đồng thời 2 document nợ (theo pattern của `createTransfer`)
    - Pre-generate 2 doc refs trong 2 account subcollections
    - Set `linkedDebtId`, `linkedAccountId`, `partyUserId` trên cả 2 documents
    - Đảm bảo type đảo ngược (lend ↔ borrow)
    - Đảm bảo `totalAmount`, `dueDate`, `interestRate`, `description` giống nhau
    - Gọi `notifyDebtCreated()` sau khi transaction thành công
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

  - [ ]* 4.2 Viết property test cho type inversion
    - **Property 3: Cặp nợ liên kết có type đảo ngược**
    - **Validates: Requirements 2.1, 2.2**

  - [ ]* 4.3 Viết property test cho cross-references
    - **Property 4: Cặp nợ liên kết có tham chiếu chéo đúng**
    - **Validates: Requirements 2.3, 2.4**

  - [ ]* 4.4 Viết property test cho shared fields
    - **Property 5: Cặp nợ liên kết có các trường chia sẻ bằng nhau**
    - **Validates: Requirements 2.5**

- [x] 5. Checkpoint — Đảm bảo tất cả tests pass
  - Đảm bảo tất cả tests pass, hỏi người dùng nếu có thắc mắc.

- [x] 6. Mở rộng DebtService — đồng bộ thanh toán
  - [x] 6.1 Mở rộng `nhanTienTra()` để đồng bộ nợ liên kết
    - Trong Firestore transaction hiện tại, thêm logic:
      - Đọc debt doc → kiểm tra `linkedDebtId`
      - Nếu `isLinked`: đọc linked debt doc, cập nhật `paidAmount` và `status` trên cả 2
      - Nếu linked debt doc không tồn tại: gỡ liên kết, tiếp tục bình thường
      - Gọi `notifyDebtPayment()` hoặc `notifyDebtCompleted()` sau transaction
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

  - [x] 6.2 Mở rộng `traNop()` để đồng bộ nợ liên kết
    - Tương tự 6.1 nhưng cho luồng trả nợ (borrow)
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

  - [ ]* 6.3 Viết property test cho đồng bộ thanh toán
    - **Property 6: Đồng bộ thanh toán — paidAmount và status nhất quán**
    - **Validates: Requirements 3.1, 3.2**

- [x] 7. Mở rộng DebtService — hủy và xóa nợ liên kết
  - [x] 7.1 Mở rộng `cancelDebt()` để gỡ liên kết
    - Đọc debt doc → kiểm tra `linkedDebtId`
    - Nếu `isLinked`: dùng Firestore transaction để cập nhật status "cancelled" trên bên hiện tại VÀ xóa `linked_debt_id`, `linked_account_id` trên document bên kia
    - Nếu linked debt doc không tồn tại: tiếp tục cancel bình thường
    - Gửi notification đến đối tác
    - _Requirements: 6.1, 6.2, 6.4_

  - [x] 7.2 Mở rộng `deleteDebt()` để gỡ liên kết
    - Tương tự 7.1: đọc debt doc trước khi xóa, gỡ liên kết trên document bên kia
    - Sử dụng Firestore batch/transaction
    - _Requirements: 6.3, 6.4_

  - [ ]* 7.3 Viết property test cho hủy/xóa gỡ liên kết
    - **Property 7: Hủy/xóa gỡ liên kết bên kia**
    - **Validates: Requirements 6.1, 6.3**

- [x] 8. Checkpoint — Đảm bảo tất cả tests pass
  - Đảm bảo tất cả tests pass, hỏi người dùng nếu có thắc mắc.

- [x] 9. Mở rộng DebtFormScreen — UI tìm kiếm người dùng
  - [x] 9.1 Thêm toggle chọn loại đối tác trên DebtFormScreen
    - Tại `lib/features/debt/screens/debt_form_screen.dart`, thêm SegmentedButton hoặc Radio cho 2 lựa chọn: "Nhập tên" (free-text, mặc định) và "Tìm người dùng" (email)
    - Khi chọn "Nhập tên": giữ nguyên UI hiện tại (partyName text field)
    - Khi chọn "Tìm người dùng": hiển thị email input field + nút tìm kiếm
    - _Requirements: 1.1, 1.2_

  - [x] 9.2 Implement logic tìm kiếm email và hiển thị kết quả
    - Gọi `AccountService.findUserIdByEmail(email)` khi người dùng nhấn tìm
    - Hiển thị tên người dùng khi tìm thấy, lưu `partyUserId` và `partyAccountId` vào state
    - Hiển thị lỗi khi không tìm thấy, cho phép quay lại nhập tên free-text
    - Validate: từ chối email trùng với chính mình
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

  - [x] 9.3 Cập nhật logic submit form để gọi method liên kết
    - Khi đối tác là người dùng trong app: gọi `choVayLienKet()` hoặc `vayMuonLienKet()`
    - Khi đối tác là free-text: gọi `choVay()` hoặc `vayMuon()` (hành vi hiện tại)
    - _Requirements: 2.1, 2.2, 5.1_

- [x] 10. Mở rộng DebtDetailScreen — hiển thị thông tin liên kết
  - [x] 10.1 Thêm chỉ báo nợ liên kết trên DebtDetailScreen
    - Tại `lib/features/debt/screens/debt_detail_screen.dart`, hiển thị badge/icon khi `debt.isLinked`
    - Hiển thị trạng thái liên kết (đang liên kết / đã gỡ liên kết)
    - _Requirements: 5.3_

- [x] 11. Checkpoint cuối — Đảm bảo tất cả tests pass
  - Đảm bảo tất cả tests pass, hỏi người dùng nếu có thắc mắc.

## Ghi chú

- Tasks đánh dấu `*` là tùy chọn và có thể bỏ qua để tập trung vào tính năng cốt lõi trước
- Mỗi task tham chiếu đến requirements cụ thể để đảm bảo truy vết
- Checkpoints đảm bảo kiểm tra tăng dần
- Property tests kiểm tra tính đúng đắn phổ quát
- Unit tests kiểm tra các ví dụ cụ thể và edge cases
