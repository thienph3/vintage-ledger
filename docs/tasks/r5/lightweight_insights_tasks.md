# Tasks: Lightweight Insights

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | InsightService | `lib/features/insights/services/insight_service.dart` | `generateInsights()` → `List<Insight>` dựa trên monthly aggregation |
| 2 | Insight model | `lib/features/insights/models/insight.dart` | `{type, message, value, icon}` — enum type: topCategory, weeklyChange, savingsHighlight |
| 3 | Top category insight | `InsightService` | Query transactions tháng này, group by category, tìm max → "Bạn chi nhiều nhất vào {category} ({amount})" |
| 4 | Weekly comparison | `InsightService` | So sánh tổng chi tuần này vs tuần trước → "Tuần này bạn chi nhiều/ít hơn {x}%" |
| 5 | Savings insight | `InsightService` | income - expense > 0 → "Bạn đã tiết kiệm được {amount} 🎉" (reuse logic SavingsHighlight hiện tại) |
| 6 | InsightCard widget | `lib/features/insights/widgets/insight_card.dart` | LedgerCard + icon + 1 dòng text. Dismissible optional |
| 7 | Insights list trong InsightsTab | `insights_tab.dart` | ListView: InsightCards + ChartSection + BudgetSummaryCard |
| 8 | Optional highlight trên Home | `home_screen.dart` | Hiện 1 insight card nổi bật nhất (top category hoặc savings) |
| 9 | L10n keys | `app_vi.dart`, `app_en.dart` | +5 keys: topSpendingInsight, weeklyMore, weeklyLess, savingsInsight, noInsights |
