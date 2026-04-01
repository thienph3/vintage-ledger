# Tasks: Currency Approximation

> Hiển thị tổng balance ước tính khi có mixed currencies.

## Phụ thuộc
- Không

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | Static exchange rates | Thêm `exchangeRates` map vào Currency class: `{'USD': 25000, 'EUR': 27000, 'GBP': 32000, 'JPY': 170, 'KRW': 19, 'CNY': 3500, 'THB': 700}` (VND base) | 🔴 |
| 2 | Convert to default currency | Method `Currency.convert(int amount, String from, String to)` dùng static rates. Return 0 nếu không có rate | 🔴 |
| 3 | Approximate total balance | Trong HomeScreen `_buildBalanceCard`: khi mixed currencies, tính tổng bằng cách convert tất cả wallets về default currency. Hiển thị "≈ 1.250.000đ" | 🔴 |
| 4 | Label "ước tính" | Prefix "≈" trước số tiền khi là approximate. Thêm tooltip/caption "Ước tính theo tỷ giá tham khảo" | 🟡 |
| 5 | L10n keys | Thêm: approximate, approximateTooltip | 🟢 |
