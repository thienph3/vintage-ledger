# Tasks: Family Detail + Recurring Cleanup (H3, H4)

> H3: FamilyDetailScreen activity feed không dùng story format — inconsistent.
> H4: RecurringListScreen có cả FAB + inline button — redundant.

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | FamilyDetail: member avatars load photo_url | `family_detail_screen.dart` | CircleAvatar dùng `backgroundImage: NetworkImage(photo_url)` nếu có. Fallback initials |
| 2 | FamilyDetail: section titles → titleSmall | `family_detail_screen.dart` | `AppTextStyles.title` → `AppTextStyles.titleSmall` cho "Members" và "Activity" headers |
| 3 | FamilyDetail: activity feed dùng FeedItem | `family_detail_screen.dart` | Thay inline `_buildActivityTile` → dùng `FeedItem` widget cho consistent look. Grouped activities giữ nguyên logic |
| 4 | RecurringList: bỏ FAB | `recurring_list_screen.dart` | Xoá `fab:` param. Giữ inline ElevatedButton.icon ở bottom list |
| 5 | RecurringList: rule tile soft style | `recurring_list_screen.dart` | Wrap mỗi rule trong SwipeListItem thay vì bare Padding. Consistent với wallet/category lists |
