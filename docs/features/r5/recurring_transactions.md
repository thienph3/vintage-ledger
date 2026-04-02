# Feature: Recurring Transactions

## Mục tiêu

Giảm effort nhập liệu cho các khoản lặp lại.

## Use cases

- Tiền nhà
- Lương
- Subscription (Netflix, Spotify)
- Tiền điện nước

## Feature

### Create recurring rule

Fields:
- amount
- category
- wallet
- frequency:
  - daily
  - weekly
  - monthly
- start date

### Auto create transaction

- Chạy khi app mở
- Hoặc background check

## Data model

recurring_rules/
  - id
  - amount
  - category_id
  - wallet_id
  - frequency
  - next_run_at

## Logic

if (now >= next_run_at):
  create transaction
  update next_run_at

## UI

- Toggle "Lặp lại" trong TransactionForm
- List trong Settings hoặc riêng tab

## Edge cases

- Offline → tạo khi online lại
- Duplicate prevention

## Expected Impact

- Giảm friction
- Tăng retention
- Tăng perceived intelligence của app