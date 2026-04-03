# Tasks: Transaction as Story ✅

| # | Task | Status |
|---|------|--------|
| 1 | Actor name in display | ✅ HomeScreen feed: "Bạn" (personal). Family: resolve from createdBy (future) |
| 2 | Story format helper | ✅ `lib/utils/transaction_story.dart`: `format()` → "Bạn cafe 30k ☕" |
| 3 | Category emoji mapping | ✅ `lib/core/constants/category_emojis.dart`: 22 mappings + `getCategoryEmoji()` fallback 💸 |
| 4 | HomeScreen feed | ✅ Feed items dùng story format: 1 dòng "Bạn ăn trưa 50k 🍜" + time |
| 5 | Timeline Ledger | ⏳ Pending — sẽ cập nhật khi refactor transaction_list_screen |
| 6 | WalletDetailScreen | ⏳ Pending — dùng TransactionSection, sẽ cập nhật cùng lúc |
| 7 | Quick Add snackbar | ✅ "✓ Cà phê 30k ☕" thay vì "✓ 30k Cà phê" |
| 8 | Member names | ⏳ Pending — cần Shared Feed task (family actor resolution) |
| 9 | L10n keys | ✅ +2 keys: todaySpent, youActor |
