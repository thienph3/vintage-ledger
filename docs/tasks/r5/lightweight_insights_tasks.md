# Tasks: Lightweight Insights — ✅

| # | Task | Status |
|---|------|--------|
| 1 | InsightService | ✅ `lib/features/insights/services/insight_service.dart`: `generate()` → `List<Insight>` từ DashboardData + last week txns |
| 2 | Insight model | ✅ `lib/features/insights/models/insight.dart`: type (topCategory/weeklyChange/savings), message (encoded), icon, color |
| 3 | Top category insight | ✅ Sort expenseByCategory → top entry → "Bạn chi nhiều nhất vào {category} ({amount})" |
| 4 | Weekly comparison | ✅ This week vs last week expense → "Tuần này bạn chi nhiều/ít hơn {pct}%" (skip if < 5%) |
| 5 | Savings insight | ✅ income - expense > 0 → "Bạn đã tiết kiệm được {amount} 🎉" |
| 6 | InsightCard widget | ✅ `lib/features/insights/widgets/insight_card.dart`: LedgerCard + icon + resolved l10n message |
| 7 | Insights list trong InsightsTab | ✅ InsightCards trước ChartSection + BudgetSummaryCard + StreakCard. Load last week for weekly comparison |
| 8 | Highlight trên Home | ✅ Top insight (first) hiện giữa WalletRow và TransactionSection |
| 9 | L10n keys | ✅ +5 keys vi/en: topSpendingInsight, weeklyMore, weeklyLess, savingsInsight, noInsights |
