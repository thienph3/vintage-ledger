# Tasks: Notification UX

> Notification rõ ràng, hữu ích, không spam.

## Phụ thuộc
- FCM Reliability

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | Rich message content | Invite: "Bạn được mời vào gia đình {name}". Transaction: "{user} vừa chi {amount} {category}" — cần resolve user display name + category name trước khi gửi | 🔴 |
| 2 | Anti-spam debounce | Nếu nhiều transactions liên tiếp trong < 2s, gộp thành 1 notification: "{user} vừa thêm {n} giao dịch" | 🟡 |
| 3 | L10n notification body | Thêm keys: invitedToFamily, memberSpent, memberEarned, multipleTransactions | 🟡 |
| 4 | Deep link verify | Test: tap invite notification → JoinFamilyScreen đúng tokenId. Tap transaction → HomeScreen | 🟢 |
