# Tasks: Firestore Security Rules

> Đảm bảo chỉ member mới đọc/ghi được data, không access trái phép.

## Phụ thuộc
- Không

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | Helper function isMember | `function isMember(accountId)` — check `request.auth.uid in get(/databases/$(database)/documents/accounts/$(accountId)).data.member_ids` | 🔴 |
| 2 | accounts/{accountId} rules | read: isMember. write: chỉ owner (update member_ids, delete) | 🔴 |
| 3 | Subcollection rules (wallets, transactions, categories, budgets) | read/write: `isMember(accountId)`. Validate: `request.resource.data` không chứa fields giả (account_id khác) | 🔴 |
| 4 | activities rules | create: isMember + `request.resource.data.user_id == request.auth.uid`. read: isMember. delete/update: deny | 🔴 |
| 5 | invites rules | create: isMember của account trong invite. read: authenticated (public cho join). delete: deny | 🔴 |
| 6 | users/{userId} rules | read/write: chỉ `request.auth.uid == userId`. Subcollection settings: same | 🔴 |
| 7 | Data validation | Transactions: `amount > 0`, `type in ['income', 'expense']`. Budgets: `amount_limit > 0`. Wallets: `name.size() > 0` | 🟡 |
| 8 | Update firestore.rules | Viết rules file hoàn chỉnh | 🔴 |
| 9 | Deploy rules | `firebase deploy --only firestore:rules` | 🟡 |
| 10 | Test rules | Dùng Firestore emulator hoặc rules playground để verify: member access ✓, non-member deny ✓, validation ✓ | 🟢 |
