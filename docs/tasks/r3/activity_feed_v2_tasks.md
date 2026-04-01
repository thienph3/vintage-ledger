# Tasks: Activity Feed V2

> Activity = fallback cho notification. User theo dõi hoạt động gia đình dễ dàng.

## Phụ thuộc
- Không

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | Rich activity messages | Thay description raw ("50000 - ăn sáng") bằng format rõ ràng: "{user} đã chi 50k cho Ăn uống". Resolve user name + category name + format amount trước khi lưu | 🔴 |
| 2 | Log thêm activity types | Ngoài transaction, log: tạo ví, xóa ví, mời thành viên, member join, member leave | 🟡 |
| 3 | Visual hierarchy | Activity của user khác: bold name + icon màu. Activity của mình: muted style | 🟡 |
| 4 | Timestamp display | Hiển thị relative time: "vừa xong", "5 phút trước", "hôm qua" thay vì raw timestamp | 🟢 |
| 5 | L10n activity keys | Thêm keys: createdWallet, deletedWallet, memberJoined, memberLeft, invitedMember | 🟢 |
