# Tasks: Wallet Detail Redesign

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | Bỏ ChartSection | `wallet_detail_screen.dart` | Remove chart import + widget. Charts available in Insights tab |
| 2 | Balance card soft | `wallet_detail_screen.dart` | Casual: "Ví chính — 500k". Soft card, tap to toggle visibility |
| 3 | Transaction feed | `wallet_detail_screen.dart` | Replace TransactionSection → story format feed (FeedItem + FeedHelper) |
| 4 | Reactions | `wallet_detail_screen.dart` | Add ReactionBar + long-press picker per transaction |
| 5 | Loading → shimmer | `wallet_detail_screen.dart` | Replace CircularProgressIndicator → ShimmerPlaceholder |
| 6 | Colors + radius | `wallet_detail_screen.dart` | All → AppColors semantic, radius 16 |
| 7 | L10n | `app_vi.dart`, `app_en.dart` | Verify wallet detail strings casual |
