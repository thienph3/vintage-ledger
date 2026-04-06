# Tasks: Account Picker UX Redesign

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | Remove long press | `account_picker_screen.dart` | Bỏ `onLongPress` trên account cards. Bỏ import `FamilyDetailScreen` |
| 2 | Swipe-to-delete family | `account_picker_screen.dart` | Wrap family cards trong `SwipeListItem`. Owner → delete, member → leave. `DeleteConfirmation` dialog |
| 3 | Settings — family section | `setting_screen.dart` | Khi `isFamily`: thêm "Nhóm" section với tiles: Thành viên, Mời người thân, Hoạt động, Rời/Xóa nhóm |
| 4 | Member list in settings | `setting_screen.dart` hoặc **NEW** widget | Reuse member list từ `FamilyDetailScreen`. Tap tile → bottom sheet hoặc screen hiện members + remove button (owner only) |
| 5 | Invite from settings | `setting_screen.dart` | Reuse `_inviteByEmail()` logic. Tap "Mời người thân" → email dialog |
| 6 | Activity from settings | `setting_screen.dart` | Tap "Hoạt động" → navigate `FamilyDetailScreen` (giữ lại cho activity view) hoặc inline stream |
