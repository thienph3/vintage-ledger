# Tasks: Onboarding & First Experience

> User mở app → dùng ngay, không friction. Time to first transaction < 10s.

## Phụ thuộc
- Không phụ thuộc Data Layer V2 (có thể làm song song)

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | Auto-create default wallet | Khi mở app lần đầu (local mode), tự tạo 1 wallet "Ví chính" với balance 0 | 🔴 |
| 2 | Skip login → Home trực tiếp | Bỏ LoginScreen làm màn hình đầu, vào thẳng Home. Login chỉ xuất hiện khi user muốn sync/đổi device | 🔴 |
| 3 | Persist last account + wallet | Lưu `last_account_id` và `last_wallet_id` vào settings, auto-restore khi mở app | 🔴 |
| 4 | Auto-select wallet trong form | TransactionFormScreen tự chọn wallet gần nhất (last used) thay vì bắt user chọn | 🟡 |
| 5 | Delayed login prompt | Hiển thị prompt "Đăng nhập để đồng bộ" sau khi user đã tạo ≥ 3 transactions | 🟡 |
| 6 | Anonymous → linked account | Khi user quyết định login, link anonymous data vào account mới (dùng migrateLocalDataToAccount hiện có) | 🟡 |
| 7 | First-run tooltip | Tooltip nhẹ chỉ FAB "Thêm giao dịch đầu tiên" khi danh sách trống | 🟢 |
| 8 | Bỏ AccountPickerScreen cho single account | Nếu user chỉ có 1 account, skip AccountPicker → vào Home luôn | 🟢 |
| 9 | Xóa l10n keys onboarding thừa | Xóa welcomeTitle, welcomeSubtitle, startWithSample, startEmpty | 🟢 |
