# Vintage Ledger

A personal expense tracker with a vintage-style UI, built with Flutter.

## Features

- **Wallet Management** — Create multiple wallets, track balance per wallet
- **Income/Expense Transactions** — Record transactions with category, notes, and date
- **Custom Categories** — Create categories with optional Material icons
- **Charts** — Visualize income/expenses with charts (fl_chart)
- **Biometric Authentication** — Lock app with fingerprint/Face ID/Windows Hello (local_auth)
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
├── models/          # Data models (Wallet, Transaction, Category)
├── repositories/    # Database CRUD operations
├── services/        # Business logic layer
├── screens/         # UI screens (Home, Wallet, Transaction, Category, Auth)
├── widgets/         # Reusable UI components
├── theme/           # App theme, colors, typography, spacing
├── utils/           # Formatters, navigation helpers
├── database.dart    # SQLite database setup & migrations
└── main.dart        # App entry point
```

## Getting Started

```bash
flutter pub get
flutter run
```
