# Tasks: Recurring Transactions — ✅

| # | Task | Status |
|---|------|--------|
| 1 | RecurringRule model | ✅ `lib/features/recurring/models/recurring_rule.dart`: amount, categoryId, walletId, type, frequency (daily/weekly/monthly), note, nextRunAt, enabled |
| 2 | RecurringRepository | ✅ `lib/features/recurring/repositories/recurring_rule_repository.dart`: extends FirestoreRepository, `getDueRules(now)` query |
| 3 | RecurringService | ✅ `lib/features/recurring/services/recurring_service.dart`: CRUD + `checkAndRun()` |
| 4 | Next run calculation | ✅ `calcNextRun()`: daily +1d, weekly +7d, monthly +1M |
| 5 | Duplicate prevention | ✅ `firestore.runTransaction`: read rule → check next_run_at → create txn + update wallet balance + update next_run_at atomically |
| 6 | Gọi khi mở app | ✅ `sl.recurringService.checkAndRun()` non-blocking trong `main.dart _init()` |
| 7 | Toggle trong TransactionForm | ✅ SwitchListTile "Lặp lại" + DropdownButton frequency. Khi save + toggle on → `createRule()` |
| 8 | RecurringListScreen | ✅ StreamBuilder watchRules, SwipeListItem delete, Switch toggle enabled, FAB add |
| 9 | RecurringFormScreen | ✅ TypeSelector + AmountInput + WalletDropdown + CategoryDropdown + FrequencyDropdown + Note |
| 10 | Firestore rules | ✅ `accounts/{accountId}/recurring_rules/{docId}`: CRUD if isMember, create validates amount > 0 |
| 11 | Firestore index | ✅ Composite: enabled ASC + next_run_at ASC |
| 12 | Settings entry | ✅ ListTile "GIAO DỊCH LẶP LẠI" → RecurringListScreen |
| 13 | L10n keys | ✅ +12 keys vi/en: recurring, recurringRules, noRecurring, addRecurring, editRecurring, daily, weekly, monthly, nextRun, frequency, deleteRecurring, deleteRecurringConfirm |
