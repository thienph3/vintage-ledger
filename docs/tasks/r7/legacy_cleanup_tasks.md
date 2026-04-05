# Tasks: Legacy Cleanup

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | Delete join_family_screen | `lib/features/account/screens/join_family_screen.dart` | Replaced by invite-by-email. Verify no imports |
| 2 | Delete invite_token | `lib/features/account/models/invite_token.dart` | Replaced by pending_invites. Verify no imports |
| 3 | Delete error_snackbar | `lib/common/widgets/error_snackbar.dart` | Replaced by app_snackbar. Verify no imports |
| 4 | Remove legacy color aliases | `app_colors.dart` | Delete `paper`, `inkBlue`, `inkPurple`, `inkBlack`, `inkRed` (only after all token migrations done) |
| 5 | Clean unused imports | All files | Run analysis, remove unused imports |
| 6 | Remove google_fonts | `pubspec.yaml` | Not used after font migration. Verify no imports |
