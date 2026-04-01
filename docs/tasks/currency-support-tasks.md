# Tasks: Multi-Currency Support

> Mỗi wallet có currency riêng, hiển thị theo locale. Sẵn sàng mở global.

## Phụ thuộc
- Không (có thể làm độc lập)

## Tasks

| # | Task | Mô tả | Status |
|---|------|--------|--------|
| 1 | Currency enum/constants | `Currency` class với 8 currencies (VND, USD, EUR, GBP, JPY, KRW, CNY, THB), symbol, decimal places, symbolBefore | ✅ |
| 2 | Thêm currency vào Wallet model | Field `currency` (String, default 'VND'), cập nhật copyWith/==/hashCode | ✅ |
| 3 | Thêm currency vào Firestore schema | WalletRepository read/write `currency` field | ✅ |
| 4 | Currency picker trong WalletFormScreen | Dropdown chọn currency khi tạo/sửa wallet | ✅ |
| 5 | Refactor AmountFormatter | Format theo currency: VND → "50.000đ", USD → "$50.00", EUR → "€50,00". Hỗ trợ decimal currencies | ✅ |
| 6 | Refactor AmountText | Nhận `currency` param (default 'VND'), truyền xuống AmountFormatter | ✅ |
| 7 | Update HomeScreen balance | Detect mixed currencies → hiển thị "Nhiều loại tiền". Single currency → hiển thị bình thường. Wallet cards hiển thị đúng currency | ✅ |
| 8 | Update Firestore schema | Đã gộp vào task #3 | ✅ |
| 9 | AmountInputField theo currency | Nhận `currency` param, format preview theo currency | ✅ |
| 10 | Default currency setting | SettingService get/setDefaultCurrency, SettingScreen có currency picker section | ✅ |
| 11 | Currency conversion (v2) | Quy đổi về base currency để tính tổng balance, dùng static rate hoặc API | ⏳ |
| 12 | L10n keys | Thêm keys: currency, selectCurrency, mixedCurrencies | ✅ |
