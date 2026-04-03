# Tasks: Home Screen V3 — Minimal Shared Feed

Theo style guide section 10: Home chỉ có Today Total + Shared Feed + Quick Add.

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | Today Total card | `home_screen.dart` | Thay BalanceCard phức tạp (income/expense/visibility toggle) bằng card đơn giản: "Hôm nay tụi mình tiêu {amount}" hoặc "Hôm nay chưa tiêu gì". Soft, 1 dòng, casual tone |
| 2 | Shared Feed | `home_screen.dart` | Thay TransactionSection bằng feed dạng timeline: mỗi item = story ("Minh cafe 30k ☕"). Giống chat feed, mới nhất ở dưới. Scroll up xem cũ hơn |
| 3 | Bỏ WalletRow khỏi Home | `home_screen.dart` | Wallets chuyển sang tab riêng hoặc Settings. Home chỉ focus today |
| 4 | Bỏ InsightCard khỏi Home | `home_screen.dart` | Insights ở tab Insights. Home minimal |
| 5 | Bỏ CoachingCard khỏi Home | `home_screen.dart` | Coaching chuyển sang Insights tab hoặc onboarding flow riêng |
| 6 | Quick Add ở bottom | `home_screen.dart` | Giữ QuickAddBar (chat-like style từ task quick_add_chat) |
| 7 | Feed empty state | `home_screen.dart` | "Chưa có gì hôm nay — ghi 1 khoản đi 👇". Friendly, encouraging |
| 8 | Today query | `TransactionService` hoặc `home_screen.dart` | Query transactions where date = today only (không cần full dashboard) |
