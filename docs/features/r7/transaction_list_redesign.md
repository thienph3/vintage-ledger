# Feature: Transaction List Screen Redesign

## Vấn đề

Screen hiện tại chỉ có 1 mode (list theo tháng) với day-group expand/collapse. Thiếu:
- Không chuyển được time range (ngày / tuần / tháng)
- Không có calendar view để scan nhanh chi tiêu theo ngày
- Month picker cứng nhắc, "fintech" style

## Giải pháp

Redesign thành 2 trục điều khiển:
1. **Time Range Mode**: ngày / tuần / tháng — quyết định khoảng thời gian load data
2. **View Mode**: list / calendar — quyết định cách hiển thị data

Giữ nguyên filter row (wallet, category, user) + QuickAddBar.

---

## 1. Time Range Mode

### UI
Dãy 3 chip nằm ngang, ngay dưới navigation bar (trước summary):

```
[ Ngày ]  [ Tuần ]  [ Tháng ✓ ]
```

- Chip active: filled soft accent, text đậm
- Chip inactive: outlined, text mờ
- Mặc định: **Tháng**

### Behavior

| Mode   | Range picker hiển thị         | Data load                        |
|--------|-------------------------------|----------------------------------|
| Ngày   | `◀ Thứ Hai, 14/07 ▶`         | 1 ngày (00:00 → 23:59)          |
| Tuần   | `◀ 08/07 – 14/07 ▶`          | 7 ngày (Mon → Sun)              |
| Tháng  | `◀ Tháng 7, 2025 ▶`          | Toàn bộ tháng (giữ nguyên hiện tại) |

- Tap vào label giữa → mở date picker (giống hiện tại)
- `◀` `▶` chuyển -1 / +1 đơn vị tương ứng
- Khi chuyển mode, snap về khoảng chứa ngày hiện tại

---

## 2. View Mode

### UI
Toggle icon nhỏ nằm bên phải dòng time range chip:

```
[ Ngày ]  [ Tuần ]  [ Tháng ✓ ]          📋 | 📅
```

- `📋` = list (mặc định)
- `📅` = calendar
- Calendar mode chỉ khả dụng khi time range = **Tháng** (ẩn toggle ở mode Ngày/Tuần)

### 2.1 List Mode (mặc định)

Giữ nguyên layout hiện tại: day-group header → expand → TransactionFeedItem.

- Mode Ngày: không group theo day, hiển thị flat list
- Mode Tuần: group theo day (7 ngày)
- Mode Tháng: group theo day (giữ nguyên)

### 2.2 Calendar Mode (chỉ ở Tháng)

Grid 7 cột (T2 → CN), mỗi ô là 1 ngày:

```
T2    T3    T4    T5    T6    T7    CN
                   1     2     3     4
                        -30k  -15k
 5     6     7     8     9    10    11
-80k  -45k              -20k  -50k
...
```

**Mỗi ô hiển thị:**
- Số ngày (top, nhỏ)
- Tổng expense ngày đó (bottom, đỏ nhạt, compact format: `-80k`)
- Nếu không có txn → ô trống (chỉ số ngày)
- Ngày hiện tại: highlight nhẹ (circle hoặc dot)
- Ngày được chọn: filled accent background

**Tap vào ô:**
- Set ngày đó làm selected
- Phần detail bên dưới calendar hiển thị danh sách txn của ngày đó

**Detail section (dưới calendar grid):**

```
──── 14/07 (Thứ Hai) ────
[ Bạn cafe 30k ☕  08:30 ]
[ Bạn ăn trưa 50k 🍜 12:15 ]
```

- Header: ngày + thứ
- Body: TransactionFeedItem list (story format, avatar, reactions)
- Mặc định khi vào calendar mode: chọn ngày hiện tại (hoặc ngày cuối có txn nếu xem tháng cũ)

---

## 3. Filters (giữ nguyên)

Filter row nằm dưới summary, trên content area:

- **Wallet**: InlineSelector → SelectionSheet (ẩn nếu chỉ 1 ví hoặc đã fix walletId)
- **Category**: InlineSelector → SelectionSheet
- **User**: InlineSelector → SelectionSheet (ẩn nếu chỉ 1 member)

Filter áp dụng cho cả list mode và calendar mode. Khi filter thay đổi:
- List mode: re-filter danh sách
- Calendar mode: re-calculate expense mỗi ô + re-filter detail section

---

## 4. Summary Row

Nằm dưới range picker, trên filter row:

```
Thu nhập: +200k          Chi tiêu: -350k
```

- Tính trên data đã filter trong time range hiện tại
- Giữ nguyên style hiện tại (compact currency, income green / expense red)

---

## 5. Layout tổng thể

```
┌─────────────────────────────────┐
│ AppScaffold (SỔ GIAO DỊCH)     │
├─────────────────────────────────┤
│ [ Ngày ] [ Tuần ] [ Tháng ✓ ] 📋|📅 │  ← time range + view toggle
│ Thu nhập: +200k    Chi: -350k   │  ← summary
│ 🏦 Tất cả  📂 Tất cả  👤 Mọi người │  ← filters
├─────────────────────────────────┤
│                                 │
│   (List hoặc Calendar content)  │  ← Expanded, scrollable
│                                 │
├─────────────────────────────────┤
│ [ QuickAddBar ]                 │  ← fixed bottom
└─────────────────────────────────┘
```

---

## 6. State Management

```dart
// Thêm vào state
enum TimeRangeMode { day, week, month }
enum ViewMode { list, calendar }

TimeRangeMode _timeRange = TimeRangeMode.month;
ViewMode _viewMode = ViewMode.list;
DateTime _selectedDate = DateTime.now();  // dùng cho calendar selected day
```

- `_currentMonth` → rename thành `_rangeAnchor` (DateTime gốc để tính range)
- `_loadMonth()` → rename thành `_loadRange()`, tính start/end dựa trên `_timeRange`
- Khi chuyển `_timeRange`, snap `_rangeAnchor` về khoảng chứa `DateTime.now()`
- `_selectedDate` mặc định = today, dùng cho calendar detail

---

## 7. Localization Keys (thêm mới)

| Key             | vi              | en              |
|-----------------|-----------------|-----------------|
| `day`           | `NGÀY`          | `DAY`           |
| `week`          | `TUẦN`          | `WEEK`          |
| `month`         | `THÁNG`         | `MONTH`         |
| `calendarView`  | `Lịch`          | `Calendar`      |
| `listView`      | `Danh sách`     | `List`          |

---

## 8. Checklist (theo Style Guide R7)

- [ ] Scan được trong 3 giây? → Calendar cho cái nhìn tổng quan expense cả tháng
- [ ] Cảm giác sharing, không phải tracking? → Story format giữ nguyên, calendar chỉ show expense nhẹ
- [ ] Giảm friction? → Tap ngày trên calendar = xem detail ngay, không cần navigate
- [ ] Couple comfortable? → Filter theo user để xem "ai tiêu gì"
