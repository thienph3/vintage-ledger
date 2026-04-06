# Tasks: Funding Source

**Depends on:** [Transfer Transaction](transfer_transaction_tasks.md) (tasks 1–6 must be done first)

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | TransactionModel funding fields | `transaction.dart`, `transaction_repository.dart` | Thêm `fundingWalletId`, `fundingAccountId`, `fundingTransferId` (nullable). Serialize/deserialize |
| 2 | TransactionService.createWithFunding | `transaction_service.dart` | Batch: cross-account transfer (personal → family) + expense in family. Link via `fundingTransferId` |
| 3 | Delete with funding revert | `transaction_service.dart` | Khi delete expense có `fundingTransferId`: revert expense + delete/revert linked transfer |
| 4 | Funding source selector UI | `transaction_form_screen.dart` | Khi family + expense: hiện InlineSelector dưới wallet dropdown. Load personal wallets. Inline info khi chọn personal |
| 5 | Feed subtitle for funded txn | `transaction_feed_item.dart` | Hiện "💳 từ Ví chính (cá nhân)" khi txn có `fundingWalletId` |
| 6 | L10n keys | `app_vi.dart`, `app_en.dart` | `fundingSource`, `fundingDefault`, `fundingPersonal`, `fundingAutoTransfer` |
