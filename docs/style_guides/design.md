# Design Style Guide

> A soft, modern interface that feels like a shared daily journal — not a finance tool.

---

## 1. Principles

| Principle | Meaning |
|-----------|---------|
| **Human over Financial** | Natural language, no jargon, readability over precision |
| **Soft over Sharp** | No harsh contrasts, no aggressive alerts, calm and forgiving |
| **Social over Personal** | Shared visibility, always show "who did what", encourage interaction |
| **Fast over Detailed** | 3-second scanning, reduce cognitive load, minimize input friction |

---

## 2. Colors (`AppColors`)

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#F8F8F6` | Scaffold background |
| `surface` | `#FFFFFF` | Cards, inputs, overlays |
| `primary` | `#5B7FA2` | Actions, icons, focus states |
| `accent` | `#E8A87C` | Warm accent, family avatars |
| `textPrimary` | `#3D3D3D` | Body text, titles |
| `textSecondary` | `#8E8E8E` | Captions, hints, disabled |
| `income` | `#5BA37C` | Income amounts (muted green) |
| `expense` | `#D4845A` | Expense amounts (warm orange) |
| `divider` | `#E8E5DE` | Subtle lines, inactive borders |
| `error` | `#D4845A` | Error states (same as expense) |

**Chart palette:** `primary`, `expense`, `income`, `accent`, `#8E7CC3`, `#6DAEDB`, `#B5C99A`

### Rules

* Avoid high saturation
* Avoid strong red (feels like warning) — use warm orange for expense/error
* No inline `Color(0xFF...)` — always use `AppColors.*`

---

## 3. Typography (`AppTextStyles`)

System sans-serif only. No custom fonts.

| Style | Size | Weight | Color | Usage |
|-------|------|--------|-------|-------|
| `title` | 22 | 600 | textPrimary | Screen headers |
| `titleSmall` | 16 | 600 | textPrimary | Section headers, sub-titles |
| `headline` | 20 | 600 | textPrimary | Large emphasis |
| `body` | 16 | 400 | textPrimary | General text |
| `bodyBold` | 16 | 600 | textPrimary | List item names, emphasis |
| `bodySmall` | 14 | 400 | textSecondary | Subtitles, secondary info |
| `amount` | 16 | 600 | textPrimary | Currency values (colored by type) |
| `caption` | 12 | 400 | textSecondary | Chart labels, timestamps, counts |
| `hint` | 14 | 400 | textSecondary | Empty states, placeholders |
| `error` | 14 | 400 | expense | Error messages |
| `buttonLabel` | 16 | 600 | (inherited) | Button text |
| `link` | 14 | 600 | primary | Tappable text links |
| `emoji` | 24 | — | — | Inline emoji |
| `emojiLarge` | 28 | — | — | Lock screen, large emoji |

### Rules

* No inline `TextStyle()` — always use `AppTextStyles.*` or `.copyWith()`
* Numbers: clear, aligned, easy to scan
* Sentence case everywhere — no UPPERCASE titles

---

## 4. Spacing (`AppSpacing`)

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4 | Tight gaps (icon-text) |
| `sm` | 8 | Small gaps between elements |
| `md2` | 12 | Medium-small (compact lists) |
| `md` | 16 | Standard padding, card inner |
| `lg` | 24 | Section gaps |
| `xl` | 32 | Large section separators |

### Corner Radius

* **16** — cards, inputs, buttons, tiles
* **20** — dialogs, bottom sheets, pill buttons
* **24** — chat input, circular elements

### Rules

* No magic numbers — always use `AppSpacing.*`
* No inline `EdgeInsets.all(16)` — use `AppSpacing.md`

---

## 5. Components

### 5.1 Cards (`LedgerCard`)

* Background: `surface`
* Shadow: `black 4% opacity`, blur 12, offset (0, 2)
* Radius: 16
* No heavy borders

### 5.2 Transaction Item (Story Format)

Transform data into story: "Minh ăn trưa 80k 🍜"

* Always include actor (who)
* Use natural language
* Add emoji when appropriate
* Avatar (Google photo / initials) + story text + time

### 5.3 Quick Add (Chat-like)

* Input looks like message bar (borderless, radius 24)
* Suggestion chips above input
* Parse preview: wallet + amount + category (all tappable)
* Send icon when complete, add icon when empty

### 5.4 Reactions

* Long press → 6 emoji picker (😂😅👍❤️😱💸)
* Bounce animation (scale 1.0→1.3→1.0, 200ms)
* Grouped emoji bubbles with count

### 5.5 Filters (`InlineSelector`)

* Compact: icon + label + ▾ (12px)
* Tap → `SelectionSheet` bottom sheet
* Active filter: colored icon/text

### 5.6 Loading States

* `ShimmerPlaceholder` — pulsing placeholder (not spinner)
* `SplashBootstrapScreen` — logo + progress bar + step label
* Never use bare `CircularProgressIndicator`

### 5.7 Empty States (`EmptyState`)

* Centered emoji + hint text
* Casual tone: "Chưa có gì — thử ghi 1 khoản xem 👇"

---

## 6. Content & Tone

### Do

* Casual, conversational, friendly
* "tụi mình", "hôm nay", "tuần này"
* Short sentences, light emotion
* "Xóa luôn hả?" not "Bạn có chắc chắn muốn xóa?"
* "Hmm, có gì đó sai rồi" not "Có lỗi xảy ra"

### Don't

* Sound like a report
* Use formal financial language
* Over-explain

---

## 7. Gestures

Mỗi gesture có 1 ý nghĩa duy nhất. Không dùng cùng gesture cho 2 hành động khác nhau trên cùng 1 element.

| Gesture | Meaning | Example |
|---------|---------|---------|
| **Tap** | Primary action (open, select, toggle) | Tap transaction → edit form, tap day → expand |
| **Long press** | Secondary / contextual action | Long press transaction → reactions, long press wallet → set default |
| **Swipe left** | Delete (destructive only) | Swipe item → delete confirmation |
| **Pull down** | Refresh data | Pull list → RefreshIndicator |
| **Tap chip** | Filter / switch mode | Tap time range → switch, tap InlineSelector → sheet |
| **◀ ▶** | Navigate time range | Prev/next day/week/month |
| **Tap center label** | Jump to specific point | Tap month label → DatePicker |

### Rules

* **Tap = primary** — always the most expected action
* **Long press = secondary** — must have hint text ("Nhấn giữ để...")
* **Swipe = destructive only** — never for edit or archive
* **No double tap** — confusing, not discoverable
* **No drag** — unless reorder (not implemented)
* Every gesture must have **visual feedback** (ripple, color, animation)
* Tap targets minimum **44x44** logical pixels

### Discoverability

* Long press: hint on first encounter (tooltip or caption)
* Swipe: red background reveals on drag start
* Tappable text: use `AppTextStyles.link` (primary color, w600)

---

## 8. Animations

* Duration: 150–250ms
* Curve: `Curves.easeOut` (default)
* Purposeful — only animate to communicate state change
* `AnimatedSize` for list insert/remove
* `FadeTransition` for screen transitions (200ms)
* Bounce for reactions (scale 1.0→1.3→1.0)

### Don't

* Heavy motion, parallax, complex transitions
* Animation for decoration
* Blocking animations (user must wait)

---

## 9. Screen Structure

### Home

```
AppScaffold (account name)
├── NetworkStatusBanner
├── Today Total card (greeting + expense summary)
├── Shared Feed (StreamBuilder, story format)
└── QuickAddBar (fixed bottom)
```

### Transaction List

```
AppScaffold
├── Time range chips (Day/Week/Month) + view toggle (List/Calendar)
├── Range picker (◀ label ▶)
├── Summary (income + expense)
├── Filter row (wallet, category, member)
├── Content (list or calendar, scrollable)
└── QuickAddBar (fixed bottom)
```

### Settings

```
AppScaffold
└── ListView
    ├── Profile card (avatar, name, auth actions)
    ├── Manage section (wallets, categories, recurring)
    ├── Preferences section (language, reminder)
    └── Data section (export, privacy, debug)
```

---

## 10. Anti-patterns

| ❌ Don't | ✅ Do |
|----------|------|
| Paper textures, sepia | Clean off-white background |
| Bank-style dashboards | Minimal feed |
| Aggressive red for expense | Warm orange (`#D4845A`) |
| Handwriting fonts | System sans-serif |
| Dense data tables | Story format with emoji |
| Complex insights on home | Simple "Hôm nay chi 120k" |
| Childish stickers | Subtle emoji, light tone |

---

## 11. Checklist

Before shipping any UI:

- [ ] Easy to understand in 3 seconds?
- [ ] Feels like sharing, not tracking?
- [ ] Reducing friction or adding it?
- [ ] Couple comfortable using this together?
- [ ] Uses `AppColors`, `AppTextStyles`, `AppSpacing` (no inline)?
- [ ] Gestures follow the gesture map?
- [ ] Loading state is shimmer (not spinner)?
- [ ] All strings use `S.of(context, 'key')`?
