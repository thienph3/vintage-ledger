# Feature: Form Screens Style Migration

## Vấn đề
22 old patterns trong form screens: legacy colors, radius 12, heavy section titles.

## Screens
- budget_form_screen
- budget_list_screen
- monthly_insight_screen
- category_form_screen
- category_list_screen
- recurring_form_screen
- recurring_list_screen
- family_detail_screen
- family_form_screen
- account_picker_screen
- transaction_form_screen

## Changes per screen
- `AppColors.inkBlue` → `AppColors.primary`
- `AppColors.inkRed` → `AppColors.expense`
- `circular(12)` → `circular(16)`
- Section titles: `AppTextStyles.titleSmall` thay `AppTextStyles.title`
- Buttons: rely on theme (no inline styleFrom)
- Consistent padding `AppSpacing.md`
