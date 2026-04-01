# Tasks: Family V2 (Simplified Shared Usage)

> Shared usage đơn giản như couple. Time to setup family < 1 phút.

## Phụ thuộc
- Data Layer V2 (realtime để thấy activity) ✅

## Tasks

| # | Task | Mô tả | Status |
|---|------|--------|--------|
| 1 | Invite bằng link | `createInviteToken()` → token ID → `buildInviteLink()`. Lưu trong `invites` collection | ✅ |
| 2 | Invite token model | `InviteToken` model: accountId, createdBy, createdAt, expiresAt, isExpired getter | ✅ |
| 3 | Deep link handler | `JoinFamilyScreen` — load token, validate expiry, join family | ✅ |
| 4 | Shared wallet mặc định | `createFamilyAccount()` tự tạo wallet "Ví chung" (VND, balance 0) | ✅ |
| 5 | Share invite UI | Nút share icon trong FamilyDetailScreen → tạo token → copy link to clipboard | ✅ |
| 6 | Activity feed | `logActivity()` + `watchActivities()` stream từ `accounts/{id}/activities/` | ✅ |
| 7 | Activity feed UI | Section "Hoạt động" trong FamilyDetailScreen với realtime StreamBuilder, icon theo action type | ✅ |
| 8 | Xóa invite by email | Bỏ email dialog, thay bằng share invite link | ✅ |
| 9 | Invite expiry | Token hết hạn sau 7 ngày, JoinFamilyScreen hiển thị "Link đã hết hạn" | ✅ |
| 10 | Member avatar | CircleAvatar với initials, owner có màu inkBlue | ✅ |
| 11 | Transaction created_by display | Icon people_outline bên cạnh transactions tạo bởi member khác + logActivity khi tạo transaction | ✅ |
| 12 | L10n keys | Thêm: shareInvite, inviteExpired, inviteCopied, sharedWallet, activity, noActivity, justSpent, justEarned, createdBy | ✅ |
