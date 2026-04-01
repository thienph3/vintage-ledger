# Tasks: Smart Empty States

> Hướng dẫn user khi chưa có data. Tăng activation.

## Phụ thuộc
- Không

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | Transaction empty state | Khi TransactionSection trống: thay "Không có thu chi nào" bằng "Chưa có giao dịch — thử nhập 'ăn trưa 50k' 👇" (chỉ QuickAddBar) | 🔴 |
| 2 | Budget empty state | Khi BudgetSummaryCard không có budgets: thay "✓ Chưa đặt ngân sách" bằng "Đặt ngân sách để kiểm soát chi tiêu →" (link đến BudgetListScreen) | 🔴 |
| 3 | Chart empty state | Khi ChartSection không có data: hiển thị illustration nhẹ + "Thêm giao dịch để xem biểu đồ" | 🟡 |
| 4 | L10n keys | Thêm: emptyTransactionHint, emptyBudgetHint, emptyChartHint | 🟢 |
