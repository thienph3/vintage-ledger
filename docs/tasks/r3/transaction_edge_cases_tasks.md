# Tasks: Transaction Edge Case Handling

> Balance luôn đúng trong mọi case: change amount, change type, change wallet, delete.

## Phụ thuộc
- Không (logic đã có trong runTransaction, cần verify + test)

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | Test: change amount | old 100k expense → new 200k expense. Verify wallet balance delta = -100k | 🔴 |
| 2 | Test: change type | expense 100k → income 100k. Verify wallet balance delta = +200k (revert -100k + apply +100k) | 🔴 |
| 3 | Test: change wallet | Wallet A expense 100k → Wallet B expense 100k. Verify A balance +100k, B balance -100k | 🔴 |
| 4 | Test: change wallet + amount + type | Wallet A expense 100k → Wallet B income 200k. Verify A +100k, B +200k | 🔴 |
| 5 | Test: delete transaction | Delete expense 100k. Verify wallet balance +100k | 🔴 |
| 6 | Test: concurrent updates | 2 transactions tạo cùng lúc trên cùng wallet. Verify balance = sum of both | 🟡 |
| 7 | Write unit tests | Tạo test file `test/transaction/atomic_balance_test.dart` cover cases 1-5 (mock Firestore hoặc dùng emulator) | 🟡 |
