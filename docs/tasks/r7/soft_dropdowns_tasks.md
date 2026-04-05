# Tasks: Soft Dropdowns (H2)

> Native `DropdownButtonFormField` phá vỡ soft style.
> Thay bằng tappable field → `SelectionSheet` (bottom sheet picker).

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | Create `DropdownField` widget | `lib/common/widgets/dropdown_field.dart` | Tappable `InputDecorator` (label + value + trailing icon) → mở SelectionSheet. Reusable cho tất cả forms |
| 2 | TransactionFormScreen wallet | `transaction_form_screen.dart` | `_buildWalletDropdown()` → `DropdownField` + SelectionSheet |
| 3 | TransactionFormScreen member | `transaction_form_screen.dart` | `_buildMemberDropdown()` → `DropdownField` + SelectionSheet |
| 4 | BudgetFormScreen category | `budget_form_screen.dart` | Category dropdown → `DropdownField` + SelectionSheet |
| 5 | RecurringFormScreen wallet | `recurring_form_screen.dart` | Wallet dropdown → `DropdownField` + SelectionSheet |
| 6 | RecurringFormScreen frequency | `recurring_form_screen.dart` | Frequency dropdown → `DropdownField` + SelectionSheet |
| 7 | CategoryDropdown widget | `category_dropdown.dart` | Thay `DropdownButtonFormField` → `DropdownField` + SelectionSheet. Giữ "Add category" option |
