# Tasks: Migrate Legacy Tokens

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | wallet_list_screen | `wallet_list_screen.dart` | `inkBlue` → `primary`, `inkRed` → `expense`, `circular(12)` → `circular(16)`, star `Color(0xFFE6A817)` → `AppColors.accent` |
| 2 | wallet_detail_screen | `wallet_detail_screen.dart` | `inkBlue` → `primary` |
| 3 | category_list_screen | `category_list_screen.dart` | `inkBlue` → `primary`, `inkRed` → `expense`, `circular(12)` → `circular(16)` |
| 4 | category_form_screen | `category_form_screen.dart` | `inkBlue` → `primary` |
| 5 | budget_form_screen | `budget_form_screen.dart` | `inkBlue` → `primary`, `circular(12)` → `circular(16)` |
| 6 | budget_list_screen | `budget_list_screen.dart` | `inkBlue` → `primary`, hardcoded progress colors → `AppColors.income`/`expense` |
| 7 | monthly_insight_screen | `monthly_insight_screen.dart` | Hardcoded chart colors → AppColors, `circular(12)` → `circular(16)` |
| 8 | recurring_list_screen | `recurring_list_screen.dart` | `inkBlue` → `primary`, `circular(12)` → `circular(16)` |
| 9 | recurring_form_screen | `recurring_form_screen.dart` | `inkBlue` → `primary` |
| 10 | family_detail_screen | `family_detail_screen.dart` | `inkBlue` → `primary`, `inkRed` → `expense`, `inkBlack` → `textPrimary` |
| 11 | family_form_screen | `family_form_screen.dart` | `inkBlue` → `primary` |
| 12 | account_picker_screen | `account_picker_screen.dart` | `inkBlue` → `primary` |
| 13 | login_screen | `login_screen.dart` | `paper` → `background` (verify) |
| 14 | home_screen wallet cards | `home_screen.dart` | `paper` → `background`, star color → `accent`, `circular(12)` → `circular(16)` |
| 15 | chart widgets | `chart_section.dart`, `chart/*.dart` | All hardcoded `Color(0xFF...)` → AppColors palette |
| 16 | transaction_form_screen | `transaction_form_screen.dart` | `inkBlue` → `primary` |
| 17 | Remove legacy aliases | `app_colors.dart` | Delete `paper`, `inkBlue`, `inkPurple`, `inkBlack`, `inkRed` aliases (after all above done) |
