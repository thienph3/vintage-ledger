# R7 UI/UX Full Audit — Screen-by-Screen

> Đánh giá toàn bộ screens + widgets so với style guide "modern soft journal for couples".
> Mỗi screen được chấm: ✅ Pass | ⚠️ Minor | ❌ Fail

---

## 1. Theme Foundation

| Component | Status | Issue |
|-----------|--------|-------|
| `AppColors` | ✅ | Semantic palette, chartColors, no legacy |
| `AppTextStyles` | ✅ | System sans-serif, w600/w400, proper hierarchy |
| `AppTheme` | ⚠️ | `LedgerListTile` shadow 0.12 quá đậm so với style guide (0.04). `SwipeListItem` dùng `Card` thay vì `Container` — inconsistent với LedgerCard |
| `AppSpacing` | ✅ | xs/sm/md2/md/lg/xl đầy đủ |

## 2. Common Widgets

| Widget | Status | Issues |
|--------|--------|--------|
| `AppScaffold` | ✅ | Clean, delegates to LedgerHeader |
| `LedgerHeader` | ⚠️ | Thiếu bottom divider (style guide: "Divider bottom"). AppBar không có bottom border/divider |
| `LedgerCard` | ✅ | surface + radius 16 + shadow 0.04 — perfect |
| `LedgerListTile` | ❌ | Shadow 0.12 quá đậm (nên 0.04 như LedgerCard). Nên dùng LedgerCard thay vì duplicate. Padding hardcoded 16/12 thay vì AppSpacing |
| `EmptyState` | ✅ | Emoji + hint text, centered |
| `SwipeListItem` | ⚠️ | Dùng `Card(elevation: 0)` — nên dùng Container + BoxDecoration cho consistent shadow. Delete background dùng expense 0.15 — OK |
| `AmountText` | ✅ | income/expense colors, compact/full format |
| `FormSaveButton` | ✅ | Full-width ElevatedButton, theme handles style |
| `TypeSelector` | ⚠️ | Outer radius 16 OK. Inner pill radius 12 OK. Nhưng selected color là `primary` solid — nên softer (primary 0.12 bg + primary text) cho "soft journal" feel |
| `InlineSelector` | ✅ | Compact, icon + text + unfold_more |
| `SelectionSheet` | ⚠️ | Item shape radius 12 (nên 16). Thiếu drag handle indicator ở top |
| `ShimmerPlaceholder` | ✅ | Animated opacity, circle + lines layout |
| `NetworkStatusBanner` | ✅ | accent 0.15 bg, cloud_off icon |
| `IncomeExpenseSummaryRow` | ✅ | Divider separator, caption labels |
| `DeleteConfirmation` | ✅ | AlertDialog, theme handles style |
| `AppSnackbar` | ✅ | clearSnackBars + 3s duration |
| `LocaleToggle` | ✅ | Flag emoji, emojiLarge style |
| `AmountInputField` | ✅ | MoMo-style, dynamic chips, TextFieldTapRegion |

## 3. Screens

### 3.1 HomeScreen
| Aspect | Status | Issue |
|--------|--------|-------|
| Layout | ✅ | Today total + feed + QuickAddBar |
| Today card | ✅ | surface + radius 16 + shadow 0.04 |
| Feed items | ✅ | TransactionFeedItem with reactions |
| Empty state | ✅ | Emoji + hint |
| Loading | ✅ | ShimmerPlaceholder |
| **Gap** | ⚠️ | Không có greeting message casual ("Chào buổi sáng 👋"). Không có coaching tip ở home (chỉ ở Insights) |

### 3.2 TransactionListScreen
| Aspect | Status | Issue |
|--------|--------|-------|
| Month picker | ✅ | Chevron + tap to pick year |
| Summary chips | ✅ | income/expense colors |
| Filter row | ✅ | InlineSelector + SelectionSheet |
| Day groups | ✅ | Collapsible, net amount |
| Expanded items | ✅ | TransactionFeedItem |
| Loading | ✅ | ShimmerPlaceholder |
| **Gap** | ⚠️ | Day header số ngày dùng `title fontSize 20` — hơi to. Thiếu subtle day divider giữa các ngày |

### 3.3 TransactionFormScreen
| Aspect | Status | Issue |
|--------|--------|-------|
| TypeSelector | ✅ | income/expense toggle |
| AmountInput | ✅ | MoMo-style |
| CategoryDropdown | ⚠️ | Dùng `DropdownButtonFormField` native — không match soft style. Nên dùng InlineSelector + SelectionSheet |
| WalletDropdown | ⚠️ | Same — native dropdown |
| Budget warning | ✅ | accent/expense colors |
| Recurring toggle | ✅ | SwitchListTile |
| Member dropdown | ⚠️ | Native dropdown |
| **Gap** | ❌ | 3 native dropdowns phá vỡ soft style. Nên migrate sang SelectionSheet pattern |

### 3.4 WalletListScreen
| Aspect | Status | Issue |
|--------|--------|-------|
| List items | ⚠️ | Dùng `LedgerListTile` (shadow 0.12 quá đậm) bên trong `SwipeListItem` — double container. Nên dùng SwipeListItem alone |
| Star icon | ✅ | accent color |
| Add button | ✅ | ElevatedButton.icon |
| Loading | ✅ | ShimmerPlaceholder |
| **Gap** | ❌ | `LedgerListTile` inside `SwipeListItem` = double card effect. SwipeListItem đã có Card bên trong |

### 3.5 WalletDetailScreen
| Aspect | Status | Issue |
|--------|--------|-------|
| Balance card | ✅ | Tap to toggle visibility, soft card |
| Feed section | ✅ | TransactionFeedItem + reactions |
| QuickAddBar | ✅ | Bottom input |
| Loading | ✅ | ShimmerPlaceholder |
| **Gap** | ⚠️ | Thiếu income/expense summary row dưới balance |

### 3.6 WalletFormScreen
| Aspect | Status | Issue |
|--------|--------|-------|
| Fields | ✅ | Name + currency + initialBalance |
| Currency dropdown | ⚠️ | Native DropdownButtonFormField — chỉ có VND nên OK |
| Save button | ✅ | FormSaveButton |
| **Gap** | ✅ | Clean form |

### 3.7 CategoryListScreen
| Aspect | Status | Issue |
|--------|--------|-------|
| Section headers | ✅ | income/expense with colored divider |
| List items | ⚠️ | `LedgerListTile` inside `SwipeListItem` — same double card issue |
| Add button | ✅ | ElevatedButton.icon |
| Loading | ✅ | ShimmerPlaceholder |

### 3.8 CategoryFormScreen
| Aspect | Status | Issue |
|--------|--------|-------|
| TypeSelector | ✅ | |
| Name field | ✅ | |
| Icon grid | ✅ | primary selected, radius 16 |
| Save button | ✅ | |
| **Gap** | ✅ | Clean |

### 3.9 BudgetListScreen
| Aspect | Status | Issue |
|--------|--------|-------|
| Progress tiles | ✅ | BudgetProgressTile with income/accent/expense colors |
| Cards | ✅ | LedgerCard wrapper |
| Add button | ✅ | |
| Loading | ✅ | ShimmerPlaceholder |
| **Gap** | ✅ | Clean |

### 3.10 BudgetFormScreen
| Aspect | Status | Issue |
|--------|--------|-------|
| Category dropdown | ⚠️ | Native DropdownButtonFormField |
| Amount input | ✅ | AmountInputField |
| Save button | ✅ | |
| **Gap** | ⚠️ | Native dropdown |

### 3.11 MonthlyInsightScreen
| Aspect | Status | Issue |
|--------|--------|-------|
| Summary card | ✅ | IncomeExpenseSummaryRow + net |
| Highlight card | ✅ | Celebration/trending icons, income/expense colors |
| Top spending | ✅ | Compact currency |
| Comparison bars | ✅ | expense/divider colors |
| Loading | ✅ | ShimmerPlaceholder |
| **Gap** | ✅ | Clean |

### 3.12 RecurringListScreen
| Aspect | Status | Issue |
|--------|--------|-------|
| Rule tiles | ⚠️ | Inline layout OK nhưng `Switch` không có soft styling. FAB dùng `primary` bg — nên dùng theme |
| Add button | ⚠️ | Có cả ElevatedButton VÀ FAB — redundant. Nên bỏ 1 |
| Loading | ✅ | ShimmerPlaceholder |
| **Gap** | ❌ | Duplicate add buttons (FAB + inline). FAB không match soft style |

### 3.13 RecurringFormScreen
| Aspect | Status | Issue |
|--------|--------|-------|
| Wallet dropdown | ⚠️ | Native dropdown |
| Category dropdown | ✅ | CategoryDropdown widget |
| Frequency dropdown | ⚠️ | Native dropdown |
| Save button | ✅ | |
| **Gap** | ⚠️ | 2 native dropdowns |

### 3.14 InsightsTab
| Aspect | Status | Issue |
|--------|--------|-------|
| Insight cards | ✅ | Icon + colored message |
| Coaching card | ✅ | Primary icon + hint text + link action |
| Chart section | ✅ | LedgerCard wrapper |
| Budget summary | ✅ | |
| Streak card | ✅ | Fire emoji + days |
| Loading | ✅ | ShimmerPlaceholder |
| **Gap** | ✅ | Clean |

### 3.15 SettingScreen
| Aspect | Status | Issue |
|--------|--------|-------|
| Profile card | ✅ | Avatar + name + email + actions |
| Section labels | ✅ | Caption weight 600 |
| List tiles | ✅ | Icon + title + arrow, radius 16 |
| Reminder toggle | ✅ | SwitchListTile |
| Small actions | ✅ | Soft bg 0.08 + radius 16 |
| **Gap** | ⚠️ | Debug section visible to users — nên hide behind long-press hoặc tap counter |

### 3.16 LoginScreen
| Aspect | Status | Issue |
|--------|--------|-------|
| Layout | ✅ | Icon + title + explanation + Google button |
| Google SSO | ✅ | ElevatedButton.icon |
| Email login | ✅ | Hidden by default |
| Locale toggle | ✅ | Top right |
| **Gap** | ✅ | Clean |

### 3.17 AccountPickerScreen
| Aspect | Status | Issue |
|--------|--------|-------|
| Account cards | ✅ | Avatar + name + arrow |
| Family avatars | ✅ | Stacked circles |
| Invite card | ✅ | Avatar + accept/decline |
| Create button | ✅ | Soft outlined, radius 20 |
| Loading | ✅ | ShimmerPlaceholder via AsyncContent |
| **Gap** | ✅ | Clean |

### 3.18 FamilyDetailScreen
| Aspect | Status | Issue |
|--------|--------|-------|
| Members | ⚠️ | CircleAvatar OK nhưng không dùng Google photo (chỉ initials). Nên load photo_url |
| Activity feed | ⚠️ | Inline text format — không dùng FeedItem/TransactionFeedItem. Inconsistent với home/wallet detail |
| Actions | ✅ | OutlinedButton with expense color |
| Loading | ✅ | AsyncContent → ShimmerPlaceholder |
| **Gap** | ❌ | Activity feed không dùng story format. Member avatars thiếu photo. Title "members" dùng `AppTextStyles.title` (quá to cho section header — nên titleSmall) |

### 3.19 FamilyFormScreen
| Aspect | Status | Issue |
|--------|--------|-------|
| Form | ✅ | Name field + save button |
| Loading | ⚠️ | Inline CircularProgressIndicator cho save — OK per spec |
| **Gap** | ✅ | Clean |

### 3.20 MainShell
| Aspect | Status | Issue |
|--------|--------|-------|
| Bottom nav | ✅ | 4 tabs, outlined/filled icons |
| AnimatedSwitcher | ✅ | 150ms fade |
| **Gap** | ✅ | Clean |

## 4. Chart Widgets

| Widget | Status | Issue |
|--------|--------|-------|
| `ChartSection` | ✅ | Pill selector, legend, animated switcher |
| `TrendChart` | ✅ | income/expense lines, gradient fill |
| `DailyChart` | ✅ | 0.7 alpha bars, rounded corners |
| `BreakdownChart` | ✅ | chartColors palette, pie + legend |
| `SummaryView` | ✅ | AmountText rows |
| `ChartStyles` | ✅ | Shared grid/border/axis config |

## 5. Reaction Widgets

| Widget | Status | Issue |
|--------|--------|-------|
| `ReactionBar` | ✅ | Grouped counts, primary 0.08 bg, radius 12 |
| `ReactionPicker` | ✅ | Bottom sheet, animated scale, primary 0.06 bg |
| `TransactionFeedItem` | ✅ | Reusable: story + FeedItem + ReactionBar |

## 6. Feed Widgets

| Widget | Status | Issue |
|--------|--------|-------|
| `FeedItem` | ✅ | Avatar + story + time, system message variant |
| `FeedHelper` | ✅ | Name/photo cache + resolve |

## 7. QuickAddBar

| Aspect | Status | Issue |
|--------|--------|-------|
| Chat-like input | ✅ | Rounded bg, hint, clear button |
| Suggestion chips | ✅ | ActionChip, primary 0.08 |
| Parse preview | ✅ | InlineSelector for wallet/category |
| Wallet chip | ✅ | Compact, divider color |
| Send button | ✅ | Conditional enable |
| **Gap** | ⚠️ | Wallet chip dùng `AppColors.divider` cho icon/text — quá nhạt. Nên `textSecondary` |

---

## Summary: Priority Gaps

### 🔴 High (visual inconsistency)

| # | Gap | Files | Impact |
|---|-----|-------|--------|
| H1 | `LedgerListTile` shadow 0.12 + duplicate with SwipeListItem | `ledger_list_tile.dart`, `wallet_list_screen.dart`, `category_list_screen.dart` | Double card effect, inconsistent shadows |
| H2 | Native `DropdownButtonFormField` in forms | `transaction_form_screen.dart`, `budget_form_screen.dart`, `recurring_form_screen.dart` | Breaks soft style — heavy Material dropdown |
| H3 | FamilyDetailScreen activity feed not using story format | `family_detail_screen.dart` | Inconsistent with home/wallet/transaction feeds |
| H4 | RecurringListScreen duplicate add buttons (FAB + inline) | `recurring_list_screen.dart` | Confusing UX |

### 🟡 Medium (polish)

| # | Gap | Files | Impact |
|---|-----|-------|--------|
| M1 | LedgerHeader thiếu bottom divider | `ledger_header.dart` | Style guide says "Divider bottom" |
| M2 | TypeSelector selected state quá bold (solid primary) | `type_selector.dart` | Nên softer: primary 0.12 bg + primary text |
| M3 | SelectionSheet item radius 12 (nên 16) + thiếu drag handle | `selection_sheet.dart` | Minor inconsistency |
| M4 | FamilyDetailScreen member avatars thiếu photo_url | `family_detail_screen.dart` | Inconsistent with account_picker |
| M5 | FamilyDetailScreen section titles dùng `title` (quá to) | `family_detail_screen.dart` | Nên `titleSmall` |
| M6 | QuickAddBar wallet chip dùng divider color (quá nhạt) | `quick_add_bar.dart` | Nên textSecondary |
| M7 | SettingScreen debug section visible | `setting_screen.dart` | Nên hide |

### 🟢 Low (nice-to-have)

| # | Gap | Files | Impact |
|---|-----|-------|--------|
| L1 | HomeScreen thiếu greeting message | `home_screen.dart` | Casual feel |
| L2 | WalletDetailScreen thiếu income/expense summary | `wallet_detail_screen.dart` | Quick overview |
| L3 | TransactionListScreen day number font quá to | `transaction_list_screen.dart` | Minor |
