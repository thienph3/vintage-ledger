# Tasks: Onboarding & First Experience

> User mở app → dùng ngay, không friction. Time to first transaction < 10s.

## Phụ thuộc
- Data Layer V2 ✅ (anonymous auth)

## Tasks

| # | Task | Mô tả | Status |
|---|------|--------|--------|
| 1 | Auto-create default wallet | Khi anonymous sign-in lần đầu, tự tạo wallet "Ví chính" (balance 0, VND) | ✅ |
| 2 | Skip login → Home trực tiếp | Anonymous auth → Home. LoginScreen chỉ khi Firebase user == null (edge case) | ✅ (Data Layer V2) |
| 3 | Persist last account + wallet | `SettingService.getLastAccountId/setLastAccountId` + `getLastWalletId/setLastWalletId`. Restore on startup, persist on select | ✅ |
| 4 | Auto-select wallet trong form | TransactionFormScreen: load `lastWalletId` → auto-select nếu match. Persist wallet ID sau khi save | ✅ |
| 5 | Delayed login prompt | `LoginPromptCard` trên HomeScreen: hiển thị "Đăng ký để đồng bộ" khi anonymous + ≥3 transactions | ✅ |
| 6 | Anonymous → linked account | `AuthService.linkWithEmail()` trong RegisterScreen — link anonymous data vào email account | ✅ (Data Layer V2) |
| 7 | First-run hint | Khi chưa có wallet: hiển thị hint text "Tạo ví đầu tiên để bắt đầu ghi chép ↑" thay QuickAddBar | ✅ |
| 8 | Bỏ AccountPickerScreen cho single account | Nếu `lastAccountId` đã set → skip AccountPicker → vào Home luôn | ✅ |
| 9 | Xóa l10n keys onboarding thừa | Đã xóa welcomeTitle, welcomeSubtitle, startWithSample, startEmpty | ✅ (Data Layer V2) |
