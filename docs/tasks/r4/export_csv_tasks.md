# Tasks: Export CSV

> User có thể backup dữ liệu, không bị lock-in. Tăng trust.

## Phụ thuộc
- Không

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | ExportService | Method `exportTransactionsCsv()`: query tất cả transactions của account hiện tại, format CSV: `date,type,amount,category,wallet,note` | 🔴 |
| 2 | Resolve names | Map wallet_id → wallet name, category_id → category name trước khi export. Format date thành dd/MM/yyyy HH:mm | 🔴 |
| 3 | Generate CSV string | Header row + data rows. Handle commas trong note (wrap quotes). UTF-8 BOM cho Excel compatibility | 🔴 |
| 4 | Share file | Dùng `share_plus` package hoặc `path_provider` + `Share.shareXFiles`. Tạo temp file → share sheet | 🔴 |
| 5 | Export button trong Settings | ListTile "Xuất dữ liệu (CSV)" với icon download. Loading indicator khi đang export | 🟡 |
| 6 | L10n keys | Thêm: exportCsv, exporting, exportSuccess | 🟢 |
