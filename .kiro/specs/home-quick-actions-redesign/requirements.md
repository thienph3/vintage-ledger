# Requirements Document

## Introduction

Thiết kế lại danh sách các nút hành động trong QuickActionsFab trên tab Home của ứng dụng Vintage Ledger. Hiện tại FAB luôn hiển thị cố định 4 nút bất kể ngữ cảnh. Yêu cầu mới là thay đổi danh sách nút thành context-aware: chỉ hiển thị các nút phù hợp với trạng thái dữ liệu hiện tại (loại tài khoản, số ví, mục tiêu tiết kiệm, khoản nợ). Nút "Thêm thu chi" sẽ bị loại bỏ khỏi FAB vì đã có QuickAddBar ở cuối màn hình Home.

## Glossary

- **Home_Screen**: Màn hình chính (tab Home) của ứng dụng, hiển thị tổng quan chi tiêu hôm nay và danh sách giao dịch gần đây
- **QuickActionsFab**: Widget FAB (Floating Action Button) mở rộng ở góc dưới phải Home_Screen, khi nhấn sẽ hiển thị danh sách các nút hành động
- **Account**: Tài khoản người dùng, có thuộc tính `type` là `personal` hoặc `family`
- **Wallet**: Ví tiền thuộc một Account, chứa số dư và tiền tệ
- **Goal**: Mục tiêu tiết kiệm, có trạng thái active/paused/completed/cancelled
- **Debt**: Khoản nợ (cho vay hoặc vay mượn), có trạng thái active/completed/cancelled
- **Visibility_Logic**: Logic xác định nút nào được hiển thị trong QuickActionsFab dựa trên ngữ cảnh dữ liệu hiện tại
- **QuickAddBar**: Thanh nhập nhanh giao dịch ở cuối Home_Screen, đã hỗ trợ thêm thu chi nên FAB không cần nút này

## Requirements

### Requirement 1: Loại bỏ nút "Thêm thu chi" khỏi FAB

**User Story:** Là người dùng, tôi không cần nút thêm thu chi trong FAB vì đã có QuickAddBar ở cuối màn hình Home để nhập giao dịch nhanh.

#### Acceptance Criteria

1. THE QuickActionsFab SHALL NOT include an "Thêm thu chi" (Add Transaction) button in its action list

### Requirement 2: Hiển thị nút "Nạp tiền vào ví" theo ngữ cảnh

**User Story:** Là người dùng tài khoản gia đình, tôi muốn thấy nút nạp tiền vào ví gia đình trong FAB, để tôi có thể nạp tiền nhanh từ ví cá nhân vào ví gia đình.

#### Acceptance Criteria

1. WHILE the current Account type is "family", THE QuickActionsFab SHALL display a "Nạp tiền vào ví" button
2. WHILE the current Account type is "personal", THE QuickActionsFab SHALL hide the "Nạp tiền vào ví" button
3. WHEN the user taps the "Nạp tiền vào ví" button, THE QuickActionsFab SHALL navigate to the TransferScreen

### Requirement 3: Hiển thị nút "Chuyển tiền" theo ngữ cảnh

**User Story:** Là người dùng có nhiều ví, tôi muốn thấy nút chuyển tiền giữa các ví trong FAB, để tôi có thể chuyển tiền nhanh giữa các ví.

#### Acceptance Criteria

1. WHILE the current Account has 2 or more Wallet entities, THE QuickActionsFab SHALL display a "Chuyển tiền" button
2. WHILE the current Account has fewer than 2 Wallet entities, THE QuickActionsFab SHALL hide the "Chuyển tiền" button
3. WHEN the user taps the "Chuyển tiền" button, THE QuickActionsFab SHALL navigate to the TransferScreen

### Requirement 4: Hiển thị nút "Tiết kiệm" theo ngữ cảnh

**User Story:** Là người dùng có mục tiêu tiết kiệm đang hoạt động, tôi muốn thấy nút nạp tiết kiệm trong FAB, để tôi có thể đóng góp vào mục tiêu nhanh chóng.

#### Acceptance Criteria

1. WHILE the current Account has at least one Goal with status "active", THE QuickActionsFab SHALL display a "Tiết kiệm" button
2. WHILE the current Account has zero active Goal entities, THE QuickActionsFab SHALL hide the "Tiết kiệm" button
3. WHEN the user taps the "Tiết kiệm" button, THE QuickActionsFab SHALL navigate to the GoalContributionScreen

### Requirement 5: Hiển thị nút "Trả nợ" theo ngữ cảnh

**User Story:** Là người dùng có khoản nợ đang hoạt động, tôi muốn thấy nút trả nợ trong FAB, để tôi có thể thanh toán nợ nhanh chóng.

#### Acceptance Criteria

1. WHILE the current Account has at least one Debt with status "active", THE QuickActionsFab SHALL display a "Trả nợ" button
2. WHILE the current Account has zero active Debt entities, THE QuickActionsFab SHALL hide the "Trả nợ" button
3. WHEN the user taps the "Trả nợ" button, THE QuickActionsFab SHALL navigate to the DebtPaymentScreen

### Requirement 6: Cập nhật danh sách nút theo thời gian thực

**User Story:** Là người dùng, tôi muốn danh sách nút trong FAB tự động cập nhật khi dữ liệu thay đổi (thêm/xóa ví, tạo/hoàn thành mục tiêu, tạo/hoàn thành nợ), để FAB luôn phản ánh đúng ngữ cảnh hiện tại.

#### Acceptance Criteria

1. WHEN the number of Wallet entities changes, THE QuickActionsFab SHALL update the visibility of the "Chuyển tiền" button accordingly
2. WHEN a Goal status changes to or from "active", THE QuickActionsFab SHALL update the visibility of the "Tiết kiệm" button accordingly
3. WHEN a Debt status changes to or from "active", THE QuickActionsFab SHALL update the visibility of the "Trả nợ" button accordingly

### Requirement 7: Xử lý trường hợp không có nút nào hiển thị

**User Story:** Là người dùng tài khoản cá nhân chỉ có 1 ví, không có mục tiêu hay nợ, tôi muốn FAB được ẩn đi thay vì hiển thị rỗng, để giao diện gọn gàng.

#### Acceptance Criteria

1. WHILE the Visibility_Logic determines zero action buttons are applicable, THE Home_Screen SHALL hide the QuickActionsFab entirely
2. WHEN at least one action button becomes applicable, THE Home_Screen SHALL show the QuickActionsFab
