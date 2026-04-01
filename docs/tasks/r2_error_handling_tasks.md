# Tasks: User-friendly Error Handling

> Error rõ ràng, dễ hiểu. Không hiển thị raw Firebase exception.

## Phụ thuộc
- Không

## Tasks

| # | Task | Mô tả | Status |
|---|------|--------|--------|
| 1 | AppException class | `AppException(code, message)` — message là l10n key | ✅ |
| 2 | FirestoreErrorMapper | Map `FirebaseException.code` → l10n key: unavailable → noConnection, permission-denied → noPermission, resource-exhausted → systemOverload | ✅ |
| 3 | Refactor showErrorSnackBar | `ErrorMapper.map(error)` → `S.of(context, mapped.message)` → SnackBar với l10n message | ✅ |
| 4 | Wrap service methods | AuthService catch `FirebaseAuthException` → throw `AppException`. LoginScreen + RegisterScreen hiển thị mapped message | ✅ |
| 5 | Auth error mapping | wrong-password → wrongPassword, user-not-found → userNotFound, email-already-in-use → emailInUse, weak-password → weakPassword, invalid-email → invalidEmail, too-many-requests → tooManyRequests, network-request-failed → noConnection | ✅ |
| 6 | L10n error keys | 13 keys: noConnection, noPermission, systemOverload, genericError, wrongPassword, userNotFound, emailInUse, weakPassword, invalidEmail, tooManyRequests, notFound, alreadyExists, retry | ✅ |
| 7 | Retry action trong snackbar | `showErrorSnackBar(context, error, onRetry: callback)` — nút "Thử lại" nếu có callback, "Bỏ qua" nếu không | ✅ |
