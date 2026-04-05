# Feature: Wallet Detail Redesign

## Vấn đề
WalletDetailScreen vẫn "fintech" style:
- ChartSection (heavy dashboard)
- TransactionSection (old table layout)
- Không có story format
- Không có reactions

## Giải pháp
Chuyển sang feed-style giống HomeScreen:
- Balance card (soft, casual)
- Transaction feed (story format + avatar + reactions)
- Bỏ ChartSection (xem chart ở Insights tab)
- QuickAddBar giữ nguyên (fixed walletId)

## Layout mới
```
[ Ví chính — 500k ]        ← soft balance card
[ Bạn cafe 30k ☕  08:30 ]  ← story feed
[ Bạn ăn trưa 50k 🍜 12:15 ]
[ ───────────────────── ]
[ QuickAddBar ]
```
