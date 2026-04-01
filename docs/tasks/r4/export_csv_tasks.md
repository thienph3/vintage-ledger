# Tasks: Export CSV — ✅
| # | Task | Status |
|---|------|--------|
| 1 | ExportService | ✅ `exportTransactionsCsv()`: query all transactions, format CSV |
| 2 | Resolve names | ✅ Map wallet_id → name, category_id → name, format date dd/MM/yyyy HH:mm |
| 3 | Generate CSV string | ✅ Header + data rows, comma escaping (wrap quotes), UTF-8 BOM |
| 4 | Share file | ✅ `share_plus` + `path_provider`: temp file → share sheet |
| 5 | Export button trong Settings | ✅ ListTile "Xuất dữ liệu (CSV)" + loading indicator |
| 6 | L10n keys | ✅ +2 keys: exportCsv, exportSuccess |
