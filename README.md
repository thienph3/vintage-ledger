# Vintage Ledger

A personal expense tracker with a vintage-style UI, built with Flutter.

## Features

- **Wallet Management** — Create multiple wallets, track balance per wallet
- **Income/Expense Transactions** — Record transactions with category, notes, and date
- **Custom Categories** — Create categories with optional Material icons
- **Charts** — Visualize income/expenses with charts (fl_chart)
- **Biometric Authentication** — Lock app with fingerprint/Face ID/Windows Hello (local_auth)
- **Multi-language** — Vietnamese / English, switchable in settings
- **Cross-platform** — Supports Android, iOS, Windows, Linux, macOS, Web

## Tech Stack

- **Flutter** (Dart)
- **SQLite** (sqflite + sqflite_common_ffi for desktop)
- **fl_chart** — Charts
- **local_auth** — Biometric authentication
- **google_fonts** — Fonts (SpecialElite, PatrickHand)
- **flutter_slidable** — Swipe actions

## Project Structure

```
lib/
├── core/
│   ├── constants/       # Shared constants (category icons, ...)
│   ├── l10n/            # Localization (vi, en) & S helper
│   ├── theme/           # App theme, colors, typography, spacing
│   └── database.dart    # SQLite database setup & migrations
├── common/
│   └── widgets/         # Reusable UI components
├── features/
│   ├── auth/            # Biometric lock screen
│   ├── category/        # Category CRUD (models, repos, services, screens, widgets)
│   ├── settings/        # Language settings (repos, services, screens)
│   ├── transaction/     # Transaction CRUD + charts
│   ├── wallet/          # Wallet CRUD
│   └── home_screen.dart # Main home screen
├── utils/               # Formatters (amount, date)
└── main.dart            # App entry point
```

## Getting Started

```bash
flutter pub get
flutter run
```

---

## Style Guide

All code and design must follow these conventions to maintain the vintage ledger identity.

### Color Palette (`AppColors`)

| Token       | Hex       | Usage                                    |
|-------------|-----------|------------------------------------------|
| `paper`     | `#FAF3E0` | Scaffold background, card fill, input bg |
| `inkBlue`   | `#1F3A5F` | Primary action, icons, focused borders   |
| `inkPurple` | `#4A2C5A` | Titles, input labels                     |
| `inkBlack`  | `#2B2B2B` | Body text, column headers                |
| `inkRed`    | `#8B1E1E` | Destructive / error accent               |
| `income`    | `#2E7D32` | Income amounts (green)                   |
| `expense`   | `#C62828` | Expense amounts (red)                    |
| `divider`   | `#8B6F47` | Dividers, card borders, subtle lines     |

### Typography (`AppTextStyles`)

Two fonts only:

- **SpecialElite** — titles, amounts, headlines, button labels (typewriter feel)
- **PatrickHand** — body text, hints, links, captions (handwritten feel)

| Style          | Font         | Size | Usage                              |
|----------------|--------------|------|------------------------------------|
| `title`        | SpecialElite | 24   | Section titles, screen headers     |
| `titleSmall`   | SpecialElite | 16   | Group headers, sub-titles          |
| `headline`     | SpecialElite | 20   | Lock screen, large emphasis        |
| `body`         | PatrickHand  | 18   | General text                       |
| `bodyBold`     | PatrickHand  | 18   | List item names, emphasis          |
| `bodySmall`    | PatrickHand  | 14   | Subtitles, secondary info          |
| `amount`       | SpecialElite | 18   | Currency values (colored by type)  |
| `caption`      | Default      | 10   | Chart labels, timestamps           |
| `hint`         | PatrickHand  | 16   | Empty states, placeholder text     |
| `link`         | PatrickHand  | 14   | "View all" action text             |
| `buttonLabel`  | SpecialElite | 18   | Button text                        |
| `columnHeader` | PatrickHand  | 18   | Table column headers               |
| `keypad`       | Default      | 22   | Amount keypad digits               |
| `error`        | PatrickHand  | 18   | Error messages                     |
| `emoji`        | Default      | 24   | Flag/emoji in settings             |
| `emojiLarge`   | Default      | 28   | Lock screen locale toggle          |

### Spacing (`AppSpacing`)

| Token | Value | Usage                        |
|-------|-------|------------------------------|
| `xs`  | 4     | Tight gaps (icon-text)       |
| `sm`  | 8     | Small gaps between elements  |
| `md`  | 16    | Standard padding, card inner |
| `lg`  | 24    | Section gaps                 |
| `xl`  | 32    | Large section separators     |

### Components

#### AppScaffold
Every screen uses `AppScaffold(title:, body:)`. When `title` is non-empty, a `LedgerHeader` is rendered as the AppBar with a vintage divider underneath. Pass `showBackButton: false` for root screens.

#### LedgerHeader
Custom AppBar with SpecialElite bold title + Divider bottom. Supports `actions` for trailing icons (e.g. settings gear).

#### LedgerCard
Standard content container: `paper` background, `divider` border at 0.4 alpha, 12px border radius, subtle drop shadow. Use for any grouped content block.

#### AmountText
Displays formatted currency with color by type: `income` → green, `expense` → red. Uses `AmountFormatter.formatCurrency()` (Vietnamese đồng format with `.` separator and `đ` suffix).

#### EmptyState
Centered hint-style text for empty lists.

#### SwipeListItem
Dismissible wrapper with red delete background. Supports `confirmDelete` dialog and `onTap` for edit.

### Layout Rules

1. **No inline `TextStyle()`** — always use `AppTextStyles.*` or `.copyWith()` from a base style
2. **No inline `Divider(color:)`** — use `const Divider()`, styled by `DividerTheme`
3. **No inline `ElevatedButton.styleFrom()`** for default buttons — theme handles bg/fg/padding/shape. Only override for variant buttons (e.g. filter pills)
4. **No inline `FloatingLabelBehavior`** — set in `InputDecorationTheme`
5. **Scaffold background** is always `paper` (set in theme)
6. **Border radius** is `12` for cards/inputs/buttons, `24` for pill-shaped buttons
7. **All imports** use `package:vintage_ledger/...` style (no relative imports)

### Screen Patterns

- **List screens** (wallets, categories): `AppScaffold` + `RefreshIndicator` + `ListView` with `SwipeListItem` rows + bottom `ElevatedButton.icon` to add
- **Form screens** (wallet form, category form, transaction form): `AppScaffold` + `Form` + `ListView` of fields + bottom `ElevatedButton` to save
- **Detail screens** (wallet detail): `AppScaffold` + `ListView` of `LedgerCard` sections
- **Home screen**: `AppScaffold` + vertical `ListView` with balance card → wallet horizontal scroll → chart → recent transactions + FAB

### Localization

- Default locale: `vi` (Vietnamese)
- All user-facing strings use `S.of(context, 'key')` — never hardcode text
- Keys defined in `lib/core/l10n/app_vi.dart` and `app_en.dart`
- Screen titles are UPPERCASE in l10n values (e.g. `'SỔ THU CHI'`)

### Data Layer

- **Architecture**: Repository → Service → Screen (feature-first)
- **Database**: Single `AppDatabase` singleton, SQLite via sqflite
- **Queries**: Always filter at DB level (date range, limit) — never load all then filter client-side
- **Lazy loading**: `transaction_list_screen` loads one month at a time, loads more on scroll
