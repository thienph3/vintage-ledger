# Tasks: Reactions Everywhere

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | TransactionFeedItem widget | `lib/features/transaction/widgets/transaction_feed_item.dart` | Reusable: story text + time + ReactionBar + long-press picker. Extract from HomeScreen `_buildFeedItem` |
| 2 | HomeScreen → use TransactionFeedItem | `home_screen.dart` | Replace inline `_buildFeedItem` + reaction StreamBuilder → `TransactionFeedItem` |
| 3 | TransactionListScreen → add reactions | `transaction_list_screen.dart` | Expanded day items use `TransactionFeedItem` (with reactions) |
| 4 | WalletDetailScreen → add reactions | `wallet_detail_screen.dart` | Feed items use `TransactionFeedItem` |
| 5 | TransactionSection → use TransactionFeedItem | `transaction_section.dart` | Replace inline `_buildItem` → `TransactionFeedItem` |
