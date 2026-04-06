# Tasks: Transfer Transaction Type

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | TransactionType enum | `transaction_type.dart` | Thêm `transfer`, `transferOut`, `transferIn`. Helpers: `isTransfer`, `isTransferOut`, `isTransferIn`. `fromString` handle `transfer_out`/`transfer_in` (snake_case from Firestore) |
| 2 | TransactionModel fields | `transaction.dart`, `transaction_repository.dart` | Thêm `toWalletId`, `toAccountId`, `linkedTransactionId` (nullable). Serialize `to_wallet_id`, `to_account_id`, `linked_transaction_id` |
| 3 | Firestore rules | `firestore.rules` | Thêm `'transfer'`, `'transfer_out'`, `'transfer_in'` vào allowed types |
| 4 | WalletService.getWalletsForAccount | `wallet_service.dart` | Load wallets từ account bất kỳ (direct Firestore query, không qua repo scoped) |
| 5 | TransactionService.createTransfer | `transaction_service.dart` | Same-account: atomic 1 txn + 2 wallet updates. Cross-account: batch 2 txn docs + 2 wallet updates |
| 6 | TransactionService delete/update transfer | `transaction_service.dart` | `deleteTransaction`: handle transfer revert 2 wallets, transfer_out/in revert + delete linked. `updateTransaction`: block edit for transfers |
| 7 | TypeSelector 3 pills | `type_selector.dart` | Thêm pill `transfer`. Nhận `types` list param (default: income+expense+transfer) |
| 8 | TransactionFormScreen transfer mode | `transaction_form_screen.dart` | Khi transfer: ẩn category/recurring/budget, hiện source+dest wallet pickers (grouped by account), validate source ≠ dest |
| 9 | Exclude transfers từ thống kê | `transaction_list_screen.dart`, `home_screen.dart`, `transaction_service.dart` | Summary, today expense, dashboard: filter `!isTransfer` |
| 10 | Transfer story + feed | `transaction_story.dart`, `transaction_feed_item.dart` | Format + subtitle cho transfer/transfer_out/transfer_in |
| 11 | L10n keys | `app_vi.dart`, `app_en.dart` | 8 keys: transfer, fromWallet, toWallet, fromAccount, toAccount, sameWalletError, transferOut, transferIn |
