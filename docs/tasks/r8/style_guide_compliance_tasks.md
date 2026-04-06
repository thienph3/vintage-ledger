# Tasks: Style Guide Compliance (R8)

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | Route TransactionRepository calls through service | `transaction_service.dart`, 5 screens | Add `watchByDateRange`, `watchRecent`, `getByDateRange` to TransactionService. Screens call `sl.transactionService.*` instead of `TransactionRepository()` |
| 2 | Read cached data instead of fetching | `category_list_screen.dart`, `recurring_list_screen.dart`, `wallet_detail_screen.dart`, `transaction_form_screen.dart`, `recurring_form_screen.dart` | Use `sl.cache.categories` / `sl.cache.lastWalletId` / `sl.cache.currentAccount` / `sl.cache.memberProfiles`. Fetch only for type-filtered subsets not in cache |
| 3 | Replace CircularProgressIndicator | `family_form_screen.dart` | Replace full-screen `CircularProgressIndicator` with `ShimmerPlaceholder` |
| 4 | Fix inline TextStyle | `reaction_picker.dart`, `calendar_grid.dart`, `insights_tab.dart`, `empty_state.dart` | Use `AppTextStyles.emoji` for emoji text. Add `calendarExpense` style to AppTextStyles for calendar grid 9px text |
