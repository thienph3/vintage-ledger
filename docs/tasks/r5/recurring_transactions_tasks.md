# Tasks: Recurring Transactions

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | RecurringRule model | `lib/features/recurring/models/recurring_rule.dart` | `{id, amount, categoryId, walletId, type, frequency, note, nextRunAt, enabled}`. Frequency enum: daily, weekly, monthly |
| 2 | RecurringRepository | `lib/features/recurring/repositories/recurring_rule_repository.dart` | Extends `FirestoreRepository<RecurringRule>`, collection `recurring_rules` dưới account |
| 3 | RecurringService | `lib/features/recurring/services/recurring_service.dart` | `checkAndRun()`: query rules where `next_run_at <= now` + `enabled == true` → tạo transaction + update `next_run_at` |
| 4 | Next run calculation | `RecurringService` | `_calcNextRun(frequency, current)`: daily +1d, weekly +7d, monthly +1M (handle 28/29/30/31) |
| 5 | Duplicate prevention | `RecurringService` | Dùng `firestore.runTransaction`: read rule → check next_run_at → create txn + update rule atomically |
| 6 | Gọi khi mở app | `main.dart` | `RecurringService.checkAndRun()` non-blocking trong `_init()` |
| 7 | Toggle trong TransactionForm | `transaction_form_screen.dart` | SwitchListTile "Lặp lại" + DropdownButton frequency (Hàng ngày / Hàng tuần / Hàng tháng). Khi save + toggle on → tạo RecurringRule |
| 8 | RecurringListScreen | `lib/features/recurring/screens/recurring_list_screen.dart` | AppScaffold + ListView of rules. SwipeListItem delete. Toggle enabled. Navigate từ Settings |
| 9 | RecurringFormScreen | `lib/features/recurring/screens/recurring_form_screen.dart` | Edit rule: amount, category, wallet, frequency, note, enabled |
| 10 | Firestore rules | `firestore.rules` | `accounts/{accountId}/recurring_rules/{docId}`: CRUD if isMember |
| 11 | Firestore index | `firestore.indexes.json` | Composite: `enabled` ASC + `next_run_at` ASC |
| 12 | Settings entry | `setting_screen.dart` | ListTile "Giao dịch lặp lại" → navigate RecurringListScreen |
| 13 | L10n keys | `app_vi.dart`, `app_en.dart` | +8 keys: recurring, daily, weekly, monthly, recurringRules, noRecurring, nextRun, enableRecurring |
