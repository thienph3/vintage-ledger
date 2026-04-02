# Tasks: Home V2 — Simplified Dashboard

| # | Task | Status |
|---|------|--------|
| 1 | MainShell với BottomNavigationBar | ✅ `lib/features/main_shell.dart`: 4 tabs (Home, Transactions, Insights, Settings), IndexedStack giữ state |
| 2 | Rút gọn HomeScreen | ✅ Chỉ giữ: BalanceCard, WalletRow, Recent Transactions, QuickAddBar. Bỏ: ChartSection, BudgetSummaryCard, SavingsHighlight, StreakCard, LoginPromptCard |
| 3 | TransactionListScreen trong tab | ✅ `showBackButton: widget.walletId != null` — ẩn back khi tab mode, hiện khi pushed |
| 4 | InsightsTab | ✅ `lib/features/insights/screens/insights_tab.dart`: ChartSection + BudgetSummaryCard + SavingsHighlight + StreakCard |
| 5 | SettingScreen trong tab | ✅ `showBackButton: false` |
| 6 | Cập nhật main.dart | ✅ `_buildHome()` return `MainShell` thay vì `HomeScreen` |
| 7 | AccountPicker → MainShell | ✅ `_selectAccount` navigate đến `MainShell` |
| 8 | Bỏ settings icon khỏi Home AppBar | ✅ Chỉ giữ swap_horiz (đổi account) |
| 9 | NotificationService → MainShell | ✅ `_handleTap` navigate đến `MainShell` |
| 10 | L10n keys | ✅ +4 keys: tabHome, tabTransactions, tabInsights, tabSettings |
