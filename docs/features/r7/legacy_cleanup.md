# Feature: Legacy Cleanup

## Files to delete
| File | Reason |
|---|---|
| `lib/features/account/screens/join_family_screen.dart` | Replaced by invite-by-email flow |
| `lib/features/account/models/invite_token.dart` | Replaced by pending_invites |
| `lib/common/widgets/error_snackbar.dart` | Replaced by app_snackbar.dart |

## Legacy aliases to remove (after all migrations done)
Trong `app_colors.dart`, bỏ:
```dart
static const paper = background;
static const inkBlue = primary;
static const inkPurple = primary;
static const inkBlack = textPrimary;
static const inkRed = error;
```

## Unused imports to clean
Run `flutter analyze` sau khi migrate xong để tìm unused imports.
