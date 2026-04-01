# Tasks: Multi-Currency Support

> Mỗi wallet có currency riêng, hiển thị theo locale. Sẵn sàng mở global.

## Phụ thuộc
- Không (có thể làm độc lập)

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | Currency enum/constants | Định nghĩa danh sách currencies hỗ trợ: VND, USD, EUR, JPY, KRW... với symbol, decimal places, locale format | 🔴 |
| 2 | Thêm currency vào Wallet model | Field `currency` (String, default 'VND'), cập nhật toMap/fromMap/copyWith | 🔴 |
| 3 | Thêm currency vào DB schema | ALTER TABLE wallets ADD currency TEXT DEFAULT 'VND' (hoặc bump DB version) | 🔴 |
| 4 | Currency picker trong WalletFormScreen | Dropdown chọn currency khi tạo/sửa wallet | 🔴 |
| 5 | Refactor AmountFormatter | Format theo currency: VND → "50.000đ", USD → "$50.00", EUR → "€50,00" | 🔴 |
| 6 | Refactor AmountText | Nhận currency param, truyền xuống AmountFormatter | 🟡 |
| 7 | Update HomeScreen balance | Nếu tất cả wallets cùng currency → hiển thị bình thường. Nếu khác currency → hiển thị từng wallet riêng hoặc "Mixed currencies" | 🟡 |
| 8 | Update Firestore schema | Thêm currency vào wallet docs trên Firestore | 🟡 |
| 9 | AmountInputField theo currency | Cho phép decimal input cho USD/EUR (2 decimal places), không decimal cho VND/JPY | 🟡 |
| 10 | Default currency setting | Setting chọn default currency cho wallets mới, lưu vào settings table | 🟢 |
| 11 | Currency conversion (v2) | Quy đổi về base currency để tính tổng balance, dùng static rate hoặc API | 🟢 |
| 12 | L10n keys | Thêm keys: currency, selectCurrency, mixedCurrencies, baseCurrency... | 🟢 |
