# Feature: App Startup & Bootstrap Redesign

## Vấn đề

Flow khởi động hiện tại trong `_MyAppState._init()` có nhiều vấn đề:

1. **Monolithic** — Tất cả logic nằm trong 1 method `_init()` dài, trộn lẫn auth check, account resolve, wallet seed, locale load, background init
2. **Không có feedback** — User chỉ thấy `CircularProgressIndicator` quay mòng mòng, không biết app đang làm gì, mất bao lâu
3. **Branching phức tạp** — 3 nhánh (anonymous mới, anonymous cũ, logged-in) xử lý khác nhau nhưng code lồng nhau khó đọc
4. **Timeout rải rác** — Mỗi call có timeout riêng (5s, 10s), không nhất quán
5. **Background init không rõ ràng** — `QuickAddParser.init()`, `QuickAddHistory.init()`, `AmountHistory.init()`, `notificationService.init()`, `recurringService.checkAndRun()`, `reminderService.init()` gọi rời rạc ở cuối, dễ quên khi thêm service mới
6. **Error handling yếu** — Catch chung `e.toString()`, không phân biệt lỗi mạng vs lỗi logic

## Giải pháp

### 1. Tách bootstrap thành pipeline có step rõ ràng

```dart
enum BootstrapStep {
  auth,        // Check/create Firebase auth
  account,     // Resolve account (personal or last used)
  settings,    // Load locale, last wallet, preferences
  data,        // Preload categories, wallets (critical data)
  background,  // Non-blocking: notifications, recurring, reminders, quick-add cache
}
```

Mỗi step:
- Có label hiển thị cho user
- Có thể fail independently
- Critical steps (auth → account → settings → data) chạy tuần tự, fail = retry/fallback
- Background step chạy non-blocking, không ảnh hưởng UX

### 2. Progressive Loading Screen thay CircularProgressIndicator

```
┌─────────────────────────────────┐
│                                 │
│        📖 Vintage Ledger        │
│                                 │
│     ━━━━━━━━━━━━━━━━━━━━━━━━    │  ← progress bar (muted accent)
│     Đang tải danh mục...        │  ← step label (caption style)
│                                 │
└─────────────────────────────────┘
```

- App icon/logo ở giữa
- Linear progress bar (determinate: step/totalSteps)
- Label mô tả step hiện tại (casual tone)
- Background color = `AppColors.background`
- Nếu lỗi: hiển thị message + nút "Thử lại"

### 3. Kịch bản khởi động

| Kịch bản | Auth step | Account step | Ghi chú |
|-----------|-----------|--------------|---------|
| Lần đầu (chưa login) | `signInAnonymously()` | Tạo personal account + seed wallet | Vào thẳng MainShell |
| Anonymous quay lại | Detect `user.isAnonymous` | Load account từ `currentUserId` | Vào thẳng MainShell |
| Đã login (1 account) | Detect logged-in user | Load `lastAccountId` hoặc resolve | Vào thẳng MainShell |
| Đã login (nhiều account) | Detect logged-in user | Load `lastAccountId` | Nếu có lastAccountId → MainShell, nếu không → AccountPicker |
| Token expired / lỗi auth | Catch auth error | — | Hiển thị LoginScreen |

### 4. BootstrapService

Tạo `BootstrapService` tập trung logic:

```dart
class BootstrapService {
  Stream<BootstrapProgress> run();
}

class BootstrapProgress {
  final BootstrapStep step;
  final int current;    // 0-based index
  final int total;      // total critical steps
  final String label;   // user-facing label
  final bool done;
  final BootstrapResult? result;
}

class BootstrapResult {
  final bool needsLogin;      // → LoginScreen
  final bool needsAccountPick; // → AccountPickerScreen
  final Locale locale;
}
```

- `_init()` trong `_MyAppState` chỉ listen stream, update UI
- Logic phức tạp nằm trong `BootstrapService`
- Dễ test, dễ thêm step mới

### 5. Step labels (casual tone theo Style Guide)

| Step | vi | en |
|------|----|----|
| auth | Đang kết nối... | Connecting... |
| account | Đang mở sổ... | Opening ledger... |
| settings | Đang tải cài đặt... | Loading settings... |
| data | Đang tải danh mục... | Loading categories... |
| background | Sắp xong rồi... | Almost ready... |

### 6. Error & Retry

- Nếu critical step fail (auth, account): hiển thị error message + nút "Thử lại" trên loading screen
- Nếu settings/data fail: dùng defaults, vẫn vào app (graceful degradation)
- Background fail: silent, log only

### 7. Timeout strategy

- Mỗi critical step: 8s timeout (nhất quán)
- Toàn bộ bootstrap: 30s max, sau đó force vào app với defaults
- Background: không timeout (fire-and-forget)

---

## Layout: SplashBootstrapScreen

```
┌─────────────────────────────────┐
│                                 │
│                                 │
│        📖                       │  ← Icon(Icons.menu_book_rounded, 64)
│     Vintage Ledger              │  ← AppTextStyles.title
│                                 │
│     ━━━━━━━━━━━━━━━━━━━━━━━━    │  ← LinearProgressIndicator (value: step/total)
│     Đang mở sổ...              │  ← AppTextStyles.hint
│                                 │
│                                 │
│     [ Thử lại ]                 │  ← chỉ hiện khi error (OutlinedButton)
│     Hmm, có gì đó sai rồi      │  ← AppTextStyles.error
│                                 │
└─────────────────────────────────┘
```

---

## Cấu trúc file

```
lib/
├── core/
│   └── bootstrap/
│       ├── bootstrap_service.dart    # Pipeline logic
│       └── bootstrap_models.dart     # BootstrapStep, BootstrapProgress, BootstrapResult
├── features/
│   └── splash/
│       └── splash_bootstrap_screen.dart  # UI
└── main.dart                         # Simplified: chỉ listen BootstrapService
```

---

## Checklist (Style Guide R7)

- [ ] Scan 3 giây? → Progress bar + label cho biết app đang làm gì
- [ ] Cảm giác sharing? → Tone casual: "Đang mở sổ...", "Sắp xong rồi..."
- [ ] Giảm friction? → Không cần user action, tự chạy pipeline
- [ ] Couple comfortable? → Không có loading spinner vô hồn, có personality
