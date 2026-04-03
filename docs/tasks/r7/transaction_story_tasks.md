# Tasks: Transaction as Story

Chuyển transaction display từ "data row" sang "story" — luôn có actor (ai), ngôn ngữ tự nhiên, emoji.

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | Thêm `createdByName` vào display | `transaction_section.dart`, `transaction_list_screen.dart` | Resolve `created_by` userId → display name. Hiện "{name} {action} {amount} {emoji}" thay vì "{category} - {amount}" |
| 2 | Story format helper | `lib/utils/transaction_story.dart` | `formatStory(txn, userName, catName, catEmoji)` → "Minh ăn trưa 80k 🍜". Rules: actor + verb + amount + emoji |
| 3 | Category emoji mapping | `lib/core/constants/category_emojis.dart` | Map category name → emoji: Ăn uống→🍜, Cà phê→☕, Di chuyển→🚗, Mua sắm→🛍️, etc. Fallback: 💰 |
| 4 | Cập nhật TransactionSection | `transaction_section.dart` | Dùng story format. Hiện actor name (bold) + action text + amount. Bỏ layout cũ (icon + catName + amount column) |
| 5 | Cập nhật Timeline Ledger | `transaction_list_screen.dart` | Day expand items dùng story format. Bỏ category icon column |
| 6 | Cập nhật WalletDetailScreen | `wallet_detail_screen.dart` | TransactionSection dùng story format |
| 7 | Quick Add snackbar | `quick_add_bar.dart` | "✓ Minh cafe 30k ☕" thay vì "✓ 30k Cà phê" |
| 8 | Load member names | `TransactionSection`, `TransactionListScreen` | Gọi `getMemberProfiles` hoặc cache user names. Personal account: dùng "Bạn" thay vì tên |
| 9 | L10n | `app_vi.dart`, `app_en.dart` | +3 keys: youActor ("Bạn"), spentVerb ("chi"), earnedVerb ("thu") |
