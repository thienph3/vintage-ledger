# Feature: Soft Loading States

## Vấn đề
15 screens dùng raw `CircularProgressIndicator` — feels "fintech", not "journal".

## Giải pháp
Replace với `ShimmerPlaceholder` (đã có) hoặc soft inline indicator.

## Rules
- Full screen loading → ShimmerPlaceholder
- Inline loading (button, save) → small CircularProgressIndicator OK (nhưng dùng AppColors.primary)
- Pull-to-refresh → giữ RefreshIndicator (native feel)

## Screens to update
- transaction_list_screen → ShimmerPlaceholder
- wallet_detail_screen → ShimmerPlaceholder
- insights_tab → ShimmerPlaceholder
- account_picker_screen → ShimmerPlaceholder
- budget_list_screen → ShimmerPlaceholder
- category_list_screen → ShimmerPlaceholder
- family_detail_screen → ShimmerPlaceholder
- recurring_list_screen → ShimmerPlaceholder
