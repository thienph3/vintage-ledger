# Tasks: Transaction List Redesign

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | Enums + state refactor | `transaction_list_screen.dart` | Thêm `TimeRangeMode { day, week, month }`, `ViewMode { list, calendar }`. Rename `_currentMonth` → `_rangeAnchor`, `_loadMonth()` → `_loadRange()`. Thêm `_selectedDate = DateTime.now()`. Mặc định `month` + `list` |
| 2 | `_loadRange()` theo mode | `transaction_list_screen.dart` | Tính start/end dựa trên `_timeRange`: day (00:00→23:59), week (Mon→Sun), month (giữ nguyên). `_changeRange(int delta)` thay `_changeMonth` |
| 3 | Time range chip row | `transaction_list_screen.dart` | Row 3 chip (Ngày/Tuần/Tháng) dưới AppBar. Active = filled soft accent + bold text, inactive = outlined + muted. Tap → set `_timeRange`, snap `_rangeAnchor` về khoảng chứa today, gọi `_loadRange()` |
| 4 | Range picker refactor | `transaction_list_screen.dart` | Refactor `_buildMonthPicker` → `_buildRangePicker`. Label format theo mode: day = `Thứ Hai, 14/07`, week = `08/07 – 14/07`, month = giữ nguyên. ◀ ▶ chuyển ±1 đơn vị. Tap label → date picker |
| 5 | View mode toggle | `transaction_list_screen.dart` | Icon toggle (list/calendar) bên phải dòng time range chip. Chỉ hiển thị khi `_timeRange == month`. Tap → switch `_viewMode` |
| 6 | List mode theo time range | `transaction_list_screen.dart` | Mode day: flat list (không group). Mode week: group 7 ngày. Mode month: giữ nguyên day-group expand/collapse |
| 7 | Calendar grid widget | `transaction/widgets/calendar_grid.dart` | Widget nhận `DateTime month`, `Map<int, int> dailyExpense`, `int? selectedDay`, `int? today`, `onDayTap(int)`. Grid 7 cột (T2→CN), mỗi ô: số ngày + expense compact (`-80k`). Today = dot highlight, selected = filled accent bg |
| 8 | Calendar detail section | `transaction_list_screen.dart` | Dưới CalendarGrid: header ngày+thứ, list TransactionFeedItem của `_selectedDate`. Mặc định chọn today (hoặc ngày cuối có txn nếu tháng cũ) |
| 9 | Calendar ↔ filter tích hợp | `transaction_list_screen.dart` | Khi filter thay đổi → re-calculate `dailyExpense` map từ `_filtered` + re-filter detail section |
| 10 | DateFormatter helpers | `date_formatter.dart` | Thêm `dayWithWeekday(DateTime)` → `Thứ Hai, 14/07`, `weekRange(DateTime)` → `08/07 – 14/07`. Hỗ trợ locale vi/en |
| 11 | L10n keys | `app_vi.dart`, `app_en.dart` | Thêm: `day`/`DAY`, `week`/`WEEK`, `month`/`MONTH`, `calendarView`/`Calendar`, `listView`/`List` |
