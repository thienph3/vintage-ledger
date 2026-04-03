# Tasks: Reaction System ✅

| # | Task | Status |
|---|------|--------|
| 1 | Reaction data model | ✅ Subcollection `transactions/{txnId}/reactions/{userId}` |
| 2 | Firestore schema | ✅ Subcollection under transactions |
| 3 | Firestore rules | ✅ read: isMember, write: isCurrentUser |
| 4 | ReactionService | ✅ addReaction (+ notify owner), removeReaction, watchReactions |
| 5 | Reaction picker UI | ✅ Bottom sheet 6 emoji with bounce animation |
| 6 | Reaction display | ✅ ReactionBar: grouped emoji bubbles + count |
| 7 | Reaction animation | ✅ Scale 1.0→1.3→1.0 bounce (200ms) |
| 8 | FCM notification | ✅ notifyReaction: push "{name} đã react {emoji}" to txn owner |
| 9 | L10n keys | ✅ tapToReact |
