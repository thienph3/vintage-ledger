# Tasks: Interaction & Animation

Feedback tức thì, subtle, non-blocking. Animations 150–250ms.

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | Quick Add success animation | `quick_add_bar.dart` | Inline "Đã ghi ✓" fade animation thay vì SnackBar. 250ms fade in → 1s visible → 250ms fade out |
| 2 | Transaction add animation | `home_screen.dart` feed | Item mới slide in từ dưới (200ms). Smooth insert |
| 3 | Reaction pop animation | `reaction_picker.dart` | Emoji scale 0→1.2→1.0 (bounce, 200ms) khi chọn |
| 4 | Tab switch transition | `main_shell.dart` | Fade transition giữa tabs (150ms) thay vì instant switch |
| 5 | Pull-to-refresh | Tất cả list screens | Smooth, custom indicator phù hợp style (soft color) |
| 6 | Swipe delete feedback | `swipe_list_item.dart` | Softer red background → warm orange. Smoother animation |
| 7 | Button press feedback | `app_theme.dart` | Subtle scale down (0.98) on press. Soft ripple color |
| 8 | Loading states | Tất cả screens | Skeleton shimmer thay vì CircularProgressIndicator. Hoặc soft pulsing placeholder |
