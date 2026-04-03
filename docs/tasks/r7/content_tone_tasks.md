# Tasks: Content & Tone Rewrite

Chuyển toàn bộ user-facing text từ formal/financial sang casual/conversational.

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | Rewrite l10n keys — Home | `app_vi.dart`, `app_en.dart` | `totalBalance` → "Tụi mình có". `monthIncome` → "Thu tháng này". `monthExpense` → "Chi tháng này". Bỏ UPPERCASE titles |
| 2 | Rewrite l10n keys — Transactions | `app_vi.dart`, `app_en.dart` | `transactionLedger` → "Thu chi". `addNewTransaction` → "Ghi thu chi". `editTransaction` → "Sửa". `noTransactions` → "Chưa có gì hôm nay" |
| 3 | Rewrite l10n keys — Wallets | `app_vi.dart`, `app_en.dart` | `myWallets` → "Ví". `addWallet` → "Thêm ví". `deleteWalletConfirm` → "Xóa ví này luôn hả?" |
| 4 | Rewrite l10n keys — Settings | `app_vi.dart`, `app_en.dart` | `settings` → "Cài đặt". Bỏ UPPERCASE. Casual tone |
| 5 | Rewrite l10n keys — Budget | `app_vi.dart`, `app_en.dart` | `budgetExceeded` → "Vượt ngân sách rồi 😅". `budgetNearLimit` → "Sắp hết ngân sách" |
| 6 | Rewrite l10n keys — Insights | `app_vi.dart`, `app_en.dart` | `topSpendingInsight` → "Tụi mình chi nhiều nhất vào {category}". `savedThisMonth` → "Tháng này tiết kiệm được" |
| 7 | Rewrite l10n keys — Coaching | `app_vi.dart`, `app_en.dart` | Casual tone: "Thử ghi 'cafe 30k' xem 👇". "Đặt ngân sách cho {category} không?" |
| 8 | Rewrite l10n keys — Family | `app_vi.dart`, `app_en.dart` | `inviteMember` → "Mời người thân". `leaveFamily` → "Rời nhóm". Casual |
| 9 | Rewrite empty states | `app_vi.dart`, `app_en.dart` | Friendly, encouraging: "Chưa có gì — thử ghi 1 khoản xem 👇" |
| 10 | Rewrite error messages | `app_vi.dart`, `app_en.dart` | Softer: "Hmm, có gì đó sai rồi" thay vì "Có lỗi xảy ra". "Thử lại nhé" thay vì "Thử lại" |
| 11 | Bỏ UPPERCASE convention | Tất cả l10n values | Screen titles không còn UPPERCASE. Dùng sentence case |
| 12 | Cập nhật screens dùng title | Tất cả screens dùng `S.of(context, ...)` | Verify titles hiển thị đúng sau bỏ UPPERCASE |
