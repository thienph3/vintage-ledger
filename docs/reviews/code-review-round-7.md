# Code Review Round 7 — Đánh giá tổng thể

> 78 file Dart | ~7.600 LOC | 6 test files | 9 features
> Từ Round 1 (63 files, 5.700 LOC, 0 features cloud) → Round 7 (78 files, 7.600 LOC, full Firebase stack)

---

## Điểm tổng: 9/10

---

## 1. Điểm mạnh

### Kiến trúc
- **Feature-first** nhất quán 9 modules: auth, account, wallet, transaction, category, sync, settings, home, + core/common
- **Layer separation** rõ ràng: models → repositories → services → screens → widgets
- **Unified Account concept** — personal và family cùng schema, app chỉ switch `account_id`. Đơn giản, mở rộng tốt
- **ServiceLocator + AppState** — DI lightweight, không cần package ngoài, mọi screen truy cập qua `sl.*`

### Data layer
- **SQLite schema** sạch: FK constraints, CHECK constraints, composite indexes, sync metadata
- **Atomic transactions** cho create/update/delete — balance luôn consistent
- **Sync-ready schema** — `is_synced`, `remote_id`, `account_id`, `sync_deletes` table tích hợp sẵn
- **DB version 1** — clean slate, không migration debt

### Sync engine
- **Full push/pull cycle**: dirty flag → push → remote_id mapping → pull → upsert → recalculate
- **Cross-device ID mapping**: wallet_id/category_id convert local↔remote khi push/pull
- **Tombstone delete sync**: delete log → push tombstone → pull detect deleted_at → local delete
- **Last-write-wins conflict resolution**: local dirty + newer → skip remote overwrite
- **Spark plan optimized**: lazy sync, batch writes, incremental pull, embedded items, no realtime listeners
- **Tombstone cleanup**: auto 1 lần/ngày, xóa docs > 30 ngày

### UI/UX
- **Theme system** xuất sắc: AppColors, AppTextStyles (final), AppSpacing — zero inline styles
- **17 reusable widgets**: AppScaffold, LedgerCard, AmountText, AsyncContent, FormSaveButton, CrudListMixin...
- **Vintage identity** nhất quán: SpecialElite + PatrickHand fonts, paper background, ink colors
- **Multi-language**: vi/en với ~80 l10n keys, `S.of(context, key)` lightweight

### Code quality
- **TransactionType enum** xuyên suốt — no string magic
- **Models có copyWith/==/hashCode** — type-safe, testable
- **Error handling** ở mọi screen: try-catch, AsyncContent, loading/error states
- **NavigatorX extension** + `showDeleteConfirmation` helper — giảm boilerplate

---

## 2. Điểm yếu

### Testing
- Chỉ 6 test files (~35 test cases) cho formatters, models, enum, upsert logic
- **Không có test cho**: services (TransactionService balance logic), sync flow (push/pull end-to-end), screens (widget tests)
- Sync là phần phức tạp nhất nhưng chỉ có 4 test cases cho upsertByRemoteId

### State management
- Toàn bộ dùng `setState()` — OK cho app hiện tại nhưng:
  - Không share state giữa screens (wallet thay đổi → home không biết cho đến khi pop + reload)
  - `AppState` là plain object, không reactive — screens phải tự poll
  - Nếu thêm features (notifications, background sync) sẽ cần refactor

### Firestore security
- `firestore.rules` viết nhưng **chưa deploy** (chỉ có trong file, chưa test thực tế)
- Security rule đọc `member_ids` từ account document mỗi request → tốn 1 read extra per operation
- Không có rate limiting hay validation rules cho data fields

### Error messages
- Firebase exceptions hiển thị raw (`Exception: [firebase_auth/wrong-password]...`) — nên map sang user-friendly messages
- Sync errors hiển thị technical details trong snackbar

### Offline edge cases
- Skip login → local mode hoạt động, nhưng nếu user muốn login sau → không có flow "connect existing local data to new account"
- `_maybeImportFromCloud` chỉ chạy khi login lần đầu — nếu fail (offline) thì không retry

---

## 3. Điểm cần bổ sung cho production

### Must-have
| # | Mô tả |
|---|---|
| 1 | **Deploy Firestore rules** — test thực tế trên Firebase Console |
| 2 | **Map Firebase error messages** — `wrong-password` → "Sai mật khẩu", `email-already-in-use` → "Email đã tồn tại" |
| 3 | **Password reset flow** — "Quên mật khẩu?" link trên LoginScreen |
| 4 | **Dispose TextEditingControllers** trong screens chưa dispose (kiểm tra tất cả form screens) |
| 5 | **flutter_slidable** dependency — import trong pubspec nhưng `SwipeListItem` dùng `Dismissible` native, không dùng flutter_slidable. Xóa dependency thừa |

### Should-have
| # | Mô tả |
|---|---|
| 6 | **Integration test** cho sync flow: push → pull → verify data consistency |
| 7 | **Retry sync** khi app resume từ background (nếu có dirty data) |
| 8 | **Account name edit** — hiện tại không có cách đổi tên personal account hoặc family |
| 9 | **Loading indicator khi login** — `_maybeImportFromCloud` có thể chậm nhưng không show progress |
| 10 | **Confirm trước khi Skip login** — user có thể bấm nhầm, mất cơ hội sync |

### Nice-to-have
| # | Mô tả |
|---|---|
| 11 | **Dark mode** — AppTheme đã có structure, chỉ cần thêm `AppTheme.dark` |
| 12 | **Export/Import CSV** — backup data ngoài cloud |
| 13 | **Recurring transactions** — thu chi định kỳ (lương hàng tháng, tiền nhà...) |
| 14 | **Budget/Spending limit** — set giới hạn chi tiêu per category |
| 15 | **Push notifications** — nhắc nhở ghi thu chi, thông báo khi family member thêm transaction |

---

## 4. Tổng kết

Codebase đã **production-ready cho MVP**. Core features hoàn chỉnh: CRUD wallets/transactions/categories, charts, multi-account, family sharing, cloud sync. Kiến trúc sạch, code consistent, theme đẹp.

Để ship v1.0, cần fix 5 must-have items (chủ yếu là deploy rules + UX polish). Phần còn lại là enhancement cho v1.1+.

```
Tiến trình qua 7 rounds:
R1: 7.5  → DB fixes, reuse widgets
R2: 8.5  → Enum, DI, base patterns
R3: 9.0  → Full type safety, cached data
R4: 8.0  → Firebase integration (nhiều code mới)
R5: 9.0  → accountId routing, sync polish
R6: 9.5  → Dead code cleanup, push safety
R7: 9.0  → Biometric removed, DB simplified, final assessment
```
