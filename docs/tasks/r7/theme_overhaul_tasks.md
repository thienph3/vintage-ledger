# Tasks: Theme Overhaul — Modern Soft Journal

Chuyển từ vintage (paper/ink/typewriter) sang modern soft (off-white/muted/clean sans-serif).

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | Đổi color palette | `app_colors.dart` | `paper` → off-white `#F8F8F6`. `inkBlue` → soft blue `#5B7FA2`. `inkPurple` → bỏ, dùng soft blue. `inkBlack` → `#3D3D3D`. `inkRed` → bỏ (avoid strong red). `income` → gentle green `#5BA37C`. `expense` → warm orange `#D4845A`. `divider` → light neutral `#E0DDD5`. Thêm: `surface` `#FFFFFF`, `textSecondary` `#8E8E8E`, `accent` warm orange `#E8A87C` |
| 2 | Đổi typography | `app_text_styles.dart` | Bỏ SpecialElite + PatrickHand. Primary: system sans-serif (hoặc Inter nếu bundle). Title: weight 600, body: weight 400. Numbers: clear, aligned. Bỏ tất cả `fontFamily: 'SpecialElite'` và `fontFamily: 'PatrickHand'` |
| 3 | Cập nhật spacing | `app_spacing.dart` | Thêm `md2: 12`. Generous spacing: section gaps `lg: 24` → `xl: 32` |
| 4 | Corner radius | `app_theme.dart` | Cards/inputs: `12` → `16`. Buttons: `24` → `20`. Consistent `16–20` everywhere |
| 5 | Card style | `ledger_card.dart`, `app_theme.dart` | Bỏ `divider` border. Subtle shadow only. Clean background `surface`. No heavy borders |
| 6 | Button style | `app_theme.dart` | Soft blue background, rounded 20. No harsh contrast. Outlined buttons: soft border |
| 7 | Input style | `app_theme.dart` | Lighter border color. Larger padding. Softer focus color |
| 8 | SnackBar style | `app_theme.dart` | Soft blue background (not dark). Rounded 16 |
| 9 | Dialog style | `app_theme.dart` | Rounded 20. Soft title. Generous padding |
| 10 | Bỏ font assets | `pubspec.yaml` | Remove SpecialElite + PatrickHand font files (hoặc giữ cho fallback) |
| 11 | Divider style | `app_theme.dart` | Lighter color, thinner (0.8) |
