# Vintage Ledger — Style Guides

> A soft, modern interface that feels like a shared daily journal — not a finance tool.

---

## Guides

| Guide | Covers |
|-------|--------|
| [Design](design.md) | Philosophy, colors, typography, spacing, components, content tone, gestures, animations, screen structure, anti-patterns |
| [Coding](coding.md) | Architecture, base classes, reusable widgets, data access, screen patterns, state management, error handling, imports, naming, l10n, DRY, bootstrap/auth flow |

---

## Quick Reference

### Colors
`background` `surface` `primary` `accent` `textPrimary` `textSecondary` `income` `expense` `divider` `error`

### Typography
`title` `titleSmall` `headline` `body` `bodyBold` `bodySmall` `amount` `caption` `hint` `error` `buttonLabel` `link`

### Spacing
`xs(4)` `sm(8)` `md2(12)` `md(16)` `lg(24)` `xl(32)`

### Gestures
Tap = primary · Long press = secondary · Swipe = delete · Pull = refresh

### Architecture
`Screen → Service → Repository → Firestore` · Cache for 3+ screens · Stream for realtime

### Key Rules
* No inline styles — use `AppColors`, `AppTextStyles`, `AppSpacing`
* No relative imports — use `package:vintage_ledger/...`
* No hardcoded strings — use `S.of(context, 'key')`
* No `CircularProgressIndicator` — use `ShimmerPlaceholder`
* No direct repository calls from screens — go through services
* All auth transitions through `SplashBootstrapScreen`
