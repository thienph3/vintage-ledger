# Tasks: Reaction System

Thêm emoji reactions cho transactions — tạo interaction loop giữa members.

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | Reaction data model | `lib/features/transaction/models/transaction.dart` | Thêm field `reactions: Map<String, String>` (userId → emoji). Hoặc subcollection `reactions/{userId}` → `{emoji, created_at}` |
| 2 | Firestore schema | Subcollection approach | `accounts/{accountId}/transactions/{txnId}/reactions/{userId}` → `{emoji, created_at}`. Mỗi user 1 reaction per transaction |
| 3 | Firestore rules | `firestore.rules` | `reactions/{userId}`: read if isMember. create/update if isMember && userId == auth.uid. delete if userId == auth.uid |
| 4 | ReactionService | `lib/features/transaction/services/reaction_service.dart` | `addReaction(txnId, emoji)`, `removeReaction(txnId)`, `watchReactions(txnId)` |
| 5 | Reaction picker UI | `lib/features/transaction/widgets/reaction_picker.dart` | Long-press transaction → popup 5–6 emoji: 😂 😅 👍 ❤️ 😱 💸. Tap chọn |
| 6 | Reaction display | `transaction_section.dart`, `transaction_list_screen.dart` | Hiện reactions dưới mỗi transaction item: emoji bubbles nhỏ + count. Tap xem ai react |
| 7 | Reaction animation | `reaction_picker.dart` | Pop/bounce animation khi chọn emoji (150–250ms) |
| 8 | FCM notification | `notification_service.dart` | Notify transaction owner khi có reaction mới: "{name} đã react {emoji}" |
| 9 | L10n keys | `app_vi.dart`, `app_en.dart` | +2 keys: reactedWith ("đã react"), tapToReact ("Nhấn giữ để react") |
