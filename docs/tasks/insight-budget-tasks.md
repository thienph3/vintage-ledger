# Tasks: Insight & Budget

> Giúp user hiểu và kiểm soát tiền. Nền tảng cho Premium monetization.

## Phụ thuộc
- Không (dùng data layer hiện có hoặc V2)

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | Budget model | `budgets` table/collection: id, category_id, amount_limit, period (monthly), account_id, created_at | 🔴 |
| 2 | BudgetRepository + BudgetService | CRUD budget per category per month | 🔴 |
| 3 | BudgetFormScreen | Chọn category → nhập limit amount → save. Hiển thị danh sách budgets đã set | 🔴 |
| 4 | Budget tracking | Tính % used = tổng chi category trong tháng / budget limit | 🔴 |
| 5 | Budget progress UI | Progress bar cho mỗi category trong BudgetListScreen: xanh < 80%, vàng 80-100%, đỏ > 100% | 🔴 |
| 6 | Monthly insight screen | Tổng thu, tổng chi, balance, top 3 spending categories, so sánh với tháng trước | 🟡 |
| 7 | Budget widget trên Home | Card nhỏ hiển thị "Còn lại X đ cho Ăn uống" hoặc "Đã vượt budget Mua sắm" | 🟡 |
| 8 | Budget alert | Khi tạo transaction mà category gần/vượt budget → hiển thị warning trong form | 🟡 |
| 9 | Spending trend | So sánh chi tiêu tháng này vs tháng trước theo category (bar chart) | 🟡 |
| 10 | Budget sync | Sync budgets qua Firestore (nếu dùng Data Layer V2 thì tự có) | 🟢 |
| 11 | Premium gate | Wrap insight/budget screens sau paywall check (chuẩn bị cho monetization) | 🟢 |
| 12 | L10n keys | Thêm keys: budget, setBudget, budgetExceeded, remaining, monthlyInsight, vs lastMonth... | 🟢 |
