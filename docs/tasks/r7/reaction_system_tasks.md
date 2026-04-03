# Tasks: Reaction System ✅

| # | Task | Status |
|---|------|--------|
| 1 | Reaction data model | ✅ Subcollection `transactions/{txnId}/reactions/{userId}` → `{emoji, created_at}` |
| 2 | Firestore schema | ✅ Subcollection under transactions |
| 3 | Firestore rules | ✅ `reactions/{userId}`: read if isMember, create/update if isMember && isCurrentUser, delete if isCurrentUser |
| 4 | ReactionService | ✅ `lib/features/transaction/services/reaction_service.dart`: addReaction, removeReaction, watchReactions stream |
| 5 | Reaction picker UI | ✅ `reaction_picker.dart`: bottom sheet 6 emoji (😂😅👍❤️😱💸), tap chọn |
| 6 | Reaction display | ✅ `reaction_bar.dart`: emoji bubbles grouped by emoji + count. StreamBuilder in HomeScreen feed |
| 7 | Reaction animation | ✅ Pop/bounce scale 1.0→1.3→1.0 (200ms) on emoji tap |
| 8 | FCM notification | ⏳ Pending — notify transaction owner khi có reaction mới |
| 9 | L10n keys | ✅ +1 key: tapToReact |
