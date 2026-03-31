# Feature: User Management + Family + Shared Wallets

## Core Concept

Personal và family đều là **account**. Mỗi account chứa bộ data riêng (wallets, transactions, categories) với cùng cấu trúc. User đăng nhập → chọn account → app load data của account đó.

```
User đăng nhập
  └── Account Picker
        ├── 📱 Ví cá nhân          → personal account
        ├── 👨‍👩‍👧 Gia đình Nguyễn     → family account
        └── ＋ Tạo gia đình mới
```

Trong app, mọi thứ hoạt động y hệt — không cần phân biệt personal hay family.

## Firestore Schema

```
accounts/{accountId}
  ├── type: "personal" | "family"
  ├── name: string
  ├── owner_id: userId
  ├── member_ids: [userId, ...]
  ├── created_at: timestamp
  │
  ├── wallets/{walletId}
  │     ├── name, created_at, updated_at, deleted_at?
  │
  ├── transactions/{transactionId}
  │     ├── wallet_id, category_id, type, amount, note?, date
  │     ├── created_by: userId
  │     ├── updated_at, deleted_at?
  │     └── items: [{ amount, note }]
  │
  └── categories/{categoryId}
        ├── name, type, icon, updated_at

users/{userId}
  ├── email, display_name, created_at
  └── account_ids: [accountId, ...]
```

### Security Rules

```javascript
match /accounts/{accountId}/{document=**} {
  allow read, write: if request.auth.uid in
    get(/databases/$(database)/documents/accounts/$(accountId)).data.member_ids;
}
```

## Authentication

Firebase Auth — Email/Password (free trên Spark plan).

```
App mở
  ├── Chưa login → Login/Register screen
  │     └── "Skip" → local-only (account_id = 'local', không sync)
  └── Đã login → Account Picker → Home screen
```

- Đã login 1 lần → Firebase cache credentials → offline OK
- Biometric lock hoạt động như layer trên auth

## Account Picker

```
┌─────────────────────────────────┐
│         CHỌN SỔ THU CHI        │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 📱  Ví cá nhân            │  │
│  │     3 ví · 15.200.000đ   │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 👨‍👩‍👧  Gia đình Nguyễn       │  │
│  │     2 ví · 3 thành viên   │  │
│  └───────────────────────────┘  │
│                                 │
│  ＋ Tạo gia đình mới            │
│                                 │
│  ⚙️ Cài đặt    🔄 Đồng bộ     │
└─────────────────────────────────┘
```

Chọn account → vào Home screen. Trong Home, thêm nút quay lại Account Picker.

App state chỉ cần:

```dart
class AppState {
  String? currentUserId;    // null nếu skip login
  String currentAccountId;  // 'local' hoặc Firestore accountId
}

// Mọi query filter theo currentAccountId
SELECT * FROM wallets WHERE account_id = ?
```

## Family Management

### Tạo

```
1. Nhập tên family
2. Tạo accounts/{newId} với type = "family", member_ids = [currentUserId]
3. Thêm newId vào users/{userId}.account_ids
```

### Mời thành viên

```
1. Nhập email → tìm user trên Firestore
2. Thêm userId vào accounts/{familyId}.member_ids
3. Thêm familyId vào users/{invitedUserId}.account_ids
```

> Không có Cloud Functions → xử lý client-side. Người được mời mở app + sync để thấy.

### Rời / Xóa

- Member tự rời: remove từ `member_ids` + `account_ids`
- Owner xóa member: tương tự
- Owner rời: chuyển owner hoặc xóa family nếu không còn ai
- Xóa family: xóa account + subcollections, remove từ `account_ids` tất cả members

### Quyền

| Account type | Ai truy cập |
|---|---|
| Personal | Chỉ owner (member_ids = [owner]) |
| Family | Tất cả member_ids |

## Screens

### Mới

| Screen | Mô tả |
|---|---|
| `LoginScreen` | Email + password, link register, nút "Skip" |
| `RegisterScreen` | Email + password + display name |
| `AccountPickerScreen` | Danh sách accounts, nút tạo family |
| `FamilyFormScreen` | Tạo family (nhập tên) |
| `FamilyDetailScreen` | Xem/mời/xóa members |

### Sửa

| Screen | Thay đổi |
|---|---|
| `main.dart` | Auth check → Account Picker → Home |
| `HomeScreen` | Nhận `accountId`, nút back về Account Picker |
| `*Service` | Mọi query thêm `WHERE account_id = ?` |
| `SettingScreen` | Thêm section Account (email, logout) |

### Không sửa

Form screens (Wallet, Transaction, Category) và widgets — không thay đổi vì đã ở trong context account.

## Folder Structure

```
lib/features/
  ├── auth/
  │     ├── screens/
  │     │     ├── lock_screen.dart        (giữ nguyên)
  │     │     ├── login_screen.dart       (mới)
  │     │     └── register_screen.dart    (mới)
  │     └── services/
  │           └── auth_service.dart       (mở rộng)
  │
  ├── account/                            (mới)
  │     ├── models/account.dart
  │     ├── screens/
  │     │     ├── account_picker_screen.dart
  │     │     ├── family_form_screen.dart
  │     │     └── family_detail_screen.dart
  │     └── services/account_service.dart
  │
  └── ... (giữ nguyên)
```

## Migration Plan

| Phase | Nội dung | Breaking? |
|---|---|---|
| 1. Auth | firebase_auth, Login/Register, "Skip" giữ app như cũ | Không |
| 2. Account | Thêm `account_id` column, Account Picker, services filter by account | Không (default 'local') |
| 3. Family | Family CRUD, mời thành viên, sync family data | Không |
| 4. Sync | Push/pull per account (xem [firebase-sync.md](firebase-sync.md)) | Không |

## L10n Keys

```dart
// Auth
'login', 'register', 'email', 'password', 'displayName', 'skipLogin', 'logout'

// Account Picker
'chooseAccount', 'personalAccount', 'walletCount', 'memberCount'

// Family
'createFamily', 'familyName', 'members', 'inviteMember',
'leaveFamily', 'deleteFamily', 'owner', 'member'
```
