# Tasks: Quick Add Transaction

> Input 1 dòng, parse tự động. Time to add < 2s.

## Phụ thuộc
- Onboarding UX (auto-select wallet)

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | QuickAddParser class | Regex-based parser: extract amount + keyword từ input string. Ví dụ: "ăn sáng 50k" → amount=50000, keyword="ăn sáng" | 🔴 |
| 2 | Amount parsing | Hỗ trợ format: "50k" → 50,000 · "10tr" → 10,000,000 · "50000" → 50,000 · "1.5tr" → 1,500,000 | 🔴 |
| 3 | Category keyword mapping | Map keywords → category: "ăn/cơm/phở" → Ăn uống, "cf/coffee" → Cà phê, "grab/taxi" → Di chuyển, "lương/salary" → Lương | 🔴 |
| 4 | QuickAddBar widget | TextField ở bottom Home (hoặc thay FAB), hiển thị preview realtime khi gõ | 🔴 |
| 5 | Realtime preview | Khi user gõ, hiển thị ngay: amount parsed, category matched, type (income/expense) | 🟡 |
| 6 | Default context | Auto-fill: wallet = last used, type = expense (mặc định), date = now, account = current | 🟡 |
| 7 | Submit flow | Enter/tap confirm → save transaction → clear input → show snackbar success | 🟡 |
| 8 | Fallback to full form | Nếu parse không đủ info (thiếu amount hoặc category), mở TransactionFormScreen với data đã parse pre-filled | 🟡 |
| 9 | Keyword learning | Lưu mapping user đã dùng (keyword → categoryId) vào settings để improve matching | 🟢 |
| 10 | Vi/En keyword sets | Keyword mapping theo locale hiện tại | 🟢 |
| 11 | Unit tests cho parser | Test cases: "ăn sáng 50k", "cf 30", "lương 10tr", "50000", edge cases | 🟢 |
