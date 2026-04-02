# Feature: Home V2 — Simplified Dashboard

## Mục tiêu

Giảm overload trên HomeScreen, đưa app về đúng mental model:
- Xem nhanh tình trạng tài chính
- Thêm giao dịch nhanh

## Vấn đề hiện tại

HomeScreen chứa quá nhiều component:
- Charts
- Budget summary
- Insight
- Streak
- Wallets
- Transactions
- Quick Add

→ Gây overload, đặc biệt với user mới

## Giải pháp

Tạo **Home V2 (Simplified Mode)** với layout tối giản:

### Components

1. Balance Card
2. Wallet Row
3. Recent Transactions (3–5 items)
4. Quick Add Bar (bottom)

### Loại bỏ khỏi Home

- Charts → chuyển sang tab riêng
- Budget → tab riêng
- Insight → tab riêng
- Streak → optional (ẩn hoặc nhỏ)

## Layout

[ Balance ]
[ Wallets (horizontal) ]
[ Recent Transactions ]
-------------------------
[ Quick Add Bar ]

## Navigation

- Tab bar:
  - Home
  - Transactions
  - Insights
  - Settings

## Expected Impact

- Giảm cognitive load
- Tăng conversion (user hiểu app nhanh hơn)
- Tăng retention early-stage

## Future

- Toggle Advanced Mode (nếu cần)