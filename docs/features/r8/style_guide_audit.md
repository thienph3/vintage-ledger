# Feature: Style Guide Compliance Audit (R8)

## Violations Found

### 1. Direct Repository Calls from Screens

Coding guide §1: "Screen không gọi repository trực tiếp — luôn qua service"

| File | Violation |
|------|-----------|
| `home_screen.dart` | `TransactionRepository().watchByDateRange(...)` |
| `transaction_list_screen.dart` | `TransactionRepository()` field |
| `insights_tab.dart` | `TransactionRepository().getByDateRange(...)` |
| `wallet_detail_screen.dart` | `TransactionRepository().watchRecent(...)` |
| `monthly_insight_screen.dart` | `TransactionRepository()` |

### 2. Fetching Cached Data

Coding guide §4: "Data dùng bởi 3+ screens → AppCache"

| File | Violation |
|------|-----------|
| `category_list_screen.dart` | `sl.categoryService.getCategories()` |
| `recurring_list_screen.dart` | `sl.categoryService.getCategories()` |
| `wallet_detail_screen.dart` | `sl.categoryService.getCategories()` |
| `transaction_form_screen.dart` | `sl.settingService.getLastWalletId()`, `sl.accountService.getAccount(...)` |
| `recurring_form_screen.dart` | `sl.categoryService.getCategoriesByType(...)` |

### 3. CircularProgressIndicator Instead of Shimmer

Design guide §5.6: "Never use bare CircularProgressIndicator"

| File | Context |
|------|---------|
| `quick_add_bar.dart` | Saving spinner (acceptable — inline action indicator) |
| `family_form_screen.dart` | Full-screen loading |
| `setting_screen.dart` | Tile loading indicator |

### 4. Inline TextStyle

Design guide §3: "No inline TextStyle() — always use AppTextStyles.*"

| File | Line |
|------|------|
| `reaction_picker.dart` | `TextStyle(fontSize: 24)` — should use `AppTextStyles.emoji` |
| `calendar_grid.dart` | `TextStyle(fontSize: 9, ...)` — needs new `AppTextStyles` token |
| `insights_tab.dart` | `TextStyle(fontSize: 20)` — should use `AppTextStyles.emoji` |
| `empty_state.dart` | `TextStyle(fontSize: 40)` — needs `AppTextStyles.emojiXl` |

### 5. Non-standard Border Radius

Design guide §4: radius should be 16/20/24, small elements 4/8/12

| File | Value | Should be |
|------|-------|-----------|
| `calendar_grid.dart` | 8 | OK (small cell) |
| `reaction_bar.dart` | 12 | OK (small pill) |
| `splash_bootstrap_screen.dart` | 4 | OK (progress bar) |
| `type_selector.dart` | 12 | OK (small toggle) |
| `selection_sheet.dart` | 2 | Should be 4 (handle) |
