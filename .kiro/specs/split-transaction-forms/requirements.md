# Requirements Document

## Introduction

Tách màn hình TransactionFormScreen hiện tại (monolithic) thành các màn hình form riêng biệt cho từng kịch bản: thêm thu chi (income/expense), nạp tiền (funding), và chuyển tiền (transfer). Hiện tại TransactionFormScreen xử lý cả 3 kịch bản bằng conditional logic dựa trên TransactionType, dẫn đến code phức tạp và khó bảo trì. Việc tách form cho phép QuickActionsFab và QuickAddBar điều hướng trực tiếp đến đúng form, đồng thời loại bỏ TransferScreen cũ (đang trùng lặp chức năng).

## Glossary

- **TransactionFormScreen**: Màn hình form monolithic hiện tại xử lý cả thu chi, chuyển tiền và nạp tiền
- **IncomeExpenseFormScreen**: Màn hình form mới chuyên xử lý thêm/sửa giao dịch thu nhập và chi tiêu
- **TransferFormScreen**: Màn hình form mới chuyên xử lý chuyển tiền giữa các ví (internal và cross-account)
- **FundingFormScreen**: Màn hình form mới chuyên xử lý nạp tiền từ ví cá nhân vào ví gia đình
- **QuickActionsFab**: Widget FAB trên Home_Screen, điều hướng đến các hành động nhanh
- **QuickAddBar**: Thanh nhập nhanh giao dịch ở cuối Home_Screen
- **TransactionType**: Enum phân loại giao dịch: income, expense, transferOut, transferIn
- **TransferType**: Enum phân loại chuyển khoản: internal, funding, crossAccount
- **Wallet**: Ví tiền thuộc một Account
- **Category**: Danh mục phân loại giao dịch thu chi
- **TransactionWithItems**: Model chứa giao dịch kèm danh sách line items
- **BudgetStatus**: Trạng thái ngân sách cho danh mục chi tiêu
- **TransferScreen**: Màn hình chuyển tiền cũ (sẽ bị loại bỏ sau khi tách form)

## Requirements

### Requirement 1: Tạo IncomeExpenseFormScreen cho giao dịch thu chi

**User Story:** Là người dùng, tôi muốn có một màn hình form chuyên biệt để thêm và sửa giao dịch thu nhập/chi tiêu, để trải nghiệm nhập liệu tập trung và không bị lẫn với các trường không liên quan.

#### Acceptance Criteria

1. THE IncomeExpenseFormScreen SHALL display fields for amount, wallet selection, category selection, date, line items, and note
2. WHEN the user switches between income and expense type, THE IncomeExpenseFormScreen SHALL reload the category list filtered by the selected type
3. WHEN the user selects an expense category, THE IncomeExpenseFormScreen SHALL check and display the budget status for that category
4. WHEN the user submits a valid income or expense form, THE IncomeExpenseFormScreen SHALL create the transaction via TransactionService and return true to the caller
5. WHEN the user opens the form with an existing TransactionWithItems, THE IncomeExpenseFormScreen SHALL populate all fields with the existing data for editing
6. WHEN the user enables the recurring toggle on a new transaction, THE IncomeExpenseFormScreen SHALL create a RecurringRule with the selected frequency after saving
7. WHEN the user submits a form with line items whose total exceeds the main amount, THE IncomeExpenseFormScreen SHALL display a warning and prevent submission
8. IF the amount is zero and line item total is positive, THEN THE IncomeExpenseFormScreen SHALL auto-fill the amount with the line item total

### Requirement 2: Tạo TransferFormScreen cho chuyển tiền

**User Story:** Là người dùng có nhiều ví, tôi muốn có một màn hình form chuyên biệt để chuyển tiền giữa các ví, để thao tác chuyển tiền rõ ràng và hỗ trợ cả chuyển nội bộ lẫn chuyển liên tài khoản.

#### Acceptance Criteria

1. THE TransferFormScreen SHALL display fields for amount, source wallet, destination wallet (including cross-account wallets), date, and note
2. WHEN the user selects a source wallet, THE TransferFormScreen SHALL exclude that wallet from the destination wallet list within the same account
3. WHEN the user submits a valid transfer form, THE TransferFormScreen SHALL create the transfer via TransactionService.createTransfer and return true to the caller
4. WHEN the user opens the form with an existing transfer transaction, THE TransferFormScreen SHALL populate all fields with the existing data for editing
5. IF the user selects the same wallet for both source and destination, THEN THE TransferFormScreen SHALL display an error and prevent submission

### Requirement 3: Tạo FundingFormScreen cho nạp tiền gia đình

**User Story:** Là thành viên tài khoản gia đình, tôi muốn có một màn hình form chuyên biệt để nạp tiền từ ví cá nhân vào ví gia đình, để thao tác nạp tiền đơn giản và tập trung.

#### Acceptance Criteria

1. THE FundingFormScreen SHALL display fields for amount, source wallet (personal wallets), destination family wallet, date, and note
2. THE FundingFormScreen SHALL pre-filter the destination wallet list to only show wallets belonging to the family account
3. WHEN the user submits a valid funding form, THE FundingFormScreen SHALL create the transfer via TransactionService.createTransfer with the family account's destAccountId and return true to the caller
4. WHEN the user submits the funding form with an amount of zero, THE FundingFormScreen SHALL allow submission as the app follows a ledger-style approach

### Requirement 4: Cập nhật điều hướng từ QuickActionsFab

**User Story:** Là người dùng, tôi muốn các nút trong QuickActionsFab điều hướng đến đúng form chuyên biệt, để tôi vào thẳng form phù hợp với hành động cần thực hiện.

#### Acceptance Criteria

1. WHEN the user taps the "Nạp tiền" button in QuickActionsFab, THE QuickActionsFab SHALL navigate to FundingFormScreen
2. WHEN the user taps the "Chuyển tiền" button in QuickActionsFab, THE QuickActionsFab SHALL navigate to TransferFormScreen

### Requirement 5: Cập nhật điều hướng từ QuickAddBar và các màn hình khác

**User Story:** Là người dùng, tôi muốn khi mở form đầy đủ từ QuickAddBar hoặc khi chỉnh sửa giao dịch, ứng dụng mở đúng form chuyên biệt tương ứng, để trải nghiệm nhất quán.

#### Acceptance Criteria

1. WHEN the user opens the full form from QuickAddBar, THE QuickAddBar SHALL navigate to IncomeExpenseFormScreen
2. WHEN the user taps on an income or expense transaction to edit, THE TransactionFeedItem SHALL navigate to IncomeExpenseFormScreen with the existing transaction data
3. WHEN the user taps on a transfer transaction to edit, THE TransactionFeedItem SHALL navigate to TransferFormScreen with the existing transaction data

### Requirement 6: Loại bỏ TransferScreen cũ và dọn dẹp TransactionFormScreen

**User Story:** Là developer, tôi muốn loại bỏ code trùng lặp và không còn sử dụng, để codebase gọn gàng và dễ bảo trì.

#### Acceptance Criteria

1. WHEN all new form screens are implemented and navigation is updated, THE TransferScreen (transfer_screen.dart) SHALL be removed from the codebase
2. WHEN all new form screens are implemented and navigation is updated, THE TransactionFormScreen (transaction_form_screen.dart) SHALL be removed from the codebase
3. WHEN TransferScreen and TransactionFormScreen are removed, THE codebase SHALL have zero import references to the removed files

### Requirement 7: Xử lý lỗi và validation chung

**User Story:** Là người dùng, tôi muốn các form mới xử lý lỗi rõ ràng và nhất quán, để tôi biết chính xác vấn đề khi nhập liệu sai.

#### Acceptance Criteria

1. WHEN a required field (wallet, category) is empty on submission, THE form screen SHALL display a validation error for that field
2. IF a network or service error occurs during save, THEN THE form screen SHALL display the error message via snackbar and keep the form data intact
3. WHEN the form saves successfully, THE form screen SHALL return true via Navigator.pop to signal the caller to refresh data
