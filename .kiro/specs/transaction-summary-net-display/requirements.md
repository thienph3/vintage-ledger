# Requirements Document

## Giới thiệu

Tính năng này cải thiện khu vực tổng hợp thu chi trên màn hình danh sách giao dịch (Transaction List Screen). Hiện tại, màn hình đã tính đúng thu/chi (bao gồm cả chuyển khoản vào/ra), nhưng chỉ hiển thị 2 chip: Thu và Chi. Yêu cầu bổ sung thêm thông tin "Chênh lệch" (net = thu - chi) để người dùng nắm bắt nhanh tình hình tài chính trong khoảng thời gian đang xem.

Ngoài ra, widget `IncomeExpenseSummaryRow` dùng chung ở nhiều nơi cũng cần hỗ trợ hiển thị net tùy chọn.

## Glossary

- **Transaction_List_Screen**: Màn hình danh sách giao dịch, hiển thị các giao dịch theo ngày/tuần/tháng với bộ lọc ví, danh mục, thành viên.
- **Summary_Area**: Khu vực tổng hợp thu chi nằm phía trên danh sách giao dịch, hiện tại gồm 2 chip (Thu, Chi).
- **Net**: Giá trị chênh lệch = tổng thu - tổng chi. Dương nghĩa là thu nhiều hơn chi, âm nghĩa là chi nhiều hơn thu.
- **Income_Total**: Tổng thu = income + transferIn (đã tính đúng trong code hiện tại qua `_countsAsIncome`).
- **Expense_Total**: Tổng chi = expense + transferOut (đã tính đúng trong code hiện tại qua `_countsAsExpense`).
- **Summary_Chip**: Widget hiển thị một nhãn và số tiền đã format, dùng trong Summary_Area.
- **IncomeExpenseSummaryRow**: Widget dùng chung hiển thị thu/chi dạng 2 cột, sử dụng ở nhiều màn hình.
- **FeedItem**: Widget hiển thị một dòng giao dịch trong danh sách, gồm avatar, story text, và thời gian.
- **TransactionStory**: Utility class format nội dung mô tả giao dịch (story text) từ thông tin giao dịch.
- **Actor_Name**: Tên người thực hiện giao dịch, hiển thị trong story text.

## Requirements

### Requirement 1: Hiển thị Net trên Summary Area

**User Story:** Là người dùng, tôi muốn thấy giá trị chênh lệch (net = thu - chi) trên màn hình danh sách giao dịch, để nhanh chóng biết mình đang thu nhiều hơn hay chi nhiều hơn trong khoảng thời gian đang xem.

#### Acceptance Criteria

1. THE Summary_Area SHALL hiển thị 3 mục: Thu (Income_Total), Chi (Expense_Total), và Chênh lệch (Net).
2. WHEN tổng thu và tổng chi được tính xong, THE Summary_Area SHALL tính Net bằng công thức Income_Total trừ Expense_Total.
3. WHEN Net có giá trị dương, THE Summary_Chip SHALL hiển thị Net với màu thu (income color).
4. WHEN Net có giá trị âm, THE Summary_Chip SHALL hiển thị Net với màu chi (expense color).
5. WHEN Net bằng 0, THE Summary_Chip SHALL hiển thị Net với màu text phụ (secondary text color).
6. THE Summary_Chip cho Net SHALL sử dụng nhãn lấy từ localization key `net` đã có sẵn.

### Requirement 2: Cập nhật IncomeExpenseSummaryRow hỗ trợ Net

**User Story:** Là developer, tôi muốn widget `IncomeExpenseSummaryRow` có thể hiển thị thêm cột Net tùy chọn, để các màn hình khác cũng có thể tái sử dụng tính năng này khi cần.

#### Acceptance Criteria

1. THE IncomeExpenseSummaryRow SHALL nhận tham số `showNet` tùy chọn, mặc định là `false`.
2. WHEN `showNet` là `true`, THE IncomeExpenseSummaryRow SHALL hiển thị thêm cột thứ 3 cho Net, tính bằng income trừ expense.
3. WHEN `showNet` là `false`, THE IncomeExpenseSummaryRow SHALL giữ nguyên giao diện 2 cột như hiện tại.
4. WHEN Net dương, THE IncomeExpenseSummaryRow SHALL hiển thị giá trị Net với màu thu (income color).
5. WHEN Net âm, THE IncomeExpenseSummaryRow SHALL hiển thị giá trị Net với màu chi (expense color).
6. WHEN Net bằng 0, THE IncomeExpenseSummaryRow SHALL hiển thị giá trị Net với màu text phụ (secondary text color).

### Requirement 3: Làm nổi bật tên người thực hiện giao dịch

**User Story:** Là người dùng, tôi muốn tên người thực hiện giao dịch được hiển thị nổi bật hơn trong danh sách giao dịch, để dễ dàng nhận biết ai đã thực hiện giao dịch nào.

#### Acceptance Criteria

1. WHEN hiển thị một giao dịch trong danh sách, THE FeedItem SHALL hiển thị tên người thực hiện (actorName) với font weight semi-bold (w600) để phân biệt với phần còn lại của story text.
2. WHEN story text chứa tên người thực hiện, THE TransactionFeedItem SHALL tách tên người thực hiện ra khỏi story text và render dưới dạng RichText với TextSpan riêng cho phần tên.
3. THE FeedItem SHALL giữ nguyên kích thước font và màu sắc hiện tại, chỉ thay đổi font weight cho phần tên người thực hiện.

### Requirement 4: Tính toán Net chính xác

**User Story:** Là người dùng, tôi muốn giá trị Net được tính chính xác dựa trên cùng logic phân loại thu/chi đã có, để đảm bảo tính nhất quán.

#### Acceptance Criteria

1. THE Transaction_List_Screen SHALL tính Net bằng cách lấy Income_Total trừ Expense_Total, sử dụng cùng hàm `_countsAsIncome` và `_countsAsExpense` đã có.
2. WHEN bộ lọc (ví, danh mục, thành viên) thay đổi, THE Summary_Area SHALL tính lại Net dựa trên danh sách giao dịch đã lọc.
3. WHEN khoảng thời gian (ngày/tuần/tháng) thay đổi, THE Summary_Area SHALL tính lại Net dựa trên danh sách giao dịch trong khoảng mới.
4. FOR ALL danh sách giao dịch hợp lệ, tính Net rồi cộng lại với Expense_Total SHALL bằng đúng Income_Total (tính chất bất biến: net + expense = income).

### Requirement 5: Tách tên người thực hiện trong TransactionStory

**User Story:** Là developer, tôi muốn `TransactionStory.format` trả về dữ liệu có cấu trúc (structured) thay vì chuỗi thuần, để FeedItem có thể render tên người thực hiện với style riêng.

#### Acceptance Criteria

1. THE TransactionStory SHALL cung cấp phương thức trả về dữ liệu có cấu trúc gồm phần tên người thực hiện và phần còn lại của story text.
2. FOR ALL loại giao dịch (income, expense, transferOut, transferIn), THE TransactionStory SHALL tách đúng phần tên người thực hiện ra khỏi phần mô tả.
3. WHEN giao dịch là transferIn (nhận tiền), THE TransactionStory SHALL xử lý đúng trường hợp tên người thực hiện không xuất hiện ở đầu câu.
