# Tài liệu Yêu cầu

## Giới thiệu

Chức năng nhắc nhở thanh toán định kỳ (Recurring Bill Reminder) cho phép người dùng nhận popup nhắc nhở ngay trên màn hình chính khi đến hạn thanh toán các khoản chi định kỳ (trả nợ, đóng lãi, tiền điện, nước, internet, học phí,...). Popup hiển thị liên tục cho đến khi người dùng xác nhận thanh toán bằng một lần chạm — tự động tạo giao dịch và cập nhật các mục liên quan (nợ, mục tiêu tiết kiệm,...). Mục tiêu chính: nhanh nhất có thể cho người dùng.

Chức năng này xây dựng trên hệ thống `RecurringRule` hiện có, bổ sung thêm khả năng liên kết với Debt/Goal và cơ chế popup nhắc nhở trên Home Screen.

## Thuật ngữ

- **Recurring_Rule**: Quy tắc giao dịch định kỳ hiện có trong hệ thống, chứa thông tin amount, category, wallet, frequency, nextRunAt
- **Bill_Reminder**: Một RecurringRule đã đến hạn (nextRunAt <= now) và chưa được xử lý, cần hiển thị popup nhắc nhở
- **Home_Screen**: Màn hình chính của ứng dụng, nơi hiển thị popup nhắc nhở
- **Popup_Widget**: Widget hiển thị trên Home Screen để nhắc nhở người dùng về khoản thanh toán đến hạn
- **One_Tap_Payment**: Hành động người dùng chạm vào popup để tự động tạo giao dịch thanh toán
- **Bill_Reminder_Service**: Service xử lý logic kiểm tra các rule đến hạn và tạo giao dịch thanh toán
- **Linked_Entity**: Debt hoặc Goal được liên kết với RecurringRule để tự động cập nhật khi thanh toán

## Yêu cầu

### Yêu cầu 1: Mở rộng RecurringRule để liên kết Debt/Goal

**User Story:** Là người dùng, tôi muốn liên kết khoản chi định kỳ với khoản nợ hoặc mục tiêu tiết kiệm, để khi thanh toán tự động cập nhật số dư nợ hoặc tiến độ tiết kiệm.

#### Tiêu chí chấp nhận

1. THE Recurring_Rule model SHALL hỗ trợ trường tùy chọn `linkedDebtId` để liên kết với một khoản nợ
2. THE Recurring_Rule model SHALL hỗ trợ trường tùy chọn `linkedGoalId` để liên kết với một mục tiêu tiết kiệm
3. WHEN người dùng tạo hoặc chỉnh sửa RecurringRule, THE Recurring_Form SHALL hiển thị tùy chọn liên kết với Debt hoặc Goal đang hoạt động
4. IF cả linkedDebtId và linkedGoalId đều được cung cấp, THEN THE Recurring_Form SHALL từ chối và yêu cầu chọn một trong hai

### Yêu cầu 2: Phát hiện khoản thanh toán đến hạn

**User Story:** Là người dùng, tôi muốn hệ thống tự động phát hiện các khoản chi định kỳ đến hạn, để tôi được nhắc nhở kịp thời.

#### Tiêu chí chấp nhận

1. WHEN Home_Screen được mở, THE Bill_Reminder_Service SHALL truy vấn tất cả RecurringRule có enabled=true và nextRunAt <= thời điểm hiện tại
2. THE Bill_Reminder_Service SHALL trả về danh sách Bill_Reminder được sắp xếp theo nextRunAt tăng dần (khoản đến hạn sớm nhất hiển thị trước)
3. WHEN không có khoản nào đến hạn, THE Bill_Reminder_Service SHALL trả về danh sách rỗng

### Yêu cầu 3: Hiển thị popup nhắc nhở trên Home Screen

**User Story:** Là người dùng, tôi muốn thấy popup nhắc nhở ngay trên màn hình chính khi có khoản thanh toán đến hạn, để tôi không bỏ lỡ.

#### Tiêu chí chấp nhận

1. WHEN có ít nhất một Bill_Reminder, THE Home_Screen SHALL hiển thị Popup_Widget ở vị trí nổi bật phía trên danh sách giao dịch
2. THE Popup_Widget SHALL hiển thị tên danh mục, số tiền, và tên ví nguồn cho mỗi khoản đến hạn
3. WHILE có nhiều khoản đến hạn, THE Popup_Widget SHALL hiển thị danh sách cuộn được với tất cả các khoản
4. WHEN không có khoản nào đến hạn, THE Home_Screen SHALL ẩn Popup_Widget hoàn toàn
5. THE Popup_Widget SHALL hiển thị liên tục trên Home_Screen cho đến khi người dùng xử lý tất cả các khoản

### Yêu cầu 4: Thanh toán nhanh bằng một lần chạm (One-Tap Payment)

**User Story:** Là người dùng, tôi muốn thanh toán khoản định kỳ chỉ bằng một lần chạm vào popup, để tiết kiệm thời gian tối đa.

#### Tiêu chí chấp nhận

1. WHEN người dùng chạm vào một Bill_Reminder trong Popup_Widget, THE Bill_Reminder_Service SHALL tạo giao dịch thanh toán với thông tin từ RecurringRule (amount, categoryId, walletId, type, note)
2. WHEN giao dịch được tạo thành công, THE Bill_Reminder_Service SHALL cập nhật nextRunAt của RecurringRule sang chu kỳ tiếp theo
3. WHEN giao dịch được tạo thành công, THE Popup_Widget SHALL xóa khoản vừa thanh toán khỏi danh sách và hiển thị thông báo xác nhận
4. WHEN RecurringRule có linkedDebtId, THE Bill_Reminder_Service SHALL ghi nhận khoản thanh toán vào Debt tương ứng (cập nhật paidAmount)
5. WHEN RecurringRule có linkedGoalId, THE Bill_Reminder_Service SHALL ghi nhận đóng góp vào Goal tương ứng (cập nhật currentAmount)
6. IF giao dịch thanh toán thất bại, THEN THE Popup_Widget SHALL hiển thị thông báo lỗi và giữ nguyên Bill_Reminder trong danh sách

### Yêu cầu 5: Bỏ qua khoản nhắc nhở

**User Story:** Là người dùng, tôi muốn có thể bỏ qua một khoản nhắc nhở mà không thanh toán, để xử lý sau hoặc khi khoản đó không cần thanh toán kỳ này.

#### Tiêu chí chấp nhận

1. WHEN người dùng vuốt bỏ (dismiss) một Bill_Reminder, THE Bill_Reminder_Service SHALL cập nhật nextRunAt sang chu kỳ tiếp theo mà không tạo giao dịch
2. WHEN một Bill_Reminder bị bỏ qua, THE Popup_Widget SHALL xóa khoản đó khỏi danh sách hiển thị

### Yêu cầu 6: Hoàn tác thanh toán

**User Story:** Là người dùng, tôi muốn có thể hoàn tác thanh toán vừa thực hiện, để sửa lỗi nếu chạm nhầm.

#### Tiêu chí chấp nhận

1. WHEN giao dịch thanh toán được tạo thành công, THE Popup_Widget SHALL hiển thị nút hoàn tác (undo) trong thông báo xác nhận trong khoảng thời gian giới hạn
2. WHEN người dùng chạm nút hoàn tác, THE Bill_Reminder_Service SHALL xóa giao dịch vừa tạo, khôi phục nextRunAt về giá trị trước đó, và hoàn tác cập nhật Debt/Goal nếu có
