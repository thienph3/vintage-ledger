# Tasks: User-friendly Error Handling

> Error rõ ràng, dễ hiểu. Không hiển thị raw Firebase exception.

## Phụ thuộc
- Không

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | AppException class | Custom exception với `code` và `userMessage`. Các service throw AppException thay vì raw Exception | 🔴 |
| 2 | FirestoreErrorMapper | Map `FirebaseException.code` → user-friendly message: `unavailable` → "Mất kết nối", `permission-denied` → "Không có quyền", `resource-exhausted` → "Hệ thống quá tải", default → "Có lỗi xảy ra" | 🔴 |
| 3 | Refactor showErrorSnackBar | Nhận `Object error`, nếu là `AppException` hiển thị `userMessage`, nếu là `FirebaseException` chạy qua mapper, còn lại hiển thị generic message | 🔴 |
| 4 | Wrap service methods | Tất cả service methods catch `FirebaseException` → throw `AppException` với message đã map | 🟡 |
| 5 | Auth error mapping | Map Firebase Auth errors: `wrong-password` → "Sai mật khẩu", `user-not-found` → "Tài khoản không tồn tại", `email-already-in-use` → "Email đã được sử dụng", `weak-password` → "Mật khẩu quá yếu" | 🟡 |
| 6 | L10n error keys | Thêm keys: noConnection, noPermission, systemOverload, genericError, wrongPassword, userNotFound, emailInUse, weakPassword | 🟡 |
| 7 | Retry action trong snackbar | SnackBar có nút "Thử lại" với callback, thay vì chỉ "Bỏ qua" | 🟢 |
