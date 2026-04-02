# Tasks: Home V2 — Simplified Dashboard

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | Tạo MainShell với BottomNavigationBar | `lib/features/main_shell.dart` | 4 tabs: Home, Transactions, Insights, Settings. Dùng `IndexedStack` giữ state |
| 2 | Rút gọn HomeScreen | `lib/features/home/screens/home_screen.dart` | Chỉ giữ: BalanceCard, WalletRow, Recent Transactions (5 items), QuickAddBar. Bỏ: ChartSection, BudgetSummaryCard, SavingsHighlight, StreakCard, LoginPromptCard |
| 3 | Tạo TransactionsTab | `lib/features/transaction/screens/transactions_tab.dart` | Reuse TransactionListScreen (all wallets mode), QuickAddBar ở bottom |
| 4 | Tạo InsightsTab | `lib/features/insights/screens/insights_tab.dart` | Gom: ChartSection, BudgetSummaryCard, SavingsHighlight, StreakCard. ListView scrollable |
| 5 | Di chuyển Settings vào tab | `lib/features/settings/screens/setting_screen.dart` | Bỏ navigate từ HomeScreen actions, setting là tab thứ 4 |
| 6 | Cập nhật navigation | `main.dart`, `_buildHome()` | Return `MainShell` thay vì `HomeScreen` trực tiếp |
| 7 | Giữ AccountPicker flow | `account_picker_screen.dart` | Sau chọn account → navigate đến `MainShell` thay vì `HomeScreen` |
| 8 | Bỏ settings icon khỏi AppBar Home | `home_screen.dart` | Chỉ giữ swap_horiz (đổi account) nếu logged in |
| 9 | Tab badge (optional) | `MainShell` | Badge đỏ trên Insights tab nếu có budget exceeded |
| 10 | L10n keys | `app_vi.dart`, `app_en.dart` | +4 keys: tabHome, tabTransactions, tabInsights, tabSettings |
