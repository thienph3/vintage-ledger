# Vintage Ledger — Summary R7

> Ứng dụng quản lý thu chi cho couples, phong cách modern soft journal, xây dựng bằng Flutter.
> 121 files Dart · ~11,700 LOC · 9 test files · 12 services

---

## Thay đổi so với R6

| Hạng mục | R6 | R7 |
|---|---|---|
| Design philosophy | Vintage ledger (paper/ink/typewriter) | **Modern soft journal** — casual, social, non-judgmental |
| Typography | SpecialElite + PatrickHand | **System sans-serif** — w600 titles, w400 body |
| Color palette | paper/inkBlue/inkPurple/inkRed | **Soft muted** — background #F8F8F6, primary #5B7FA2, income #5BA37C, expense #D4845A |
| Content tone | Formal, UPPERCASE titles | **Casual/conversational** — "Tụi mình có", "Xóa luôn hả?", sentence case |
| Home screen | Overloaded (balance + wallets + chart + budget + streak + coaching) | **Minimal** — Today Total + Shared Feed (StreamBuilder realtime) + QuickAddBar |
| Transaction display | Data rows (category - amount) | **Story format** — "Bạn cafe 30k ☕" with actor + emoji |
| Transaction list | Group mode pills, infinite scroll | **Timeline Ledger** — month picker, day collapse/expand, filters (wallet + category + member) |
| Quick Add | Form-like input | **Chat-like** — borderless input, send icon, suggestion chips, parse preview |
| Amount input | Custom keypad bottom sheet | **System keyboard** + dynamic suffix chips (MoMo-style) + amount history |
| Reactions | Không có | **Emoji reactions** — long-press, bounce animation, Firestore subcollection |
| Auth | Email register + login | **Google SSO** primary, email login deprecated, no register |
| Avatar | Không có | **Google photo** in profile + feed items |
| Settings | Dense sections, vintage style | **Profile card** with avatar, grouped sections, soft tiles |
| Filters | Không có | **InlineSelector** + **SelectionSheet** — wallet, category (with icons + colors), member |
| Components | LedgerHeader with divider, harsh colors | **Soft** — no divider, radius 16-20, warm delete, shimmer loading |
| Navigation | HomeScreen root, settings icon | **MainShell** BottomNav 4 tabs, settings = tab |
| Wallet form | Balance editable (dangerous) | **initialBalance** separated, balance = initialBalance + sum(txns) |
| Services | 11 | **12** (+ReactionService) |
| Files | 114 | **121** |
| LOC | ~10,900 | **~11,700** |
| L10n keys | ~233 | **~248** |
| Rules | 16 | **17** (+reactions subcollection) |

---

## Design System (R7 Style Guide)

### Philosophy
> A soft, modern interface that feels like a shared daily journal — not a finance tool.

### Principles
- **Human over Financial** — natural language, no jargon
- **Soft over Sharp** — no harsh contrasts, calm and forgiving
- **Social over Personal** — always show "who did what"
- **Fast over Detailed** — 3-second scanning, minimize friction

### Colors (`AppColors`)
| Token | Hex | Usage |
|---|---|---|
| `background` | `#F8F8F6` | Scaffold background |
| `surface` | `#FFFFFF` | Cards, inputs, overlays |
| `primary` | `#5B7FA2` | Actions, icons, focus |
| `accent` | `#E8A87C` | Warm accent |
| `textPrimary` | `#3D3D3D` | Body text |
| `textSecondary` | `#8E8E8E` | Captions, hints |
| `income` | `#5BA37C` | Income amounts (green) |
| `expense` | `#D4845A` | Expense amounts (warm orange) |
| `divider` | `#E8E5DE` | Subtle lines |

### Typography
- System sans-serif (no custom fonts)
- Titles: w600, Body: w400
- Numbers: clear, aligned, easy to scan

### Spacing
- `xs: 4`, `sm: 8`, `md2: 12`, `md: 16`, `lg: 24`, `xl: 32`
- Corner radius: 16 (cards/inputs), 20 (buttons/dialogs/sheets)

---

## New Features R7

### 1. Modern Soft Theme
- Complete color palette overhaul (8 semantic colors)
- Sans-serif typography (bỏ SpecialElite + PatrickHand)
- Soft shadows, no borders on cards
- Radius 16-20 everywhere

### 2. Casual Content & Tone
- ~248 l10n keys rewritten vi + en
- "Tụi mình có" / "We have" thay "Tổng số dư"
- "Xóa luôn hả?" thay "Bạn có chắc muốn xóa?"
- "Hmm, có gì đó sai rồi" thay "Có lỗi xảy ra"
- Sentence case everywhere (bỏ UPPERCASE)

### 3. Home V3 — Minimal Feed
- Today Total: "Hôm nay chi 150k" (1 dòng casual)
- Shared Feed: StreamBuilder realtime, story format, avatar
- AnimatedSize cho smooth insert
- ShimmerPlaceholder loading
- Bỏ: wallets row, charts, budget, streak, coaching (→ Insights tab)

### 4. Transaction as Story
- `TransactionStory.format()` → "Bạn cafe 30k ☕"
- `category_emojis.dart`: 22 emoji mappings
- `FeedHelper`: actor resolution (personal → "Bạn", family → tên thật) + photo cache
- `FeedItem`: avatar (Google photo / initials) + story + time

### 5. Timeline Ledger (Transaction List V2)
- Month picker ◄ ► + tap DatePicker
- Day collapse/expand: ngày + thứ + count + net amount
- Filters: wallet + category + member (family) via InlineSelector + SelectionSheet
- Category filter: actual icons + thu/chi colors
- Story format trong expanded items

### 6. Chat-like Quick Add
- Borderless input (no OutlineInputBorder)
- Send icon (send_rounded / add_circle_outline)
- Parse preview: wallet + amount + category (all tappable)
- Category always changeable (tap to pick even when parsed)
- Send disabled until amount + category complete
- Learn only when user manually picks category, persist immediately

### 7. Amount Input (MoMo-style)
- System keyboard (bỏ custom keypad)
- Dynamic suffix chips: gõ "5" → 5.000đ · 50.000đ · 500.000đ
- History chips when empty (top 3 most used, fallback 10k/20k/50k)
- Formatted display while typing (1.234đ)
- Cursor before suffix (1.234|đ)
- Max 8 digits, chip count adapts (3→2→1→history)
- TextFieldTapRegion: chip tap doesn't dismiss keyboard
- AmountHistory: persist top amounts, record from txn/wallet/quickadd

### 8. Emoji Reactions
- Long-press transaction → 6 emoji picker (😂😅👍❤️😱💸)
- Bounce animation (scale 1.0→1.3→1.0, 200ms)
- ReactionBar: grouped emoji bubbles + count
- Firestore subcollection `transactions/{id}/reactions/{userId}`
- FCM notification to transaction owner

### 9. Google SSO
- `signInWithProvider(GoogleAuthProvider())` — no extra package
- Primary login method (LoginScreen + Settings)
- Email login deprecated (hidden, expandable)
- Register removed entirely
- `linkEmailUserWithGoogle()` for migration
- Avatar sync: `photoURL` → Firestore `photo_url` → profile + feed

### 10. Redesigned Settings
- Profile card: avatar (Google photo / initials) + name + email + edit
- Anonymous card: Google SSO + email login buttons
- "Chuyển sang Google" for email users
- Grouped sections: Manage / Preferences / Data / Debug
- Language: tap toggle (not 2 tiles)
- Currency: VND only (ready for multi)
- Inline reminder toggle + time picker

### 11. Reusable Components
- `SelectionSheet`: unified bottom sheet picker (title, items with icon/color, selected highlight)
- `InlineSelector`: compact tappable label (icon + text + unfold_more, optional color)
- `ShimmerPlaceholder`: pulsing loading state (no extra package)
- `AmountHistory`: track + persist top amounts

### 12. Wallet & Category Improvements
- `initialBalance` field separated from `balance`
- `balance = initialBalance + sum(transactions)`
- Wallet rename: tap title on WalletDetailScreen
- WalletListScreen: tap → detail, edit icon → form
- Category icons + thu/chi colors throughout (preview, picker, filters)
- Edit `createdBy` in transaction form (family)
- Display name editable in Settings

---

## Bug Fixes R7

| Bug | Fix |
|---|---|
| All wallets show star | Compare `wallet.id == _defaultWalletId` directly |
| SnackBar not auto-dismiss | `showAppSnackBar` helper + theme `persist: false` |
| "Sửa thu chi" instead of "Thêm" | Separate `prefill` param from `existing` |
| Permission denied after login | `getIdToken(true)` force refresh |
| Permission denied query wallet | Persist `lastAccountId` after login + fallback resolve |
| Family detail permission denied | Open `/users` read for authenticated |
| Filter "All" not selectable | `'_all'` sentinel instead of null |
| Unknown userId shows "Bạn" | Show "?" + editable `createdBy` dropdown |
| Amount chip doesn't update + keyboard closes | `TextFieldTapRegion` wraps Overlay |
| Compact format truncates (142k) | Double division → 142.9k |
| TransactionListScreen missing back button | `isTab` param |
| Settings Google SSO fails | Sign out anonymous first, then sign in fresh + migrate |
| QuickAdd learn too aggressive | Only learn when user manually picks category |
| QuickAdd learn may lose data | Persist immediately (no debounce) |
| Amount shows hint instead of 0đ | `showZero` param + formatted display |
| Cursor after suffix đ | `lastIndexOf(RegExp(r'[0-9]')) + 1` |

---

## Architecture

```
MainShell (BottomNavigationBar)
├── Home tab — Today Total + Shared Feed (StreamBuilder) + QuickAddBar
├── Transactions tab — Month picker + Filters (InlineSelector) + Timeline (collapse/expand) + QuickAddBar
├── Insights tab — InsightCards + CoachingCard + Charts + Budget + Streak
└── Settings tab — Profile card + Manage + Preferences + Data + Debug
```

- **Pattern**: Feature-first (Repository → Service → Screen)
- **Data**: Firestore-first + in-memory cache layers (Settings, Category, Budget, Account)
- **Auth**: Google SSO primary, anonymous auto, email deprecated
- **Realtime**: StreamBuilder for home feed + wallet list
- **DI**: ServiceLocator singleton — 12 services
- **L10n**: Vietnamese / English, ~248 keys

---

## Firestore Schema

```
accounts/{accountId}/
  ├── wallets/{docId}              → name, balance, initial_balance, currency
  ├── transactions/{docId}         → wallet_id, category_id, type, amount, note, date, created_by
  │   └── reactions/{userId}       → emoji, created_at
  ├── categories/{docId}           → name, type, icon
  ├── budgets/{docId}              → category_id, amount_limit
  ├── recurring_rules/{docId}      → amount, category_id, wallet_id, type, frequency, next_run_at, enabled
  ├── activities/{docId}           → user_id, action, description, created_at
  └── notification_events/{eventId}

users/{userId}/
  ├── email, display_name, photo_url, account_ids[]
  ├── settings/prefs → locale, last_account_id, last_wallet_id, quick_add_keywords, quick_add_history, amount_history, streak_*, reminder_*, dismissed_tips
  └── fcm_tokens/{token}

pending_invites/{inviteId}/ → account_id, account_name, from_user_id, to_user_id, status
user_emails/{email}         → user_id
config/fcm                  → server_key
```

---

## Project Structure

```
lib/                              # 121 files, ~11,700 LOC
├── core/
│   ├── constants/                # category_icons, category_emojis, currency, seed_categories
│   ├── debug/                    # ReadCounter
│   ├── enums/                    # transaction_type
│   ├── firestore/                # FirestoreRepository<T> (+useCache)
│   ├── l10n/                     # vi (~248 keys), en (~248 keys), S helper
│   ├── theme/                    # AppColors (soft), AppTextStyles (sans-serif), AppSpacing, AppTheme
│   ├── app_state.dart
│   ├── error_mapper.dart
│   └── service_locator.dart      # 12 services
├── common/widgets/               # ~20 widgets
│   ├── amount_input_field.dart   # System keyboard + dynamic chips + TextFieldTapRegion
│   ├── amount_history.dart       # Track top amounts
│   ├── inline_selector.dart      # Compact tappable label
│   ├── selection_sheet.dart      # Reusable bottom sheet picker
│   ├── shimmer_placeholder.dart  # Pulsing loading
│   ├── ledger_card.dart          # Soft card (no border)
│   ├── ledger_header.dart        # Clean AppBar (no divider)
│   └── ...
├── features/
│   ├── account/                  # Google SSO, invite by email, family
│   ├── auth/                     # AuthService (Google + email deprecated), LoginScreen
│   ├── budget/                   # Budget (+cache)
│   ├── category/                 # Category (+cache, +icons, +colors)
│   ├── coaching/                 # Smart coaching (rule-based tips)
│   ├── export/                   # CSV export
│   ├── feed/                     # FeedHelper (actor + photo), FeedItem widget
│   ├── home/                     # HomeScreen V3 (minimal feed)
│   ├── insights/                 # InsightService, InsightCard, InsightsTab (+coaching)
│   ├── main_shell.dart           # BottomNav 4 tabs (AnimatedSwitcher)
│   ├── notification/             # FCM + local notifications
│   ├── quick_add/                # Parser (learn), History (suggestions), QuickAddBar (chat-like)
│   ├── recurring/                # Recurring transactions
│   ├── reminder/                 # Daily reminder (local notifications)
│   ├── settings/                 # SettingService (+cache), SettingScreen (profile card)
│   ├── transaction/              # Atomic CRUD, Timeline Ledger, Reactions, Story format
│   └── wallet/                   # Wallet (+initialBalance, +rename)
├── utils/                        # AmountFormatter, DateFormatter, TransactionStory, NavigatorX
└── main.dart
```

---

## Evolution Summary

| Round | Focus | Files | LOC | L10n | Services | Rules | Indexes |
|---|---|---|---|---|---|---|---|
| R1 | SQLite + manual sync | 78 | ~7,600 | ~120 | 6 | — | — |
| R2 | Firestore-first + features | 91 | ~7,650 | ~160 | 7 | 7 | 3 |
| R3 | Production hardening | 95 | ~8,200 | ~180 | 8 | 10 | 5 |
| R4 | Polish | 95 | ~8,600 | ~190 | 9 | 10 | 5 |
| R5 | Trust & UX | 96 | ~8,900 | ~200 | 9 | 10 | 5 |
| R6 | Engagement & Structure | 114 | ~10,900 | ~233 | 11 | 16 | 8 |
| R7 | Style Guide Migration | 121 | ~11,700 | ~248 | 12 | 17 | 8 |
