# Tasks: Notifications (FCM)

> User nhận được update realtime khi được invite hoặc có transaction mới trong family.

## Phụ thuộc
- Firestore Security Rules (để Cloud Function có quyền ghi)

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | Thêm firebase_messaging dependency | `firebase_messaging` + platform setup (Android manifest, iOS entitlements) | 🔴 |
| 2 | FCM token registration | Khi user login/sign-in, lưu FCM token vào `users/{userId}/fcm_tokens/{deviceId}` | 🔴 |
| 3 | Cloud Function: onInviteCreated | Trigger khi doc tạo trong `invites/` → gửi notification đến tất cả members của account (trừ creator) | 🔴 |
| 4 | Cloud Function: onTransactionCreated | Trigger khi doc tạo trong `accounts/{id}/transactions/` → gửi notification đến members khác trong family account | 🟡 |
| 5 | Notification handler trong app | `FirebaseMessaging.onMessage` (foreground) + `onMessageOpenedApp` (background tap) → navigate đến đúng screen | 🟡 |
| 6 | Navigate on tap | Invite notification → JoinFamilyScreen(tokenId). Transaction notification → HomeScreen hoặc WalletDetailScreen | 🟡 |
| 7 | Notification permission request | Hỏi permission lần đầu, lưu preference | 🟢 |
| 8 | L10n notification messages | Keys cho notification title/body: inviteTitle, inviteBody, newTransactionTitle, newTransactionBody | 🟢 |
