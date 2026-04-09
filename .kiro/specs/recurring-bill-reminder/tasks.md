# Implementation Plan: Recurring Bill Reminder

## Tổng quan

Triển khai chức năng nhắc nhở thanh toán định kỳ theo thứ tự: mở rộng model → service logic → UI widget → tích hợp Home Screen. Mỗi bước build trên bước trước, test đi kèm implementation.

## Tasks

- [x] 1. Mở rộng RecurringRule model và serialization
  - [x] 1.1 Thêm trường `linkedDebtId` và `linkedGoalId` vào `RecurringRule` model
    - Thêm 2 optional fields vào class `RecurringRule` trong `lib/features/recurring/models/recurring_rule.dart`
    - Cập nhật constructor, `toMap()`, `fromMap()` để hỗ trợ `linked_debt_id` và `linked_goal_id`
    - _Requirements: 1.1, 1.2_
  - [x] 1.2 Thêm hàm validation mutual exclusion
    - Tạo hàm `validateLinkedEntity()` trả về error message nếu cả linkedDebtId và linkedGoalId đều non-null
    - _Requirements: 1.4_
  - [ ]* 1.3 Write property test cho RecurringRule serialization round-trip
    - **Property 1: RecurringRule serialization round-trip**
    - **Validates: Requirements 1.1, 1.2**
  - [ ]* 1.4 Write property test cho mutual exclusion validation
    - **Property 2: Mutual exclusion — linkedDebtId và linkedGoalId**
    - **Validates: Requirements 1.4**

- [x] 2. Tạo BillReminderService và PaymentResult model
  - [x] 2.1 Tạo `PaymentResult` model
    - Tạo file `lib/features/recurring/models/payment_result.dart`
    - Chứa: transactionId, previousNextRunAt, ruleId, linkedDebtId, linkedGoalId, amount
    - _Requirements: 6.2_
  - [x] 2.2 Tạo `BillReminderService` với `getDueReminders()` và `watchDueReminders()`
    - Tạo file `lib/features/recurring/services/bill_reminder_service.dart`
    - `getDueReminders()`: query RecurringRuleRepository.getDueRules(now), sort by nextRunAt ascending
    - `watchDueReminders()`: stream wrapper cho realtime updates
    - _Requirements: 2.1, 2.2, 2.3_
  - [x] 2.3 Implement `payBill(RecurringRule rule)` trong BillReminderService
    - Tạo transaction qua TransactionService.createTransaction()
    - Cập nhật nextRunAt qua RecurringService.updateRule()
    - Nếu có linkedDebtId: gọi DebtService.traNop() để cập nhật Debt
    - Nếu có linkedGoalId: gọi GoalService.napVaoMucTieu() để cập nhật Goal
    - Trả về PaymentResult
    - _Requirements: 4.1, 4.2, 4.4, 4.5_
  - [x] 2.4 Implement `dismissBill(RecurringRule rule)` trong BillReminderService
    - Chỉ cập nhật nextRunAt sang chu kỳ tiếp theo, không tạo giao dịch
    - _Requirements: 5.1_
  - [x] 2.5 Implement `undoPayment(PaymentResult result)` trong BillReminderService
    - Xóa transaction qua TransactionService.deleteTransaction()
    - Khôi phục nextRunAt về previousNextRunAt
    - Hoàn tác Debt/Goal nếu có
    - _Requirements: 6.2_
  - [ ]* 2.6 Write property test cho getDueReminders filter and sort
    - **Property 3: Due reminders filter and sort**
    - **Validates: Requirements 2.1, 2.2**
  - [ ]* 2.7 Write property test cho calcNextRun
    - **Property 4: calcNextRun tính đúng chu kỳ tiếp theo**
    - **Validates: Requirements 4.2**
  - [ ]* 2.8 Write property test cho dismissBill
    - **Property 8: dismissBill chỉ cập nhật nextRunAt, không tạo giao dịch**
    - **Validates: Requirements 5.1**

- [ ] 3. Checkpoint - Đảm bảo tất cả tests pass
  - Chạy tất cả tests, hỏi user nếu có thắc mắc.

- [x] 4. Tạo BillReminderWidget UI
  - [x] 4.1 Tạo `BillReminderWidget`
    - Tạo file `lib/features/recurring/widgets/bill_reminder_widget.dart`
    - Card nổi bật với icon cảnh báo, danh sách các khoản đến hạn
    - Mỗi item hiển thị: tên ghi chú/danh mục, số tiền, tên ví
    - Tap vào item = gọi onPay callback
    - Swipe dismiss = gọi onDismiss callback
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_
  - [ ]* 4.2 Write widget test cho BillReminderWidget
    - Test hiển thị đúng khi có reminders
    - Test ẩn khi danh sách rỗng
    - Test tap gọi onPay
    - Test swipe gọi onDismiss
    - _Requirements: 3.1, 3.4, 4.1, 5.1_

- [x] 5. Tích hợp vào Home Screen
  - [x] 5.1 Thêm BillReminderWidget vào HomeScreen
    - Thêm StreamBuilder lắng nghe `watchDueReminders()` trong HomeScreen
    - Đặt BillReminderWidget phía trên `_buildTodayTotal()` trong ListView
    - Xử lý onPay: gọi BillReminderService.payBill(), hiển thị snackbar với nút Undo
    - Xử lý onDismiss: gọi BillReminderService.dismissBill()
    - Xử lý Undo: gọi BillReminderService.undoPayment()
    - _Requirements: 3.1, 4.1, 4.3, 5.1, 5.2, 6.1, 6.2_
  - [x] 5.2 Đăng ký BillReminderService vào ServiceLocator
    - Thêm BillReminderService vào service_locator.dart
    - _Requirements: 2.1_

- [x] 6. Mở rộng RecurringFormScreen
  - [x] 6.1 Thêm phần chọn liên kết Debt/Goal vào RecurringFormScreen
    - Thêm dropdown "Liên kết với": Không / Khoản nợ / Mục tiêu
    - Load danh sách Debt active và Goal active
    - Hiển thị dropdown phụ tương ứng khi chọn loại liên kết
    - Validation: gọi validateLinkedEntity() trước khi save
    - Lưu linkedDebtId/linkedGoalId vào RecurringRule khi tạo/cập nhật
    - _Requirements: 1.3, 1.4_

- [ ] 7. Final checkpoint - Đảm bảo tất cả tests pass
  - Chạy tất cả tests, hỏi user nếu có thắc mắc.

## Ghi chú

- Tasks đánh dấu `*` là optional, có thể bỏ qua để tập trung vào core features trước
- Mỗi task tham chiếu đến requirements cụ thể để truy vết
- Checkpoints đảm bảo validation từng giai đoạn
- Property tests kiểm tra tính đúng đắn tổng quát, unit/widget tests kiểm tra edge cases cụ thể
