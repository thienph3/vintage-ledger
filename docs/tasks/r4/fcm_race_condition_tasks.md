# Tasks: FCM Race Condition Mitigation

> Mỗi event chỉ notify 1 lần, không duplicate cross-device.

## Phụ thuộc
- Không

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | Notification lock collection | Tạo subcollection `accounts/{accountId}/notification_events/{eventId}` với field `created_at`. Trước khi gửi, check doc tồn tại → skip nếu có | 🔴 |
| 2 | Atomic check-and-create | Dùng Firestore transaction: `get(eventRef)` → nếu chưa tồn tại → `set(eventRef)` + proceed gửi. Nếu đã tồn tại → skip | 🔴 |
| 3 | Integrate vào NotificationService | Thay `_isDuplicate` in-memory bằng Firestore-based lock cho cross-device dedup. Giữ in-memory check làm fast path | 🔴 |
| 4 | TTL cleanup | Xóa notification_events docs > 3 ngày. Chạy khi app init (1 lần/ngày, check last_cleanup timestamp) | 🟡 |
| 5 | Security rules | `notification_events`: create isMember, read isMember, delete isMember, update deny | 🟡 |
