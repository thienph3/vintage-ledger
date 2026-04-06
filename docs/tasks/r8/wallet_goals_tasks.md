# Tasks: Wallet Types & Savings Goals

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | WalletType enum + Wallet model | `wallet.dart`, `wallet_repository.dart` | Thêm `WalletType { spending, savings }` + `type` field. Default `spending`. Serialize/deserialize |
| 2 | WalletGoal model | **NEW** `features/wallet/models/wallet_goal.dart` | `id`, `name`, `targetAmount`, `deadline?`, `emoji?`, `savedAmount`, `createdAt` |
| 3 | GoalRepository | **NEW** `features/wallet/repositories/goal_repository.dart` | CRUD cho `wallets/{walletId}/goals/` subcollection. Không extend `FirestoreRepository` (khác path) |
| 4 | GoalService | **NEW** `features/wallet/services/goal_service.dart` | Create/update/delete goal. Validate `sum(savedAmount) ≤ wallet.balance` |
| 5 | Firestore rules | `firestore.rules` | Goals subcollection: read/write if `isMember(accountId)`, validate name + target_amount |
| 6 | Wallet form — type picker | `wallet_form_screen.dart` | TypeSelector-like toggle: `[ 💳 Chi tiêu ] [ 🏦 Tiết kiệm ]` |
| 7 | Wallet detail — goals section | `wallet_detail_screen.dart` | Khi savings: hiện goals list + progress bars + "Chưa phân bổ" + "Thêm mục tiêu" button |
| 8 | Goal form screen | **NEW** `features/wallet/screens/goal_form_screen.dart` | Form: name, emoji picker, targetAmount, deadline (optional), savedAmount |
| 9 | Goal progress bar widget | **NEW** `features/wallet/widgets/goal_progress_bar.dart` | Reusable: `savedAmount / targetAmount` bar + percentage + days left |
| 10 | Wallet list — mini progress | `wallet_list_screen.dart` | Savings wallets hiện mini progress bars cho goals bên dưới tên |
| 11 | L10n keys | `app_vi.dart`, `app_en.dart` | ~17 keys: walletType*, goals, addGoal, editGoal, deleteGoal*, targetAmount, savedAmount, deadline, daysLeft, overdue, unallocated, goalReached, goalName* |
