# Tasks: Insight & Budget

> Giúp user hiểu và kiểm soát tiền. Nền tảng cho Premium monetization.

## Phụ thuộc
- Data Layer V2 ✅

## Tasks

| # | Task | Mô tả | Status |
|---|------|--------|--------|
| 1 | Budget model | `Budget` (id, categoryId, amountLimit, period) + `BudgetStatus` (budget + spent + percentage + isExceeded/isNearLimit) | ✅ |
| 2 | BudgetRepository + BudgetService | Firestore CRUD, upsert per category, `getBudgetStatuses()` tính % used, `checkBudget()` cho single category | ✅ |
| 3 | BudgetFormScreen + BudgetListScreen | Form: chọn category expense + nhập limit. List: progress bars + swipe delete + add button | ✅ |
| 4 | Budget tracking | `getBudgetStatuses()` tính spent = tổng expense transactions tháng này per category / budget limit | ✅ |
| 5 | Budget progress UI | `BudgetProgressTile`: progress bar xanh < 80%, vàng 80-100%, đỏ > 100% + spent/remaining text | ✅ |
| 6 | Monthly insight screen | `MonthlyInsightScreen`: tổng thu/chi/net, top 3 spending categories, vs last month trend | ✅ |
| 7 | Budget widget trên Home | `BudgetSummaryCard`: hiển thị budgets gần/vượt limit + link đến BudgetList + Insight | ✅ |
| 8 | Budget alert | Warning trong TransactionFormScreen khi chọn category gần/vượt budget (icon + text) | ✅ |
| 9 | Spending trend | Bar chart so sánh chi tiêu tháng này vs tháng trước per category trong MonthlyInsightScreen | ✅ |
| 10 | Budget sync | Firestore-first via `FirestoreRepository` base — auto sync | ✅ |
| 11 | Premium gate | `PremiumGate.isUnlocked` placeholder — sẵn sàng wrap screens khi có monetization | ✅ |
| 12 | L10n keys | 14 keys: budget, budgets, setBudget, editBudget, budgetLimit, budgetExceeded, budgetNearLimit, remaining, spent, noBudgets, monthlyInsight, vsLastMonth, topSpending, budgetWarning | ✅ |
