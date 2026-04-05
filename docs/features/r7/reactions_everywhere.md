# Feature: Reactions Everywhere

## Vấn đề
Reactions chỉ có trong HomeScreen feed. TransactionListScreen timeline và WalletDetailScreen không có.

## Giải pháp
Thêm ReactionBar + long-press picker vào mọi nơi hiển thị transaction:
- TransactionListScreen (expanded day items)
- WalletDetailScreen (feed items)
- Giữ HomeScreen (đã có)

## Implementation
Tạo `TransactionFeedItem` widget chung — story + time + reactions — dùng ở cả 3 screens.
