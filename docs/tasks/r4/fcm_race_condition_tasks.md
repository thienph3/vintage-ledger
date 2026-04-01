# Tasks: FCM Race Condition Mitigation — ✅

| # | Task | Status |
|---|------|--------|
| 1 | Notification lock collection | ✅ `accounts/{accountId}/notification_events/{eventId}` with created_at |
| 2 | Atomic check-and-create | ✅ `firestore.runTransaction`: get → exists? skip : set + proceed |
| 3 | Integrate vào NotificationService | ✅ `_acquireNotificationLock()` replaces `_isDuplicate()`. In-memory kept as fast path |
| 4 | TTL cleanup | ✅ `_cleanupOldNotificationEvents()`: delete > 3 days, 1x/day, on init |
| 5 | Security rules | ✅ notification_events: create/read/delete isMember, update deny |
