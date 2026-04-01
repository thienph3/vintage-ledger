# Tasks: Notifications (FCM)

> User nhận được update realtime khi được invite hoặc có transaction mới trong family.

## Phụ thuộc
- Firestore Security Rules ✅

## Tasks

| # | Task | Mô tả | Status |
|---|------|--------|--------|
| 1 | Thêm firebase_messaging dependency | `firebase_messaging: ^15.2.4` trong pubspec.yaml | ✅ |
| 2 | FCM token registration | `NotificationService._registerToken()` → lưu token vào `users/{userId}/fcm_tokens/{token}` + listen onTokenRefresh | ✅ |
| 3 | Cloud Function: onInviteCreated | `functions/index.js` — trigger on `invites/{tokenId}` create → gửi notification đến members (trừ creator) | ✅ |
| 4 | Cloud Function: onTransactionCreated | `functions/index.js` — trigger on `accounts/{id}/transactions/{txnId}` create → gửi notification đến family members (trừ creator) | ✅ |
| 5 | Notification handler trong app | `NotificationService._setupHandlers()` — onMessage (foreground), onMessageOpenedApp (background tap), getInitialMessage (terminated) | ✅ |
| 6 | Navigate on tap | invite → JoinFamilyScreen(tokenId), transaction → HomeScreen | ✅ |
| 7 | Notification permission request | `_requestPermission()` gọi trong init() | ✅ |
| 8 | L10n notification messages | 4 keys: inviteTitle, inviteBody, newTransactionTitle, newTransactionBody | ✅ |

## Deploy

```bash
cd functions && npm install
firebase deploy --only functions
```
