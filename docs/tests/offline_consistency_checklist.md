# Offline Consistency Test Checklist

> Manual test trên device thật. Ghi kết quả vào cột Result.

## Setup
- Cài app trên device
- Tạo wallet "Test" với balance 0
- Tạo 1 category "Test Cat"

## Test Cases

| # | Scenario | Steps | Expected | Result |
|---|----------|-------|----------|--------|
| 1 | Create offline → sync | Bật airplane mode → tạo expense 100k → tắt airplane mode → đợi 5s | 1 transaction, balance = -100k | |
| 2 | Delete offline → sync | Bật airplane mode → xóa transaction vừa tạo → tắt airplane mode | 0 transactions, balance = 0 | |
| 3 | Create + delete offline | Bật airplane mode → tạo expense 50k → xóa ngay → tắt airplane mode | 0 transactions, balance = 0 | |
| 4 | Update conflict | Device A: sửa amount 100k → 200k. Device B: sửa cùng txn 100k → 300k (cùng lúc) | Last write wins, balance consistent | |

## Notes
- Firestore offline persistence tự handle queued writes
- `runTransaction` sẽ retry nếu conflict detected khi online
- Balance luôn atomic vì nằm trong cùng 1 `runTransaction`
