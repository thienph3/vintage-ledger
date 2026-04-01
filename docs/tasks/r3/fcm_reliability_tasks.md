# Tasks: FCM Reliability (Client-side)

> Notification gửi đúng người, không duplicate, ổn định.

## Tasks

| # | Task | Mô tả | Status |
|---|------|--------|--------|
| 1 | Deduplication | `_sentEvents` map với TTL 60s. `_isDuplicate(eventId)` check trước khi gửi. Event ID = `invite_{tokenId}` hoặc `txn_{transactionId}` | ✅ |
| 2 | Self-notification guard | `_getTokensForUsers` exclude `currentUserId`. Đã có từ trước, verified | ✅ |
| 3 | Retry with backoff | `_sendWithRetry`: max 2 retries, delay 500ms → 1s. Handle timeout 10s + non-200 status | ✅ |
| 4 | Stale token cleanup | `_handleFcmResponse` parse FCM response, nếu `InvalidRegistration` hoặc `NotRegistered` → xóa token khỏi Firestore | ✅ |
| 5 | Prevent duplicate tokens | `_registerToken` xóa tất cả tokens cũ trước khi set token mới. `onTokenRefresh` xóa token cũ | ✅ |
| 6 | Failure logging | `_log()` dùng `debugPrint` chỉ trong `kDebugMode`. Log retry attempts + final failure | ✅ |
