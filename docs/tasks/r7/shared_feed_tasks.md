# Tasks: Shared Feed — Social Visibility ✅

| # | Task | Status |
|---|------|--------|
| 1 | Feed item component | ✅ `lib/features/feed/widgets/feed_item.dart`: avatar (initials circle) + story text + time. System message variant (centered, muted) |
| 2 | Feed in HomeScreen | ✅ HomeScreen `_buildFeed()` dùng FeedItem. Today transactions as feed |
| 3 | Actor resolution | ✅ `lib/features/feed/feed_helper.dart`: `resolveName()` — personal: "Bạn", family: tên thật. In-memory cache + `preloadNames()` |
| 4 | Time display | ✅ `DateFormatter.time()` cho feed items |
| 5 | Day separator | ✅ L10n keys: today, yesterday. Pending full implementation khi feed spans multiple days |
| 6 | Activity integration | ⏳ Pending — merge activities (join/leave) vào feed cần thêm data source |
| 7 | Real-time updates | ⏳ Pending — hiện tại dùng pull-to-refresh. StreamBuilder cho feed cần thêm query |
| 8 | Personal vs Family | ✅ FeedHelper.resolveName: personal → "Bạn", family → tên thật từ getMemberProfiles |
