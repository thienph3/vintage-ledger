# Tasks: Smart Coaching (Contextual Guidance)

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | CoachingService | `lib/features/coaching/coaching_service.dart` | `getCoachingTip(context)` → `CoachingTip?` dựa trên user lifecycle |
| 2 | CoachingTip model | `lib/features/coaching/coaching_tip.dart` | `{message, icon, action, dismissKey}` — action: nullable callback (navigate budget, etc.) |
| 3 | Rule: No transactions | `CoachingService` | txnCount == 0 → "Thử nhập 'ăn sáng 30k' 👇" (reuse emptyTransactionHint) |
| 4 | Rule: Has txn, no budget | `CoachingService` | txnCount > 5 && budgetCount == 0 → "Bạn có muốn đặt ngân sách cho {topCategory} không?" |
| 5 | Rule: After 3+ days | `CoachingService` | streak >= 3 → "Bạn đang chi nhiều nhất vào {topCategory} ☕" |
| 6 | Rule: Weekly comparison | `CoachingService` | streak >= 7 → "Tuần này bạn chi nhiều/ít hơn {x}% so với tuần trước" |
| 7 | Dismiss tracking | `SettingService` | `dismissed_tips` list trong user settings. Mỗi tip có unique key, dismissed → không hiện lại |
| 8 | CoachingCard widget | `lib/features/coaching/coaching_card.dart` | LedgerCard + icon + message + optional action button + dismiss (X). Dùng `AppTextStyles.hint` |
| 9 | Hiển thị trên Home | `home_screen.dart` | Gọi `CoachingService.getCoachingTip()` trong `_loadDashboard()`, hiện CoachingCard trước Recent Transactions |
| 10 | Priority ordering | `CoachingService` | Chỉ hiện 1 tip tại 1 thời điểm. Priority: no txn > no budget > top category > weekly comparison |
| 11 | L10n keys | `app_vi.dart`, `app_en.dart` | +4 keys: coachBudgetSuggestion, coachTopCategory, coachWeeklyMore, coachWeeklyLess |
