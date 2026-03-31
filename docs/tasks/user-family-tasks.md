# Tasks — User Management + Family + Shared Wallets

> Ref: [docs/features/user-family-management.md](../features/user-family-management.md)

## Phase 1: Auth

| # | Task | Mô tả | Status |
|---|---|---|---|
| 1 | Thêm `firebase_core` + `firebase_auth` dependencies | Thêm vào `pubspec.yaml`, chạy `flutter pub get`. | ✅ |
| 2 | Init Firebase trong `main.dart` | Gọi `Firebase.initializeApp()` trước `runApp()`, dùng `firebase_options.dart` đã có. | ✅ |
| 3 | Mở rộng `AuthService` | Thêm methods: `loginWithEmail`, `registerWithEmail`, `logout`, `currentUser` getter. Giữ `authenticate` (biometric) nguyên. | ✅ |
| 4 | Tạo `RegisterScreen` | Form: email + password + display name. Gọi `AuthService.registerWithEmail`. Tạo personal account trên Firestore sau register. | ✅ |
| 5 | Tạo `LoginScreen` | Form: email + password. Link sang Register. Nút "Skip" → vào app local-only (`account_id = 'local'`). | ✅ |
| 6 | Cập nhật `main.dart` auth flow | Check `FirebaseAuth.currentUser`: null → LoginScreen, có → Account Picker (Phase 2) hoặc Home (tạm). "Skip" → Home như cũ. | ✅ |
| 7 | Tạo `users/{userId}` document khi register | Lưu email, display_name, created_at, account_ids (chứa personal accountId). | ⏳ Phase 2 (cần cloud_firestore) |
| 8 | Thêm l10n keys cho Auth | `login`, `register`, `email`, `password`, `displayName`, `skipLogin`, `logout` — cả vi và en. | ✅ |

## Phase 2: Account System

| # | Task | Mô tả | Status |
|---|---|---|---|
| 9 | DB migration: thêm `account_id` column | Thêm `account_id TEXT NOT NULL DEFAULT 'local'` vào wallets, transactions, categories. Bump DB version. | ⬜ |
| 10 | Cập nhật repositories: filter by `account_id` | Mọi query trong `WalletRepository`, `TransactionRepository`, `CategoryRepository` thêm `WHERE account_id = ?`. | ⬜ |
| 11 | Cập nhật services: truyền `accountId` | `WalletService`, `TransactionService`, `CategoryService` nhận `accountId` param hoặc đọc từ `AppState`. | ⬜ |
| 12 | Tạo `AppState` | Class giữ `currentUserId` + `currentAccountId`. Inject qua `ServiceLocator` hoặc `InheritedWidget`. | ⬜ |
| 13 | Tạo `Account` model | `id`, `type` (personal/family), `name`, `ownerId`, `memberIds`, `createdAt`. Có `toMap`/`fromMap`/`copyWith`. | ⬜ |
| 14 | Tạo `AccountService` | Firestore CRUD: `createAccount`, `getAccountsForUser`, `deleteAccount`. | ⬜ |
| 15 | Tạo `AccountPickerScreen` | Hiển thị danh sách accounts (personal + families). Tap → set `currentAccountId` → navigate Home. Nút tạo family. | ⬜ |
| 16 | Cập nhật `main.dart` navigation | Auth → AccountPicker → Home. "Skip" → Home với `account_id = 'local'`. | ⬜ |
| 17 | Cập nhật `HomeScreen` | Nhận `accountId`, thêm nút back về Account Picker. | ⬜ |
| 18 | Migrate local data khi login lần đầu | Gán `account_id = personalAccountId` cho tất cả records có `account_id = 'local'`. | ⬜ |
| 19 | Thêm l10n keys cho Account Picker | `chooseAccount`, `personalAccount`, `walletCount`, `memberCount` — cả vi và en. | ⬜ |

## Phase 3: Family

| # | Task | Mô tả | Status |
|---|---|---|---|
| 20 | Tạo `FamilyFormScreen` | Form nhập tên family. Gọi `AccountService.createAccount(type: family)`. | ⬜ |
| 21 | Tạo `FamilyDetailScreen` | Hiển thị members, nút mời thành viên, nút rời/xóa family. | ⬜ |
| 22 | Implement mời thành viên | Nhập email → tìm user trên Firestore → thêm vào `member_ids` + `account_ids`. | ⬜ |
| 23 | Implement rời family | Remove userId từ `member_ids` + `account_ids`. Nếu owner rời → chuyển owner hoặc xóa. | ⬜ |
| 24 | Implement xóa family | Xóa account document + subcollections. Remove accountId từ tất cả members. | ⬜ |
| 25 | Seed default categories cho family account | Khi tạo family account → copy default categories vào `accounts/{id}/categories/`. | ⬜ |
| 26 | Cập nhật `SettingScreen` | Thêm section Account: hiển thị email, nút logout. Link sang FamilyDetail nếu đang trong family account. | ⬜ |
| 27 | Thêm l10n keys cho Family | `createFamily`, `familyName`, `members`, `inviteMember`, `leaveFamily`, `deleteFamily`, `owner`, `member` — cả vi và en. | ⬜ |
| 28 | Firestore security rules | Deploy rules: `accounts/{accountId}/**` chỉ cho phép users trong `member_ids`. | ⬜ |
