# Tasks: Offline Consistency Validation

> App hoạt động đúng khi offline → online. Không duplicate, không lệch balance.

## Phụ thuộc
- Transaction Edge Cases (atomic logic phải đúng trước)

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | Test: create offline → sync | Tắt mạng → tạo transaction → bật mạng. Verify: 1 transaction duy nhất, balance đúng | 🔴 |
| 2 | Test: delete offline → sync | Tắt mạng → xóa transaction → bật mạng. Verify: transaction bị xóa, balance revert đúng | 🔴 |
| 3 | Test: update conflict (2 devices) | Device A update amount → Device B update cùng transaction. Verify: last-write-wins, balance consistent, không crash | 🟡 |
| 4 | Test: create offline + delete offline | Tắt mạng → tạo → xóa cùng transaction → bật mạng. Verify: không có transaction, balance = 0 delta | 🟡 |
| 5 | Document test results | Ghi kết quả test vào `docs/tests/offline_consistency_results.md` | 🟢 |
