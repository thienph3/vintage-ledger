# Tasks: UI Polish (M1–M7)

> Medium priority polish items cho consistent soft journal feel.

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | LedgerHeader bottom divider | `ledger_header.dart` | Thêm `bottom: PreferredSize(child: Divider())` vào AppBar. Style guide: "Divider bottom" |
| 2 | TypeSelector soft selected state | `type_selector.dart` | Selected: `primary.withValues(alpha: 0.12)` bg + `primary` text. Thay vì solid primary bg + white text |
| 3 | SelectionSheet radius 16 + drag handle | `selection_sheet.dart` | Item shape radius 12 → 16. Thêm drag handle indicator (Container 40x4, divider color, radius 2) ở top |
| 4 | QuickAddBar wallet chip color | `quick_add_bar.dart` | `AppColors.divider` → `AppColors.textSecondary` cho wallet chip icon + text |
| 5 | SettingScreen hide debug | `setting_screen.dart` | Debug section chỉ hiện khi tap 5 lần vào version text (hoặc long-press section label) |
| 6 | TransactionListScreen day number size | `transaction_list_screen.dart` | Day number `title fontSize 20` → `titleSmall` (16). Vẫn bold nhưng không quá to |
| 7 | WalletDetailScreen income/expense summary | `wallet_detail_screen.dart` | Thêm `IncomeExpenseSummaryRow` dưới balance card (stream từ dashboard hoặc tính từ recent txns) |
