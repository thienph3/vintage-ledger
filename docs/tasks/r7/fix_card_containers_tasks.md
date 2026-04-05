# Tasks: Fix Card Containers (H1)

> `LedgerListTile` shadow 0.12 quá đậm + bị duplicate khi nằm trong `SwipeListItem`.
> SwipeListItem đã có Card bên trong → LedgerListTile thừa.

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | Xoá `LedgerListTile` | `ledger_list_tile.dart` | Widget thừa — SwipeListItem đã wrap Card(surface, radius 16) |
| 2 | WalletListScreen bỏ LedgerListTile | `wallet_list_screen.dart` | SwipeListItem > child: Padding + Row (không cần LedgerListTile wrapper) |
| 3 | CategoryListScreen bỏ LedgerListTile | `category_list_screen.dart` | Same — SwipeListItem > child: Padding + Row |
| 4 | SwipeListItem soft shadow | `swipe_list_item.dart` | Thay `Card(elevation: 0)` → `Container` với shadow 0.04 (match LedgerCard) |
| 5 | Verify không còn import ledger_list_tile | All files | grep + remove unused imports |
