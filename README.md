# Vintage Ledger

A family expense tracker with a vintage-style UI, built with Flutter and Firebase.

## Features

### Core
- **Multi-Wallet Management** — Create and manage multiple wallets, track balance per wallet
- **Income/Expense Transactions** — Record transactions with categories, notes, items, and date/time
- **Transfer Between Wallets** — Internal transfers and cross-account transfers
- **Custom Categories** — Create categories with Material icons for income/expense
- **Budgets** — Set monthly spending limits per category with progress tracking
- **Recurring Transactions** — Automate daily/weekly/monthly transactions

### Family & Collaboration
- **Family Accounts** — Share wallets and transactions with family members
- **Activity Feed** — See who added what, with reactions (👍❤️😂)
- **Member Profiles** — Track who created each transaction
- **Invitations** — Invite family members via email
- **Notifications** — Real-time push notifications for family activities

### Goals & Debts (V2)
- **Goal Tracking** — Save for 9 categories (vacation, education, emergency, etc.) with any wallet
- **Goal Contributions** — Track deposits/withdrawals with history
- **Auto-Saving Rules** — Automated recurring contributions
- **Debt Management** — Track money lent/borrowed with payment schedules
- **Debt Payments** — Record partial/full payments with progress tracking

### Insights & Analytics
- **Charts** — 4 chart types (trend, daily, breakdown, summary) with fl_chart
- **Dashboard** — Monthly income/expense overview with category breakdown
- **Smart Insights** — AI-generated spending insights and coaching tips
- **Streak Tracking** — Daily usage streaks with fire emoji 🔥

### UX & Security
- **Biometric Lock** — Fingerprint/Face ID/Windows Hello (local_auth)
- **Quick Add Bar** — Fast transaction entry with wallet selector and suggestions
- **Quick Actions FAB** — 4 quick actions (transaction, funding, savings, pay debt)
- **Multi-language** — Vietnamese (default) / English
- **Offline Support** — Works offline with Firestore cache
- **Cross-platform** — Android, iOS, Windows, Linux, macOS, Web

## Tech Stack

### Frontend
- **Flutter** (Dart) — Cross-platform UI framework
- **google_fonts** — SpecialElite (typewriter) + PatrickHand (handwritten)
- **fl_chart** — Beautiful charts
- **local_auth** — Biometric authentication
- **flutter_slidable** — Swipe-to-delete actions

### Backend
- **Firebase Firestore** — NoSQL cloud database with realtime sync
- **Firebase Cloud Messaging** — Push notifications
- **Firebase Security Rules** — Server-side access control

### Architecture
- **Feature-first** — Organized by feature (wallet, transaction, goal, debt, etc.)
- **Repository pattern** — Service → Repository → Firestore
- **Stream-based** — Realtime updates with StreamBuilder
- **Localization** — S helper with vi/en locale files

## Project Structure

```
lib/
├── core/
│   ├── constants/          # Category icons, currency
│   ├── l10n/               # Localization (app_vi.dart, app_en.dart, s.dart)
│   ├── theme/              # AppColors, AppTextStyles, AppSpacing, theme.dart
│   ├── enums/              # TransactionType, etc.
│   ├── firestore/          # FirestoreRepository base class
│   ├── bootstrap/          # App initialization & auth flow
│   ├── service_locator.dart # Dependency injection (GetIt)
│   └── app_state.dart      # Global state (currentAccountId, currentUserId)
├── common/
│   └── widgets/            # Reusable UI (AppScaffold, LedgerCard, AmountText, etc.)
├── features/
│   ├── account/            # Family account management
│   ├── auth/               # Biometric lock screen
│   ├── budget/             # Budget CRUD + tracking
│   ├── category/           # Category CRUD
│   ├── debt/               # Debt V2 (lend/borrow + payments)
│   ├── goal/               # Goal V2 (savings goals + contributions + auto-saving)
│   ├── home/               # Home screen with dashboard
│   ├── insights/           # Insights tab with charts + coaching
│   ├── notification/       # FCM notification handling
│   ├── quick_add/          # Quick add bar + suggestions
│   ├── recurring/          # Recurring transaction rules
│   ├── settings/           # Settings screen + language picker
│   ├── transaction/        # Transaction CRUD + charts + feed
│   ├── transfer/           # Transfer V2 (internal/funding/cross-account)
│   ├── wallet/             # Wallet CRUD
│   └── main_shell.dart     # Bottom navigation (4 tabs)
├── utils/                  # AmountFormatter, DateFormatter
└── main.dart               # App entry point

docs/
├── style_guides/           # Design & coding style guides (see below)
├── features/               # Feature specs by release (r3-r10)
├── tasks/                  # Implementation task lists
└── reviews/                # Code review reports

firestore.rules             # Firestore security rules
firestore.indexes.json      # Composite indexes for queries
```

## Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Firebase project with Firestore + FCM enabled
- `google-services.json` (Android) / `GoogleService-Info.plist` (iOS)

### Installation

```bash
# Clone repo
git clone <repo-url>
cd vintage-ledger

# Install dependencies
flutter pub get

# Run app
flutter run
```

### Firebase Setup

1. Create Firebase project at https://console.firebase.google.com
2. Enable Firestore Database
3. Enable Cloud Messaging
4. Download config files and place in:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
5. Deploy Firestore rules:
   ```bash
   firebase deploy --only firestore:rules
   firebase deploy --only firestore:indexes
   ```

## Style Guides

All code and design must follow the style guides in `docs/style_guides/`:

- **[Design Guide](docs/style_guides/design.md)** — Colors, typography, spacing, components, content tone, gestures, animations, screen structure
- **[Coding Guide](docs/style_guides/coding.md)** — Architecture, patterns, state management, error handling, imports, naming, localization

### Quick Reference

**Colors**: `background` `surface` `primary` `accent` `textPrimary` `textSecondary` `income` `expense` `divider` `error`

**Typography**: `title` `titleSmall` `headline` `body` `bodyBold` `bodySmall` `amount` `caption` `hint` `error` `buttonLabel` `link`

**Spacing**: `xs(4)` `sm(8)` `md2(12)` `md(16)` `lg(24)` `xl(32)`

**Key Rules**:
- No inline styles — use `AppColors`, `AppTextStyles`, `AppSpacing`
- No relative imports — use `package:vintage_ledger/...`
- No hardcoded strings — use `S.of(context, 'key')`
- No `CircularProgressIndicator` — use `ShimmerPlaceholder`
- No direct repository calls from screens — go through services

## Data Layer

### Architecture
```
Screen → Service → Repository → Firestore
         ↓
      Cache (for 3+ screens)
```

### Collections

```
accounts/{accountId}
├── wallets/{walletId}
├── transactions/{txnId}
│   └── reactions/{userId}
├── categories/{categoryId}
├── budgets/{budgetId}
├── debts_v2/{debtId}
│   └── payments/{paymentId}
├── goals_v2/{goalId}
│   └── contributions/{contributionId}
├── auto_saving_rules/{ruleId}
├── transfers_v2/{transferId}
├── transfer_shortcuts/{shortcutId}
├── recurring_rules/{ruleId}
├── activities/{activityId}
└── notification_events/{eventId}

users/{userId}
├── settings/{docId}
└── fcm_tokens/{tokenId}

pending_invites/{inviteId}
user_emails/{email}
```

### Firestore Patterns

- **Realtime**: Use `Stream<T>` with `watchAll()` / `watchById()` for live updates
- **One-shot**: Use `Future<T>` with `getAll()` / `getById()` for static data
- **Transactions**: Use `firestore.runTransaction()` for atomic wallet balance updates
- **Batch writes**: Use `batch.commit()` for multi-document writes
- **Queries**: Always filter at DB level with `where()` + `orderBy()` + `limit()`
- **Indexes**: Composite indexes required for multi-field queries (see `firestore.indexes.json`)

## Localization

- **Default locale**: `vi` (Vietnamese)
- **Supported locales**: `vi`, `en`
- **Usage**: `S.of(context, 'key')` — never hardcode text
- **Files**: `lib/core/l10n/app_vi.dart`, `lib/core/l10n/app_en.dart`
- **Helper**: `lib/core/l10n/s.dart` provides `S.of(context, key)` method

## Release History

- **R10** — User flow redesign: Debt V2, Goal V2, Transfer V2, 4-tab navigation, Quick Actions FAB
- **R9** — Firebase read optimization: Batch reads, cache strategy, read counter
- **R8** — Debt tracking, wallet goals, transfer transactions, funding source
- **R7** — UI/UX overhaul: Soft charts, loading states, transaction list redesign, reactions
- **R5** — Home V2, lightweight insights, smart coaching, recurring transactions
- **R4** — Activity feed noise reduction, empty state improvements, CSV export
- **R3** — Family onboarding, FCM reliability, notification UX, quick add improvements
- **R2** — Firestore migration, security rules, indexes, query optimization
- **R1** — Initial release with SQLite

## Contributing

Before contributing, please read:
1. [Design Style Guide](docs/style_guides/design.md)
2. [Coding Style Guide](docs/style_guides/coding.md)
3. Latest feature specs in `docs/features/r10/`

## License

MIT
