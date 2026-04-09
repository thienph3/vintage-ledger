# Tài liệu Yêu cầu

## Giới thiệu

Tính năng "Earmark Balance" (Đánh dấu số dư) thay đổi cách mục tiêu tiết kiệm tương tác với ví. Thay vì tạo giao dịch thu/chi giả khi nạp/rút mục tiêu (gây nhầm lẫn số dư ví và làm bẩn báo cáo), hệ thống sẽ chỉ đánh dấu một phần số dư ví là "đã phân bổ cho mục tiêu" mà không thay đổi số dư thực tế của ví.

**Khuyến nghị sử dụng:** Người dùng nên tạo một ví tiết kiệm riêng biệt để gắn mục tiêu, không nên dùng chung với ví tracking chi tiêu hàng ngày. Điều này giúp tách biệt rõ ràng giữa tiền tiết kiệm và tiền chi tiêu, tránh nhầm lẫn khi xem số dư khả dụng. Thông tin earmark chỉ hiển thị trên các ví có mục tiêu liên kết, ví thường không bị ảnh hưởng.

## Thuật ngữ

- **Goal_Service**: Dịch vụ xử lý logic nghiệp vụ liên quan đến mục tiêu tiết kiệm (`GoalService`)
- **Wallet_Model**: Mô hình dữ liệu ví (`Wallet`), chứa thông tin số dư và loại ví
- **Wallet_Type**: Loại ví — `normal` (ví thường), `saving` (ví tiết kiệm), `debt` (ví nợ)
- **Goal_Model**: Mô hình dữ liệu mục tiêu tiết kiệm (`Goal`), chứa `currentAmount` và `fundingWalletId`
- **Earmarked_Amount**: Tổng `currentAmount` của tất cả mục tiêu active liên kết với một ví
- **Available_Balance**: Số dư khả dụng = `balance` của ví trừ đi Earmarked_Amount
- **Contribution**: Hành động nạp tiền vào mục tiêu (tăng `goal.currentAmount`)
- **Withdrawal**: Hành động rút tiền từ mục tiêu (giảm `goal.currentAmount`)
- **Contribution_Screen**: Màn hình nạp tiền vào mục tiêu (`GoalContributionScreen`)
- **Wallet_Detail_Screen**: Màn hình chi tiết ví (`WalletDetailScreen`)
- **Wallet_Form_Screen**: Màn hình tạo/sửa ví (`WalletFormScreen`)
- **Debt_Amount**: Số tiền nợ còn lại của ví nợ (giá trị âm của `balance` hoặc field riêng)

## Yêu cầu

### Yêu cầu 1: Nạp tiền vào mục tiêu không tạo giao dịch

**User Story:** Là người dùng, tôi muốn nạp tiền vào mục tiêu tiết kiệm mà không tạo giao dịch chi tiêu giả, để số dư ví và báo cáo tài chính phản ánh đúng thực tế.

#### Tiêu chí chấp nhận

1. WHEN người dùng nạp tiền vào mục tiêu, THE Goal_Service SHALL chỉ tăng `goal.currentAmount` và tạo bản ghi contribution mà không tạo giao dịch (transaction) trong collection `transactions`
2. WHEN người dùng nạp tiền vào mục tiêu, THE Goal_Service SHALL không thay đổi `wallet.balance`
3. WHEN mục tiêu đạt `currentAmount >= targetAmount` sau khi nạp, THE Goal_Service SHALL cập nhật trạng thái mục tiêu thành `completed`

### Yêu cầu 2: Rút tiền từ mục tiêu không tạo giao dịch

**User Story:** Là người dùng, tôi muốn rút tiền từ mục tiêu tiết kiệm mà không tạo giao dịch thu nhập giả, để báo cáo tài chính không bị sai lệch.

#### Tiêu chí chấp nhận

1. WHEN người dùng rút tiền từ mục tiêu, THE Goal_Service SHALL chỉ giảm `goal.currentAmount` và tạo bản ghi contribution âm mà không tạo giao dịch trong collection `transactions`
2. WHEN người dùng rút tiền từ mục tiêu, THE Goal_Service SHALL không thay đổi `wallet.balance`
3. WHEN số tiền rút vượt quá `goal.currentAmount`, THE Goal_Service SHALL từ chối thao tác và trả về lỗi

### Yêu cầu 3: Tính toán số dư khả dụng của ví

**User Story:** Là người dùng, tôi muốn biết số dư khả dụng thực sự của ví (sau khi trừ phần đã phân bổ cho mục tiêu), để tôi biết mình còn bao nhiêu tiền có thể chi tiêu.

#### Tiêu chí chấp nhận

1. THE Goal_Service SHALL cung cấp phương thức tính tổng earmarked amount cho một ví bằng cách cộng `currentAmount` của tất cả mục tiêu active có `fundingWalletId` trùng với ví đó
2. WHEN nhiều mục tiêu cùng liên kết một ví, THE Goal_Service SHALL tính earmarked amount bằng tổng `currentAmount` của tất cả mục tiêu active liên kết ví đó
3. THE Available_Balance SHALL bằng `wallet.balance` trừ đi earmarked amount của ví đó

### Yêu cầu 4: Validation khi nạp tiền vào mục tiêu

**User Story:** Là người dùng, tôi muốn hệ thống ngăn tôi nạp quá số dư khả dụng vào mục tiêu, để tôi không vô tình phân bổ nhiều hơn số tiền mình có.

#### Tiêu chí chấp nhận

1. WHEN người dùng nạp tiền vào mục tiêu với số tiền vượt quá available balance của ví, THE Goal_Service SHALL từ chối thao tác và trả về lỗi
2. WHEN người dùng nạp tiền vào mục tiêu với số tiền nhỏ hơn hoặc bằng 0, THE Goal_Service SHALL từ chối thao tác và trả về lỗi
3. WHEN người dùng nạp tiền vào mục tiêu không ở trạng thái active, THE Goal_Service SHALL từ chối thao tác và trả về lỗi

### Yêu cầu 5: Hiển thị số dư ví với thông tin earmark (chỉ ví có mục tiêu)

**User Story:** Là người dùng, tôi muốn thấy rõ ràng tổng số dư, số tiền đã phân bổ cho mục tiêu, và số dư khả dụng trên màn hình ví khi ví đó có gắn mục tiêu, để tôi hiểu tình trạng tài chính mà không bị nhiễu thông tin trên các ví thường.

#### Tiêu chí chấp nhận

1. WHEN ví có ít nhất một mục tiêu active liên kết, THE Wallet_Detail_Screen SHALL hiển thị ba giá trị: tổng số dư (`balance`), earmarked amount, và available balance
2. WHEN ví không có mục tiêu active nào liên kết, THE Wallet_Detail_Screen SHALL chỉ hiển thị tổng số dư như hiện tại
3. WHEN ví có mục tiêu active liên kết, THE Wallet_Detail_Screen SHALL hiển thị danh sách các mục tiêu liên kết bên cạnh danh sách giao dịch gần đây
4. WHEN ví có mục tiêu active liên kết, THE Wallet_List_Screen SHALL hiển thị thêm dòng available balance bên dưới tổng balance
5. WHEN ví không có mục tiêu active nào liên kết, THE Wallet_List_Screen SHALL chỉ hiển thị tổng balance như hiện tại

### Yêu cầu 6: Giải phóng earmark khi hủy hoặc xóa mục tiêu

**User Story:** Là người dùng, tôi muốn khi hủy hoặc xóa mục tiêu thì phần tiền đã phân bổ tự động được giải phóng, để số dư khả dụng của ví tăng lên tương ứng.

#### Tiêu chí chấp nhận

1. WHEN người dùng hủy mục tiêu (status → cancelled), THE Goal_Service SHALL đặt `currentAmount` về 0 để giải phóng earmarked amount
2. WHEN người dùng xóa mục tiêu, THE Goal_Service SHALL xóa mục tiêu và toàn bộ contributions liên quan, tự động giải phóng earmarked amount
3. WHEN mục tiêu được hủy hoặc xóa, THE Goal_Service SHALL không tạo bất kỳ giao dịch nào trong collection `transactions`

### Yêu cầu 7: Hiển thị available balance trên màn hình nạp tiền

**User Story:** Là người dùng, tôi muốn thấy số dư khả dụng khi nạp tiền vào mục tiêu, để tôi biết mình có thể nạp tối đa bao nhiêu.

#### Tiêu chí chấp nhận

1. WHEN người dùng chọn mục tiêu để nạp tiền, THE Contribution_Screen SHALL hiển thị available balance của ví liên kết với mục tiêu đó
2. WHEN người dùng nhập số tiền vượt quá available balance, THE Contribution_Screen SHALL hiển thị cảnh báo và vô hiệu hóa nút nạp

### Yêu cầu 8: Loại bỏ phụ thuộc vào system category cho mục tiêu

**User Story:** Là developer, tôi muốn loại bỏ việc sử dụng system category `goal_contribution` trong luồng nạp/rút mục tiêu, để code sạch hơn và không tạo dữ liệu thừa.

#### Tiêu chí chấp nhận

1. THE Goal_Service SHALL không gọi `ensureSystemCategory('goal_contribution')` trong các phương thức `napVaoMucTieu` và `rutTuMucTieu`
2. THE Goal_Service SHALL không tham chiếu đến `TransactionService` hoặc `CategoryService` trong luồng nạp/rút mục tiêu

### Yêu cầu 9: Phân loại ví theo loại (Wallet Type)

**User Story:** Là người dùng, tôi muốn phân loại ví thành ví thường, ví tiết kiệm, và ví nợ, để mỗi loại ví có giao diện và chức năng phù hợp với mục đích sử dụng.

#### Tiêu chí chấp nhận

1. THE Wallet_Model SHALL có trường `type` với ba giá trị: `normal`, `saving`, `debt`
2. WHEN tạo ví mới, THE Wallet_Form_Screen SHALL cho phép người dùng chọn loại ví
3. WHEN không chọn loại ví, THE Wallet_Form_Screen SHALL mặc định loại ví là `normal`
4. THE Wallet_Model SHALL serialize và deserialize trường `type` từ Firestore

### Yêu cầu 10: Giao diện ví tiết kiệm

**User Story:** Là người dùng, tôi muốn ví tiết kiệm có nút nạp mục tiêu nhanh, để tôi dễ dàng nạp tiền vào mục tiêu từ màn hình ví.

#### Tiêu chí chấp nhận

1. WHEN ví có type là `saving`, THE Wallet_Detail_Screen SHALL hiển thị FAB (Floating Action Button) cho phép nạp tiền vào mục tiêu
2. WHEN người dùng nhấn FAB nạp mục tiêu, THE Wallet_Detail_Screen SHALL điều hướng đến Contribution_Screen
3. WHEN ví có type là `saving`, THE Wallet_Detail_Screen SHALL hiển thị danh sách mục tiêu liên kết phía trên danh sách giao dịch

### Yêu cầu 11: Giao diện ví nợ

**User Story:** Là người dùng, tôi muốn ví nợ có nút trả nợ nhanh và hiển thị số nợ còn lại, để tôi theo dõi và quản lý nợ dễ dàng.

#### Tiêu chí chấp nhận

1. WHEN ví có type là `debt`, THE Wallet_Detail_Screen SHALL hiển thị FAB cho phép ghi nhận trả nợ
2. WHEN người dùng nhấn FAB trả nợ, THE Wallet_Detail_Screen SHALL tạo giao dịch chi tiêu với category hệ thống `debt_payment`
3. WHEN ví có type là `debt`, THE Wallet_Detail_Screen SHALL hiển thị số nợ ban đầu (`initialBalance` dạng âm) và số nợ còn lại
4. WHEN ví có type là `debt`, THE Wallet_List_Screen SHALL hiển thị số nợ còn lại với màu sắc khác biệt (ví dụ: đỏ)
