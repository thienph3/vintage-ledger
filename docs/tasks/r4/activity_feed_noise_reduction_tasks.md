# Tasks: Activity Feed Noise Reduction

> Feed dễ đọc, không spam khi nhiều transactions.

## Phụ thuộc
- Không

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | Group transactions by user+day | Khi render activity list, group consecutive transaction activities cùng user_id + cùng ngày → hiển thị "{user} đã thêm {n} giao dịch hôm nay" thay vì n dòng riêng | 🔴 |
| 2 | Priority events styling | Join/leave family: icon lớn hơn + background highlight (nhẹ). Transaction activities: compact style | 🟡 |
| 3 | Limit feed to 30 items | Thay limit 20 → 30 trong `watchActivities`. Thêm "Xem thêm" button load thêm 30 | 🟡 |
| 4 | L10n keys | Thêm: addedTransactionsToday, viewMoreActivities | 🟢 |
