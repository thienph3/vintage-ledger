# Tasks: Stream Read Optimization — ✅

| # | Task | Status |
|---|------|--------|
| 1 | Audit stream usage | ✅ 4 streams: HomeScreen wallets (keep), WalletListScreen (keep), CategoryListScreen (→ get), WalletDetailScreen (keep) |
| 2 | Replace chart stream → get | ✅ Already uses getDashboard one-shot |
| 3 | Replace budget stream → get | ✅ Already uses getBudgetStatuses one-shot |
| 4 | Limit transaction stream | ✅ watchRecent not used by screens (getDashboard limit 5 used instead) |
| 5 | CategoryListScreen stream → get | ✅ Replaced StreamBuilder with StatefulWidget + getCategories() + manual reload on add/edit/delete |
| 6 | Measure before/after | ⏳ Cần chạy app thật |
