# Tasks: Minimal Testing — ✅

| # | Task | Status |
|---|------|--------|
| 1 | AmountFormatter multi-currency tests | ✅ VND vi/compact, USD, JPY — `test/utils/currency_formatter_test.dart` |
| 2 | QuickAddParser tests update | ✅ Existing tests cover learned/LRU. Fuzzy flag added |
| 3 | Currency model tests | ✅ fromCode, hasDecimals, all count — same test file |
| 4 | ErrorMapper tests | ✅ AppException passthrough, unknown → genericError — `test/core/error_mapper_test.dart` |
| 5 | Budget model tests | ✅ Inline percentage/flags tests in error_mapper_test.dart |
| 6 | TransactionService integration test | ⏳ Cần Firestore emulator. Balance logic covered in `test/transaction/atomic_balance_test.dart` |
