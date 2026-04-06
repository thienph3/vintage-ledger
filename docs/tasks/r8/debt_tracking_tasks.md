# Tasks: Debt Tracking

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | Debt model + DebtType | **NEW** `features/debt/models/debt.dart` | `DebtType { lend, borrow }`. Fields: id, type, partyName, partyUserId?, totalAmount, paidAmount, walletId?, note?, dueDate?, createdAt, settled |
| 2 | Payment model | **NEW** `features/debt/models/payment.dart` | Fields: id, amount, date, note?, transactionId?, createdAt |
| 3 | DebtRepository | **NEW** `features/debt/repositories/debt_repository.dart` | CRUD cho `debts/` subcollection under account |
| 4 | PaymentRepository | **NEW** `features/debt/repositories/payment_repository.dart` | CRUD cho `debts/{debtId}/payments/` subcollection |
| 5 | DebtService | **NEW** `features/debt/services/debt_service.dart` | Create debt (+ optional initial txn). Record payment (+ optional txn). Auto-settle khi paid ≥ total. Delete debt + all payments |
| 6 | Firestore rules | `firestore.rules` | Debts + payments subcollection rules: isMember, validate type/amount/name |
| 7 | Debt list screen | **NEW** `features/debt/screens/debt_list_screen.dart` | 2 sections: "Cho vay" + "Đang vay". Progress bars. SwipeListItem to delete. Add button |
| 8 | Debt form screen | **NEW** `features/debt/screens/debt_form_screen.dart` | Type toggle, party name (free text + member suggestions), amount, wallet?, due date?, note |
| 9 | Debt detail screen | **NEW** `features/debt/screens/debt_detail_screen.dart` | Progress, payment history, "Ghi nhận trả nợ" button |
| 10 | Payment form screen | **NEW** `features/debt/screens/payment_form_screen.dart` | Amount, note, toggle "Tạo giao dịch" + wallet picker |
| 11 | Debt progress bar widget | **NEW** `features/debt/widgets/debt_progress_bar.dart` | Reusable: paid/total bar + percentage |
| 12 | Debt summary card | **NEW** `features/debt/widgets/debt_summary_card.dart` | For home screen: "Người khác nợ bạn: X / Bạn đang nợ: Y" |
| 13 | Home screen integration | `home_screen.dart` | Thêm `DebtSummaryCard` section |
| 14 | Service locator + entry point | `service_locator.dart`, `setting_screen.dart` | Register DebtService. Add "Nợ" tile in settings manage section |
| 15 | L10n keys | `app_vi.dart`, `app_en.dart` | ~21 keys |
