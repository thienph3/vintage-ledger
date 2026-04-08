# Implementation Plan: Split Transaction Forms

## Overview

Tách TransactionFormScreen monolithic thành 3 form chuyên biệt, cập nhật navigation, và dọn dẹp code cũ. Thực hiện theo thứ tự: shared utilities → form screens → navigation updates → cleanup.

## Tasks

- [x] 1. Extract shared AccountWallets model
  - [x] 1.1 Create `lib/features/wallet/models/account_wallets.dart` with `AccountWallets` class extracted from `_AccountWallets` in TransactionFormScreen
    - Fields: `accountId`, `accountName`, `wallets` (List<Wallet>)
    - _Requirements: 2.1, 3.1_

- [x] 2. Implement IncomeExpenseFormScreen
  - [x] 2.1 Create `lib/features/transaction/screens/income_expense_form_screen.dart`
    - Extract income/expense logic from TransactionFormScreen
    - Props: `walletId`, `existing` (TransactionWithItems?), `prefill` (TransactionWithItems?)
    - State: `_type` (income/expense only), `_walletId`, `_categoryId`, `_categories`, `_items`, `_date`, `_note`, `_recurring`, `_frequency`, `_budgetStatus`, `_members`, `_createdBy`
    - Methods: `_loadCategories()`, `_loadWallets()`, `_loadMembers()`, `_checkBudget()`, `_onAddCategory()`, `_addItem()`, `_removeItem()`, `_pickDateTime()`, `_save()`
    - Build: TypeSelector (income/expense only), AmountInputField, wallet dropdown, CategoryDropdown, budget status warning, date picker, TransactionItemList, note field, member dropdown (edit), recurring toggle (new), save button, delete button (edit)
    - Validation: wallet required, category required, line items total ≤ amount, auto-fill amount from items
    - Save: createTransaction/updateTransaction, create RecurringRule if recurring, AmountHistory.record, Navigator.pop(true)
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8_
  - [ ]* 2.2 Write property test: Category filtering by transaction type
    - **Property 1: Category filtering by transaction type**
    - **Validates: Requirements 1.2**
  - [ ]* 2.3 Write property test: Line items total validation
    - **Property 3: Line items total validation**
    - **Validates: Requirements 1.7**
  - [ ]* 2.4 Write property test: Auto-fill amount from line items
    - **Property 4: Auto-fill amount from line items**
    - **Validates: Requirements 1.8**

- [-] 3. Implement TransferFormScreen
  - [x] 3.1 Create `lib/features/transfer/screens/transfer_form_screen.dart`
    - Extract transfer logic from TransactionFormScreen
    - Props: `existing` (TransactionWithItems?)
    - State: `_walletId`, `_toWalletId`, `_toAccountId`, `_wallets`, `_allAccountWallets`, `_date`, `_note`, `_members`, `_createdBy`
    - Methods: `_loadWallets()`, `_loadAllAccountWallets()`, `_loadMembers()`, `_pickDateTime()`, `_save()`
    - Build: AmountInputField, source wallet dropdown, destination wallet dropdown (cross-account), date picker, note field, member dropdown (edit), save button, delete button (edit)
    - Validation: source ≠ destination
    - Save: createTransfer/updateTransfer, Navigator.pop(true)
    - Use shared `AccountWallets` model from task 1
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_
  - [ ]* 3.2 Write property test: Source wallet exclusion from destination list
    - **Property 5: Source wallet exclusion from destination list**
    - **Validates: Requirements 2.2**

- [x] 4. Implement FundingFormScreen
  - [x] 4.1 Create `lib/features/transfer/screens/funding_form_screen.dart`
    - Props: none (create-only, no edit mode)
    - State: `_sourceWalletId`, `_destWalletId`, `_familyAccountId`, `_personalWallets`, `_familyWallets`, `_date`, `_note`
    - Methods: `_loadWallets()`, `_pickDateTime()`, `_save()`
    - Build: AmountInputField, source wallet dropdown (personal), destination wallet dropdown (family only), date picker, note field, save button
    - Save: createTransfer with destAccountId = family account ID, Navigator.pop(true)
    - _Requirements: 3.1, 3.2, 3.3, 3.4_
  - [ ]* 4.2 Write property test: Funding destination wallet filtering
    - **Property 7: Funding destination wallet filtering**
    - **Validates: Requirements 3.2**

- [ ] 5. Checkpoint - Ensure all form screens compile and render
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Update navigation to use new form screens
  - [x] 6.1 Update QuickActionsFab to navigate to FundingFormScreen and TransferFormScreen
    - `QuickActionType.funding` → `FundingFormScreen()`
    - `QuickActionType.transfer` → `TransferFormScreen()`
    - Remove import of old `TransferScreen`
    - _Requirements: 4.1, 4.2_
  - [x] 6.2 Update QuickAddBar to navigate to IncomeExpenseFormScreen
    - Change `_openFullForm()` to push `IncomeExpenseFormScreen` instead of `TransactionFormScreen`
    - Update prefill logic to use new screen
    - Remove import of old `TransactionFormScreen`
    - _Requirements: 5.1_
  - [x] 6.3 Update TransactionFeedItem to route to correct form based on transaction type
    - Check `txn.transaction.type.isTransfer`: true → `TransferFormScreen(existing: txn)`, false → `IncomeExpenseFormScreen(walletId:, existing: txn)`
    - Remove import of old `TransactionFormScreen`
    - _Requirements: 5.2, 5.3_
  - [ ]* 6.4 Write property test: Edit navigation routing by transaction type
    - **Property 8: Edit navigation routing by transaction type**
    - **Validates: Requirements 5.2, 5.3**

- [x] 7. Remove old screens and clean up imports
  - [x] 7.1 Delete `lib/features/transaction/screens/transaction_form_screen.dart`
    - _Requirements: 6.2_
  - [x] 7.2 Delete `lib/features/transfer/screens/transfer_screen.dart`
    - _Requirements: 6.1_
  - [x] 7.3 Search and fix any remaining import references to deleted files
    - Grep for `transaction_form_screen.dart` and `transfer_screen.dart` across codebase
    - Fix or remove any remaining references
    - _Requirements: 6.3_

- [ ] 8. Final checkpoint - Ensure all tests pass and no broken imports
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties
- The existing TransactionFormScreen and TransferScreen remain functional until task 7 (cleanup)
