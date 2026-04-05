# Feature: Soft Charts

## Vấn đề
Chart widgets dùng 21 hardcoded colors — aggressive, "fintech" feel.

## Giải pháp
- Migrate tất cả chart colors → AppColors palette (muted tones)
- Bar charts: dùng `primary` + `income` + `expense` (soft)
- Pie/breakdown: dùng muted palette (primary variants at different alpha)
- Axis labels: `AppTextStyles.caption`
- Grid lines: `AppColors.divider`
- Bỏ aggressive gradients nếu có

## Style guide check
- "Avoid aggressive charts" ✓
- "Soft over Sharp" ✓
- "Easy to scan in 3 seconds" ✓
