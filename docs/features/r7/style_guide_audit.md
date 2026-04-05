# R7 Style Guide Audit

## Methodology
Đánh giá từng section của style guide, so sánh với code hiện tại, xác định gaps cần fix.

---

## 1. Colors — 38 legacy references còn sót

| Issue | Count | Files |
|---|---|---|
| `AppColors.inkBlue` (should be `primary`) | ~20 | wallet_list, category_list, family_detail, budget screens, recurring screens |
| `AppColors.inkRed` (should be `expense`) | ~5 | wallet_list, setting_screen |
| `AppColors.paper` (should be `background`) | ~8 | wallet cards, login_screen |
| `AppColors.inkBlack` (should be `textPrimary`) | ~5 | scattered |
| Hardcoded `Color(0xFF...)` | 17 | chart widgets, budget progress, star badge |
| `Colors.red` / `Colors.grey` | ~5 | scattered |

**Action**: Migrate all 38 legacy + 17 hardcoded → AppColors semantic tokens.

---

## 2. Radius — 8 places still using 12

| File | Issue |
|---|---|
| wallet_list_screen | ListTile shape radius 12 |
| category_list_screen | ListTile shape radius 12 |
| family_detail_screen | LedgerCard border radius 12 |
| budget screens | Various radius 12 |
| recurring screens | Various radius 12 |

**Action**: Replace all `circular(12)` → `circular(16)`.

---

## 3. Loading States — 15 CircularProgressIndicator

Only HomeScreen uses ShimmerPlaceholder. All other screens still use raw `CircularProgressIndicator`.

| Screen | Issue |
|---|---|
| transaction_list_screen | CircularProgressIndicator |
| wallet_detail_screen | CircularProgressIndicator |
| insights_tab | CircularProgressIndicator |
| account_picker_screen | CircularProgressIndicator |
| budget_list_screen | CircularProgressIndicator |
| category_list_screen | CircularProgressIndicator |
| family_detail_screen | CircularProgressIndicator |
| recurring_list_screen | CircularProgressIndicator |

**Action**: Replace with ShimmerPlaceholder or soft loading indicator.

---

## 4. Transaction Display — 2 screens missing story format

| Screen | Current | Should be |
|---|---|---|
| wallet_detail_screen | TransactionSection (old table-ish) | Story format feed |
| monthly_insight_screen | Data display | Casual tone |

**Action**: WalletDetailScreen use story format. MonthlyInsight casual tone.

---

## 5. Charts — 21 hardcoded colors

Chart widgets (chart_section, breakdown_chart, etc.) use hardcoded colors instead of AppColors.

**Action**: Migrate chart colors to AppColors. Softer palette (muted, not aggressive).

---

## 6. Reactions — missing from Transaction List

HomeScreen feed has reactions. TransactionListScreen timeline does NOT.

**Action**: Add reaction display + long-press picker to timeline items.

---

## 7. Wallet Detail — still "fintech" style

WalletDetailScreen has:
- ChartSection (heavy dashboard feel)
- TransactionSection (old style)
- No story format

**Action**: Simplify to feed-style. Bỏ chart (→ Insights tab). Story format transactions.

---

## 8. Legacy Files — should be deleted

| File | Reason |
|---|---|
| `join_family_screen.dart` | Replaced by invite-by-email |
| `invite_token.dart` | Replaced by pending_invites |
| `error_snackbar.dart` | Replaced by app_snackbar |

**Action**: Delete unused files.

---

## 9. Form Screens — 22 old patterns

Budget, Category, Recurring, Account form screens still use:
- `AppColors.inkBlue` instead of `primary`
- `circular(12)` instead of `circular(16)`
- Some use `AppTextStyles.title` for section headers (too heavy)

**Action**: Migrate all form screens to new style tokens.

---

## 10. Account Picker — old style

AccountPickerScreen uses:
- Old LedgerCard style
- No avatar for family members
- No soft styling

**Action**: Redesign with profile avatars, soft cards, casual tone.

---

## 11. Animations — incomplete

Style guide says 150-250ms, smooth, purposeful.

| Done | Missing |
|---|---|
| Tab fade (150ms) | Form screen transitions |
| Page slide+fade (250ms) | List item insert animation |
| Reaction bounce (200ms) | Delete animation (just disappears) |
| Feed AnimatedSize | Skeleton → content transition |

**Action**: Add missing animations where impactful.

---

## 12. Social Visibility — incomplete

Style guide: "Always show who did what"

| Done | Missing |
|---|---|
| Home feed: actor name | Transaction list: no actor in collapsed day header |
| FeedItem: avatar | Budget: no "who set this budget" |
| Reaction: who reacted | Wallet: no "who created" |

**Action**: Add actor info where meaningful (not everywhere).

---

## Summary

| Category | Status | Gap |
|---|---|---|
| Colors | 🟡 70% | 38 legacy + 17 hardcoded |
| Radius | 🟡 80% | 8 places still 12 |
| Typography | ✅ Done | Sans-serif everywhere |
| Content/Tone | ✅ Done | L10n rewritten |
| Home Screen | ✅ Done | Minimal feed |
| Quick Add | ✅ Done | Chat-like + preview |
| Transaction Story | 🟡 80% | 2 screens missing |
| Reactions | 🟡 50% | Only in home feed |
| Loading States | 🔴 20% | 15 raw spinners |
| Charts | 🔴 30% | 21 hardcoded colors |
| Forms | 🟡 60% | 22 old patterns |
| Wallet Detail | 🔴 Old | Needs redesign |
| Account Picker | 🟡 Old | Needs soft style |
| Animations | 🟡 50% | Missing in several places |
| Social Visibility | 🟡 60% | Incomplete |
| Legacy Cleanup | 🔴 | 3 unused files |
