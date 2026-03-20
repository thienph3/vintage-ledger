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
- **smooth_page_indicator** — Page indicator

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
