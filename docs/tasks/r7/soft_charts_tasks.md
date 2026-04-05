# Tasks: Soft Charts

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | Chart color palette | `app_colors.dart` | Add `chartColors` list: 6 muted tones derived from primary/income/expense at various alpha |
| 2 | chart_section.dart | `chart_section.dart` | Tab labels → `AppTextStyles.caption`. Background → transparent |
| 3 | trend_chart | `chart/trend_chart.dart` | Line colors → `AppColors.income`/`expense`. Grid → `AppColors.divider`. Axis labels → `AppTextStyles.caption` |
| 4 | daily_chart | `chart/daily_chart.dart` | Bar colors → `AppColors.income`/`expense` at 0.7 alpha. Soft rounded bars |
| 5 | breakdown_chart | `chart/breakdown_chart.dart` | Pie colors → `chartColors` palette. Legend → `AppTextStyles.caption` |
| 6 | summary_chart | `chart/summary_chart.dart` | Colors → AppColors. Text → AppTextStyles |
| 7 | Budget progress bars | `budget_summary_card.dart`, `budget_list_screen.dart` | Progress colors → `income` (under), `accent` (near), `expense` (over). Background → `divider` |
