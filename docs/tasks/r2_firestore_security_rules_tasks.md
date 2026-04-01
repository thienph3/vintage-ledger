# Tasks: Firestore Security Rules

> Đảm bảo chỉ member mới đọc/ghi được data, không access trái phép.

## Phụ thuộc
- Không

## Tasks

| # | Task | Mô tả | Status |
|---|------|--------|--------|
| 1 | Helper function isMember | `isMember(accountId)` + `isOwner(accountId)` + `isAuthenticated()` + `isCurrentUser(userId)` | ✅ |
| 2 | accounts/{accountId} rules | read: isMember. create: auth uid in member_ids + owner_id == uid. update/delete: isOwner | ✅ |
| 3 | Subcollection rules | wallets/transactions/categories/budgets: read/write isMember. Validation trên create/update | ✅ |
| 4 | activities rules | create: isMember + user_id == auth uid. read: isMember. update/delete: deny | ✅ |
| 5 | invites rules | create: isMember of referenced account + created_by == uid. read: authenticated. update/delete: deny | ✅ |
| 6 | users/{userId} rules | read/write: isCurrentUser. Subcollection settings: same | ✅ |
| 7 | Data validation | transactions: amount > 0, type in [income, expense]. budgets: amount_limit > 0. wallets: name.size() > 0. categories: name.size() > 0 | ✅ |
| 8 | Update firestore.rules | File hoàn chỉnh với tất cả rules trên | ✅ |
| 9 | Deploy rules | `firebase deploy --only firestore:rules` — cần chạy thủ công | ⏳ |
| 10 | Test rules | Cần Firestore emulator hoặc rules playground | ⏳ |
