# Tài liệu Yêu cầu: Nợ Liên kết (Linked Debt)

## Giới thiệu

Tính năng Nợ Liên kết cho phép hai người dùng trong ứng dụng tạo và theo dõi khoản nợ chung. Khi người dùng A cho người dùng B vay (hoặc ngược lại), hệ thống sẽ tạo 2 bản ghi nợ liên kết — một trong tài khoản của mỗi bên — để cả hai đều có thể xem và quản lý khoản nợ. Khi một bên thanh toán, cả hai bản ghi được cập nhật đồng bộ. Thông báo được gửi đến bên còn lại khi có sự kiện quan trọng.

## Thuật ngữ

- **Hệ_thống**: Ứng dụng quản lý tài chính cá nhân (Flutter + Firebase/Firestore)
- **Nợ_Liên_kết**: Cặp bản ghi nợ (debt document) được tạo trong 2 tài khoản khác nhau, liên kết qua `linkedDebtId` và `linkedAccountId`
- **Bên_Tạo**: Người dùng khởi tạo khoản nợ liên kết
- **Bên_Đối_tác**: Người dùng ở phía bên kia của khoản nợ (được tìm qua email)
- **Nợ_Tự_do**: Khoản nợ hiện tại không liên kết với người dùng trong app (chỉ có tên free-text)
- **Dịch_vụ_Thông_báo**: NotificationService hiện có, gửi push notification qua FCM
- **Giao_dịch_Firestore**: Firestore transaction đảm bảo tính nguyên tử khi ghi vào nhiều document

## Yêu cầu

### Yêu cầu 1: Tìm kiếm người dùng trong app

**User Story:** Là người dùng, tôi muốn tìm kiếm người dùng khác trong app bằng email, để tôi có thể tạo khoản nợ liên kết với họ.

#### Tiêu chí chấp nhận

1. WHEN Bên_Tạo nhập email vào trường tìm kiếm trên DebtFormScreen, THEN Hệ_thống SHALL tra cứu userId tương ứng qua bảng `user_emails` và hiển thị tên người dùng tìm được
2. WHEN email không tồn tại trong hệ thống, THEN Hệ_thống SHALL hiển thị thông báo "Không tìm thấy người dùng" và cho phép Bên_Tạo tiếp tục tạo nợ tự do với tên free-text
3. WHEN Bên_Tạo tìm thấy người dùng và chọn họ, THEN Hệ_thống SHALL lưu `partyUserId` và `linkedAccountId` vào khoản nợ thay vì chỉ lưu tên free-text
4. WHEN Bên_Tạo nhập email trùng với email của chính mình, THEN Hệ_thống SHALL từ chối và hiển thị thông báo lỗi phù hợp

### Yêu cầu 2: Tạo nợ liên kết

**User Story:** Là người dùng, tôi muốn khi tạo khoản nợ với người dùng trong app, hệ thống tự động tạo bản ghi nợ tương ứng ở phía bên kia, để cả hai bên đều thấy và theo dõi được khoản nợ.

#### Tiêu chí chấp nhận

1. WHEN Bên_Tạo tạo khoản nợ loại "cho vay" với một người dùng trong app, THEN Hệ_thống SHALL tạo đồng thời 2 document nợ trong một Giao_dịch_Firestore: một document loại "lend" trong tài khoản Bên_Tạo và một document loại "borrow" trong tài khoản Bên_Đối_tác
2. WHEN Bên_Tạo tạo khoản nợ loại "vay mượn" với một người dùng trong app, THEN Hệ_thống SHALL tạo đồng thời 2 document nợ: một document loại "borrow" trong tài khoản Bên_Tạo và một document loại "lend" trong tài khoản Bên_Đối_tác
3. THE Hệ_thống SHALL lưu trường `linkedDebtId` và `linkedAccountId` trên mỗi document nợ liên kết, trỏ đến document nợ tương ứng ở tài khoản bên kia
4. THE Hệ_thống SHALL lưu trường `partyUserId` trên mỗi document nợ liên kết, chứa userId của bên đối tác
5. WHEN tạo nợ liên kết, THEN Hệ_thống SHALL đảm bảo cả 2 document có cùng `totalAmount`, `dueDate`, `interestRate`, và `description`
6. WHEN tạo nợ liên kết thành công, THEN Hệ_thống SHALL gửi thông báo push đến Bên_Đối_tác thông qua Dịch_vụ_Thông_báo

### Yêu cầu 3: Đồng bộ thanh toán

**User Story:** Là người dùng, tôi muốn khi một bên thanh toán khoản nợ liên kết, bên còn lại cũng được cập nhật tự động, để cả hai luôn thấy số liệu chính xác.

#### Tiêu chí chấp nhận

1. WHEN một bên thực hiện thanh toán trên khoản nợ liên kết, THEN Hệ_thống SHALL cập nhật `paidAmount` trên cả 2 document nợ trong cùng một Giao_dịch_Firestore
2. WHEN `paidAmount` đạt hoặc vượt `totalAmount` trên khoản nợ liên kết, THEN Hệ_thống SHALL cập nhật `status` thành "completed" trên cả 2 document nợ
3. WHEN thanh toán được thực hiện trên khoản nợ liên kết, THEN Hệ_thống SHALL tạo bản ghi payment trong subcollection `payments` của document nợ bên thực hiện thanh toán
4. WHEN thanh toán thành công trên khoản nợ liên kết, THEN Hệ_thống SHALL gửi thông báo push đến bên còn lại thông qua Dịch_vụ_Thông_báo

### Yêu cầu 4: Thông báo

**User Story:** Là người dùng, tôi muốn nhận thông báo khi bên kia tạo nợ liên kết, thanh toán, hoặc hoàn tất khoản nợ, để tôi luôn nắm được tình trạng.

#### Tiêu chí chấp nhận

1. WHEN khoản nợ liên kết được tạo, THEN Dịch_vụ_Thông_báo SHALL gửi push notification đến Bên_Đối_tác với nội dung bao gồm tên Bên_Tạo và số tiền
2. WHEN thanh toán được thực hiện trên khoản nợ liên kết, THEN Dịch_vụ_Thông_báo SHALL gửi push notification đến bên còn lại với nội dung bao gồm số tiền thanh toán
3. WHEN khoản nợ liên kết chuyển sang trạng thái "completed", THEN Dịch_vụ_Thông_báo SHALL gửi push notification đến bên còn lại thông báo khoản nợ đã hoàn tất

### Yêu cầu 5: Tương thích ngược

**User Story:** Là người dùng hiện tại, tôi muốn các khoản nợ tự do (free-text) hiện có vẫn hoạt động bình thường, để tính năng mới không ảnh hưởng đến dữ liệu cũ.

#### Tiêu chí chấp nhận

1. THE Hệ_thống SHALL tiếp tục hỗ trợ tạo và quản lý Nợ_Tự_do (không có `linkedDebtId`) mà không thay đổi hành vi hiện tại
2. WHEN đọc document nợ không có trường `linkedDebtId`, THEN Hệ_thống SHALL xử lý document đó như Nợ_Tự_do với giá trị null cho các trường liên kết
3. THE Hệ_thống SHALL hiển thị cả Nợ_Tự_do và Nợ_Liên_kết trong cùng danh sách nợ, với chỉ báo trực quan phân biệt nợ liên kết

### Yêu cầu 6: Xử lý xóa và hủy nợ liên kết

**User Story:** Là người dùng, tôi muốn có thể hủy hoặc xóa khoản nợ liên kết ở phía mình, và bên kia được thông báo, để tránh nhầm lẫn.

#### Tiêu chí chấp nhận

1. WHEN một bên hủy (cancel) khoản nợ liên kết, THEN Hệ_thống SHALL cập nhật status thành "cancelled" chỉ trên document nợ của bên đó và gỡ liên kết bằng cách xóa `linkedDebtId` trên document bên kia
2. WHEN một bên hủy khoản nợ liên kết, THEN Hệ_thống SHALL gửi thông báo push đến bên còn lại rằng khoản nợ đã bị hủy liên kết
3. WHEN một bên xóa (delete) khoản nợ liên kết, THEN Hệ_thống SHALL xóa document nợ của bên đó và gỡ liên kết trên document bên kia bằng cách xóa `linkedDebtId`
4. IF document nợ liên kết ở bên kia không tồn tại (đã bị xóa trước đó), THEN Hệ_thống SHALL tiếp tục xử lý hủy/xóa bình thường mà không báo lỗi

### Yêu cầu 7: Mở rộng Debt Model

**User Story:** Là nhà phát triển, tôi muốn Debt model được mở rộng với các trường mới để hỗ trợ liên kết, mà vẫn tương thích với dữ liệu hiện có.

#### Tiêu chí chấp nhận

1. THE Hệ_thống SHALL mở rộng Debt model với 3 trường nullable mới: `linkedDebtId` (String?), `linkedAccountId` (String?), và `partyUserId` (String?)
2. THE Hệ_thống SHALL serialize và deserialize các trường mới đúng cách trong `toMap()` và `fromMap()`
3. WHEN deserialize document nợ cũ không có các trường mới, THEN Hệ_thống SHALL gán giá trị null cho `linkedDebtId`, `linkedAccountId`, và `partyUserId`
4. THE Hệ_thống SHALL cung cấp computed property `isLinked` trả về true khi `linkedDebtId` khác null
