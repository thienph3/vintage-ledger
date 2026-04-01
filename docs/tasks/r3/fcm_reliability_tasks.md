# Tasks: FCM Reliability (Client-side)

> Notification gửi đúng người, không duplicate, ổn định.

## Phụ thuộc
- Không

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | Deduplication | Thêm `event_id` (transactionId/inviteId) vào notification data. Trước khi gửi, check nếu event_id đã gửi gần đây (in-memory set, TTL 60s) → skip | 🔴 |
| 2 | Self-notification guard | Verify `_getTokensForUsers` luôn exclude currentUserId. Thêm unit test | 🔴 |
| 3 | Retry with backoff | Nếu `_sendPush` trả về non-200 hoặc timeout: retry tối đa 2 lần, delay 500ms → 1s | 🔴 |
| 4 | Stale token cleanup | Khi FCM trả về `InvalidRegistration` hoặc `NotRegistered` cho 1 token → xóa token đó khỏi Firestore | 🟡 |
| 5 | Prevent duplicate tokens | Khi `_registerToken`, xóa tokens cũ của cùng device trước khi thêm mới | 🟡 |
| 6 | Failure logging | Trong debug mode, log failed push attempts vào console (không crash app) | 🟢 |
