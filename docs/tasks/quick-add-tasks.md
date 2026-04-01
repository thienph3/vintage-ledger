# Tasks: Quick Add Transaction

> Input 1 dòng, parse tự động. Time to add < 2s.

## Phụ thuộc
- Onboarding UX (auto-select wallet)

## Tasks

| # | Task | Mô tả | Status |
|---|------|--------|--------|
| 1 | QuickAddParser class | Regex-based parser: extract amount + keyword từ input string | ✅ |
| 2 | Amount parsing | "50k" → 50,000 · "10tr" → 10,000,000 · "1.5tr" → 1,500,000 · "2 tỷ" → 2,000,000,000 · "50000" → 50,000 | ✅ |
| 3 | Category keyword mapping | 30+ keywords → category: ăn/cơm/phở → Ăn uống, cf/coffee → Cà phê, grab/taxi → Di chuyển, lương/salary → Lương... | ✅ |
| 4 | QuickAddBar widget | Bottom bar trên HomeScreen thay FAB, TextField + submit button | ✅ |
| 5 | Realtime preview | Khi gõ hiển thị: amount parsed (có màu thu/chi), category matched (chip), "?" nếu chưa match | ✅ |
| 6 | Default context | Auto-fill: wallet = first wallet, type = expense (mặc định, income nếu keyword match), date = now | ✅ |
| 7 | Submit flow | Enter/tap ✓ → save → clear input → snackbar "Đã thêm thu chi" → reload dashboard | ✅ |
| 8 | Fallback to full form | Nếu thiếu category → mở TransactionFormScreen với amount + note pre-filled. Tap + khi input trống → mở form trống | ✅ |
| 9 | Keyword learning | `QuickAddParser.learn(keyword, categoryId)` — learned map checked trước built-in map | ✅ |
| 10 | Vi/En keyword sets | Built-in map có cả vi (ăn, cơm, phở, cf, grab, xăng, lương, thưởng) và en (food, eat, coffee, taxi, salary, bonus) | ✅ |
| 11 | Unit tests cho parser | 15 test cases: amount parsing (7), category matching (6), isComplete (3), keyword learning (1) | ✅ |
