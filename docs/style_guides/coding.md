# Coding Style Guide

---

## 1. Architecture

### Layers

```
core/           → Shared infrastructure (theme, l10n, bootstrap, firestore base, enums, constants)
common/widgets/ → Reusable UI components (không phụ thuộc feature cụ thể)
features/       → Feature modules (self-contained)
utils/          → Pure functions (formatters, helpers — no state, no Flutter if possible)
```

### Feature Module Structure

```
features/wallet/
├── models/          → Data classes
├── repositories/    → Firestore CRUD (extends FirestoreRepository<T>)
├── services/        → Business logic (calls repo, validation, cache)
├── screens/         → Full-screen StatefulWidgets
└── widgets/         → Feature-specific UI components
```

### Dependency Rules

```
Screen → Service → Repository → Firestore
Screen → common/widgets/
Screen → utils/

❌ Screen → Repository (skip service)
❌ Service → Flutter widgets
❌ common/ → features/
❌ features/x/ → features/y/widgets/
```

---

## 2. Base Classes

| Base | Purpose | Extended by |
|------|---------|-------------|
| `FirestoreRepository<T>` | CRUD + streams for account subcollections | WalletRepo, TransactionRepo, CategoryRepo, BudgetRepo, RecurringRuleRepo |
| `AppScaffold` | Standard scaffold with LedgerHeader | Every screen |
| `AppCache` | Preloaded data singleton | Bootstrap populates, screens read via `sl.cache` |

### When to Create a New Base

* 3+ classes share the same pattern (rule of three)
* Duplicated logic > 10 lines
* Don't create for 1-2 cases — use composition over inheritance

---

## 3. Reusable Widgets (`common/widgets/`)

Only promote to `common/` when used by **2+ different features**.

| Widget | Purpose |
|--------|---------|
| `AppScaffold` | Scaffold + LedgerHeader |
| `LedgerCard` | Card container (surface, shadow, radius 16) |
| `EmptyState` | Emoji + hint text centered |
| `ShimmerPlaceholder` | Pulsing loading placeholder |
| `AsyncContent` | loading/error/child wrapper |
| `InlineSelector` | Compact tappable label (icon + text + ▾) |
| `SelectionSheet` | Bottom sheet picker with icons/colors |
| `AmountInputField` | System keyboard + dynamic suffix chips |
| `AmountText` | Formatted currency, colored by type |
| `SwipeListItem` | Swipe-to-delete wrapper |
| `FormSaveButton` | Full-width save button for forms |
| `TypeSelector` | Income/Expense toggle |
| `DeleteConfirmation` | Confirm delete dialog |
| `NetworkStatusBanner` | Offline warning |

### Rules

* All config via constructor — no reading `sl` directly
* Exceptions: `AppScaffold`, `NetworkStatusBanner` (need context/theme)
* No business logic — UI only

---

## 4. Data Access

### Service Locator

Access services via `sl` (global singleton):

```dart
sl.walletService.getWallets()
sl.cache.categories
sl.appState.currentAccountId
```

### Cache vs Fetch vs Stream

| When | Use |
|------|-----|
| Data used by 3+ screens | `sl.cache.*` (bootstrap preloads) |
| Data only 1 screen needs | `await sl.someService.getData()` |
| Data needs realtime updates | `StreamBuilder` + `sl.someService.watch*()` |
| After mutating cached data | Invalidate: `sl.cache.setCategories(newList)` |

### Examples

```dart
// ✅ Read from cache
final categories = sl.cache.categories;
final accountName = sl.cache.currentAccount?.name;

// ✅ Fetch screen-specific data
final wallets = await sl.walletService.getWallets();

// ✅ Realtime stream
StreamBuilder(stream: sl.walletService.watchWallets(), ...)

// ❌ Fetch what's already cached
final cats = await sl.categoryService.getCategories();

// ❌ Repository directly from screen
final txns = await TransactionRepository().getByDateRange(...);
```

---

## 5. Screen Patterns

### List Screen

```
AppScaffold
└── Column
    ├── [Filter row]       → InlineSelector chips
    ├── Expanded
    │   └── RefreshIndicator
    │       └── ListView.builder → SwipeListItem or custom
    └── [QuickAddBar]      → if has quick input
```

### Form Screen

```
AppScaffold
└── Form
    └── ListView
        ├── fields          → TextFormField, DropdownField, AmountInputField, TypeSelector
        └── FormSaveButton
```

### Detail Screen

```
AppScaffold
└── RefreshIndicator
    └── ListView
        └── LedgerCard sections
```

---

## 6. State Management

* `StatefulWidget` for screens with local state (loading, form, filters)
* `StreamBuilder` for realtime data
* No state management packages (Provider, Bloc, Riverpod) — app is small enough
* `setState()` only when `mounted == true`

```dart
// Async pattern
setState(() => _loading = true);
try {
  await doWork();
} finally {
  if (mounted) setState(() => _loading = false);
}
```

---

## 7. Error Handling

### Screen Level

```dart
try {
  await sl.someService.doSomething();
} catch (e) {
  final mapped = ErrorMapper.map(e);
  if (mounted) showAppSnackBar(context, S.of(context, mapped.message));
}
```

### Rules

* Never `catch (e) { print(e); }` — always show to user or log meaningfully
* `ErrorMapper.map(e)` converts Firebase exceptions → l10n keys
* Non-critical errors (background tasks) → `debugPrint` only
* Service layer: throw `AppException` or let Firebase exceptions bubble up
* Repository layer: let Firestore exceptions bubble up

---

## 8. Imports

### Package Imports Only

```dart
// ✅
import 'package:vintage_ledger/core/theme/app_colors.dart';

// ❌
import '../../../core/theme/app_colors.dart';
```

### Order

1. `dart:` libraries
2. `package:flutter/`
3. `package:` (third-party)
4. `package:vintage_ledger/core/`
5. `package:vintage_ledger/common/`
6. `package:vintage_ledger/features/`
7. `package:vintage_ledger/utils/`

Blank line between each group.

---

## 9. Naming

| Type | Convention | Example |
|------|-----------|---------|
| File | `snake_case` | `wallet_list_screen.dart` |
| Class | `PascalCase` | `WalletListScreen` |
| Variable / method | `camelCase` | `_loadRange()`, `_filterWalletId` |
| Constant | `camelCase` | `AppSpacing.md`, `AppColors.primary` |
| Enum value | `camelCase` | `TransactionType.income` |
| Private | `_` prefix | `_loading`, `_buildFilterRow()` |
| L10n key | `camelCase` | `'transactionLedger'` |
| Screen | `*Screen` | `WalletListScreen` |
| Service | `*Service` | `WalletService` |
| Repository | `*Repository` | `WalletRepository` |
| Model | Entity name | `Wallet`, `Account` |
| Reusable widget | Descriptive | `LedgerCard`, `CalendarGrid` |

---

## 10. L10n

* Every user-facing string: `S.of(context, 'key')` — never hardcode
* Key format: `camelCase`, short and descriptive
* Casual tone: "Xóa luôn hả?" not "Bạn có chắc chắn muốn xóa?"
* Add new key → add to both `app_vi.dart` and `app_en.dart` at the same time
* Interpolation: `replaceAll('{key}', value)` — no complex templates
* Default locale: `vi`
* Fallback chain: current locale → `vi` → raw key

---

## 11. Don't Repeat Yourself

| If you see... | Then... |
|---|---|
| Same TextStyle inline 3+ places | Add to `AppTextStyles` |
| Same Color inline 3+ places | Add to `AppColors` |
| Same widget pattern in 2+ features | Extract to `common/widgets/` |
| Same Firestore query in 2+ repos | Add method to `FirestoreRepository<T>` |
| Same data fetch in 3+ screens | Add to `AppCache` (bootstrap preload) |
| Same business logic in 2+ screens | Extract to service |
| Same format/parse logic | Extract to `utils/` |
| Same spacing value inline | Use `AppSpacing.*` |

---

## 12. Bootstrap & Auth Flow

### App Startup

All startup logic goes through `BootstrapService` (5-step pipeline):

```
auth → account → settings → data → background
```

Screens never do their own auth/account resolution.

### Auth Transitions

All auth changes (login, logout, switch account) go through `SplashBootstrapScreen`:

```dart
// ✅ Clear state → navigate to splash → bootstrap handles everything
_resetAndBootstrap(LoginIntent(method: LoginMethod.google, ...));

// ❌ Inline logout + sign-in + migrate in screen
await sl.authService.logout();
await sl.authService.signInWithGoogle();
await sl.accountService.migrateAccount(...);
```

### Rules

* Never call `logout()` while Firestore streams are active
* Always clear `appState` + `cache` + `FeedHelper` before navigating away
* `LoginIntent` carries: method, anonAccountIdToMigrate, returnToTab
* Bootstrap handles: logout → sign-in → account resolve → migrate → preload → navigate
