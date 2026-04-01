# Tasks: Firestore Read Optimization

> Giảm reads per user. Target < 1000 reads / user / day.

## Phụ thuộc
- Không

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | ReadCounter per screen | Extend ReadCounter để track reads per screen name. Hiển thị breakdown trong Settings debug section | 🔴 |
| 2 | Count stream reads | Hook ReadCounter vào watchAll/watchById snapshots (count docs per snapshot event) | 🔴 |
| 3 | Cache categories | Categories ít thay đổi — cache in-memory sau lần load đầu, invalidate khi user tạo/sửa/xóa category | 🟡 |
| 4 | Avoid duplicate wallet stream | HomeScreen có 2 StreamBuilder cho wallets (build + balanceCard). Merge thành 1 stream, pass data xuống | 🟡 |
| 5 | Measure baseline | Dùng ReadCounter đo reads cho flow: mở app → Home → tạo 1 transaction → xem wallet detail. Ghi kết quả | 🟢 |
