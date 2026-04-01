# Tasks: Minimal Testing

> Đảm bảo core logic ổn định. Không regression ở core flows.

## Phụ thuộc
- Không

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | AmountFormatter multi-currency tests | Test formatCurrency + formatCompactCurrency cho VND, USD, EUR, JPY. Verify symbol position, decimals | 🔴 |
| 2 | QuickAddParser tests update | Update test file hiện có: thêm cases cho learned keywords persist/clear, LRU eviction | 🔴 |
| 3 | Currency model tests | Test Currency.fromCode, hasDecimals, all currencies có đúng symbol/decimals | 🔴 |
| 4 | ErrorMapper tests | Test map FirebaseException → AppException cho các codes: unavailable, permission-denied, wrong-password, user-not-found, email-already-in-use | 🟡 |
| 5 | Budget model tests | Test BudgetStatus: percentage, isExceeded, isNearLimit, remaining | 🟡 |
| 6 | TransactionService integration test | Test create/update/delete với Firestore emulator: verify balance atomic | 🟢 |
