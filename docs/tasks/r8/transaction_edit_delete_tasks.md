# Tasks: Transaction Edit & Delete UX

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | Swipe-to-delete on feed items | `transaction_feed_item.dart` | Wrap trong `SwipeListItem`. Thêm `onDelete` callback. Swipe → `DeleteConfirmation` → delete |
| 2 | Delete button in edit form | `transaction_form_screen.dart` | Khi `isEdit`: thêm `OutlinedButton` "Xóa" (expense color) cuối form. Tap → `DeleteConfirmation` → delete → pop(true) |
| 3 | Undo snackbar after delete | `transaction_list_screen.dart`, `home_screen.dart` | Sau delete: snackbar "Đã xóa ✓" + "Hoàn tác" (5s). Undo = `createTransaction` lại với saved data |
| 4 | InkWell ripple on feed items | `feed_item.dart` | Đổi `GestureDetector` → `InkWell` cho ripple feedback khi tap |
| 5 | Type/wallet change warnings | `transaction_form_screen.dart` | Inline warning khi đổi type trong edit mode. Inline info khi đổi wallet |
| 6 | L10n keys | `app_vi.dart`, `app_en.dart` | `deleted`, `typeChangeWarning`, `walletChangeInfo` |
