# Tasks: Family V2 (Simplified Shared Usage)

> Shared usage đơn giản như couple. Time to setup family < 1 phút.

## Phụ thuộc
- Data Layer V2 (realtime để thấy activity)

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | Invite bằng link | Tạo invite link (Firebase Dynamic Links hoặc custom scheme): `vintage-ledger://join/{accountId}/{token}` | 🔴 |
| 2 | Invite token model | Lưu invite token trên Firestore: `accounts/{id}/invites/{token}` với expiry, created_by | 🔴 |
| 3 | Deep link handler | Xử lý khi user tap invite link: mở app → auto join family account | 🔴 |
| 4 | Shared wallet mặc định | Khi tạo family, tự tạo 1 wallet "Ví chung" trên Firestore | 🔴 |
| 5 | Share invite UI | Nút "Chia sẻ link" trong FamilyDetailScreen, dùng Share API native | 🟡 |
| 6 | Activity feed | Subcollection `accounts/{id}/activities/` — log ai tạo/sửa/xóa transaction gì | 🟡 |
| 7 | Activity feed UI | Tab/section trong FamilyDetailScreen hiển thị "Minh vừa chi 50k cho Ăn uống" | 🟡 |
| 8 | Xóa invite by email | Bỏ flow nhập email trong FamilyDetailScreen, thay bằng invite link | 🟡 |
| 9 | Invite expiry | Token hết hạn sau 7 ngày, hiển thị "Link đã hết hạn" khi tap expired link | 🟢 |
| 10 | Member avatar | Hiển thị avatar/initials cho mỗi member trong FamilyDetailScreen | 🟢 |
| 11 | Transaction created_by display | Hiển thị tên người tạo bên cạnh transaction trong shared wallet | 🟢 |
| 12 | L10n keys | Thêm keys: shareInvite, inviteExpired, sharedWallet, activity, justSpent... | 🟢 |
