# Tasks: Shared Feed — Social Visibility

Design for shared visibility: luôn hiện "ai làm gì". Family-first experience.

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | Feed item component | `lib/features/feed/widgets/feed_item.dart` | Avatar (initials circle) + story text + time. Giống chat bubble nhưng không phải bubble |
| 2 | Feed screen | `home_screen.dart` hoặc `lib/features/feed/screens/feed_screen.dart` | ListView of feed items, mới nhất ở dưới (chat order). Pull up load more |
| 3 | Actor resolution | `lib/features/feed/feed_helper.dart` | Resolve userId → name. Personal account: "Bạn". Family: tên thật. Cache names |
| 4 | Time display | Feed items | Relative time: "vừa xong", "5 phút trước", "hôm qua". Group by day separator |
| 5 | Day separator | Feed | "Hôm nay", "Hôm qua", "Thứ 2, 23/6" — casual, không formal |
| 6 | Activity integration | Feed | Merge transactions + activities (join/leave/wallet create) vào 1 feed. Transactions = story format. Activities = system message style (centered, muted) |
| 7 | Real-time updates | Feed | StreamBuilder cho feed — new items appear instantly |
| 8 | Personal vs Family | Feed | Personal: feed chỉ có "Bạn". Family: feed có tất cả members. Cùng component, khác data |
