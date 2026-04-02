# Tasks: Smart Coaching (Contextual Guidance) — ✅

| # | Task | Status |
|---|------|--------|
| 1 | CoachingService | ✅ `lib/features/coaching/coaching_service.dart`: `getTip()` → `CoachingTip?` rule-based |
| 2 | CoachingTip model | ✅ `lib/features/coaching/coaching_tip.dart`: dismissKey, message, icon, actionLabel?, action? |
| 3 | Rule: No transactions | ✅ `monthly.isEmpty` → reuse `emptyTransactionHint` |
| 4 | Rule: Has txn, no budget | ✅ `monthly.length > 5 && budgetCount == 0` → "Bạn có muốn đặt ngân sách cho {topCategory}?" + action label |
| 5 | Rule: After 3+ days | ✅ `streak >= 3` → "Bạn đang chi nhiều nhất vào {topCategory} ☕" |
| 6 | Rule: Weekly comparison | ✅ `streak >= 7` → first half vs second half of month → "{pct}% more/less" |
| 7 | Dismiss tracking | ✅ `dismissed_tips` comma-separated in user settings. `dismiss(key)` persists. Tips check `_dismissed` set |
| 8 | CoachingCard widget | ✅ `lib/features/coaching/coaching_card.dart`: LedgerCard + icon + hint text + optional action link + X dismiss |
| 9 | Hiển thị trên Home | ✅ CoachingCard giữa InsightCard và TransactionSection. Load after dashboard, needs context |
| 10 | Priority ordering | ✅ no txn > no budget > top category > weekly. First non-dismissed tip returned |
| 11 | L10n keys | ✅ +4 keys vi/en: coachBudgetSuggestion, coachTopCategory, coachWeeklyMore, coachWeeklyLess |
