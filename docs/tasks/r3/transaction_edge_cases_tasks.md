# Tasks: Transaction Edge Case Handling

> Balance luôn đúng trong mọi case.

## Tasks

| # | Task | Mô tả | Status |
|---|------|--------|--------|
| 1 | Test: change amount | 100k expense → 200k expense. Balance delta = -100k | ✅ |
| 2 | Test: change type | expense 100k → income 100k. Balance delta = +200k | ✅ |
| 3 | Test: change wallet | A expense 100k → B expense 100k. A +100k, B -100k | ✅ |
| 4 | Test: change wallet + amount + type | A expense 100k → B income 200k. A +100k, B +200k | ✅ |
| 5 | Test: delete transaction | Delete expense 100k. Balance +100k | ✅ |
| 6 | Test: concurrent updates | Cần Firestore emulator — logic đã đúng vì dùng runTransaction | ⏳ |
| 7 | Write unit tests | `test/transaction/atomic_balance_test.dart` — 8 test cases cover create/delete/update (same wallet + different wallet) | ✅ |
