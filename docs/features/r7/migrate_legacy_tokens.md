# Feature: Migrate Legacy Colors & Radius

## Vấn đề
38 references dùng legacy color aliases (inkBlue, inkRed, paper...) + 17 hardcoded Color(0xFF...) + 8 places radius 12.

## Giải pháp
Batch replace tất cả → semantic AppColors tokens + radius 16.

## Scope
- `inkBlue` → `primary`
- `inkRed` → `expense` hoặc `error`
- `inkBlack` → `textPrimary`
- `inkPurple` → `primary`
- `paper` → `background`
- `Color(0xFFE6A817)` (star) → `AppColors.accent`
- `Colors.red` → `AppColors.expense`
- `Colors.grey` → `AppColors.textSecondary`
- `circular(12)` → `circular(16)`
- Chart hardcoded colors → AppColors palette

## Files affected
- wallet_list_screen, wallet_detail_screen
- category_list_screen, category_form_screen
- budget screens (form, list, monthly_insight)
- recurring screens
- family_detail_screen, account_picker_screen
- login_screen
- chart widgets (chart_section, breakdown_chart, trend_chart, daily_chart, summary_chart)
