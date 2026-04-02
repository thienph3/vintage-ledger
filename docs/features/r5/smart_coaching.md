# Feature: Smart Coaching (Contextual Guidance)

## Mục tiêu

Biến app từ tool → financial coach.

## Vấn đề

Empty states hiện tại:
- Generic
- Không hướng dẫn rõ user nên làm gì tiếp

## Giải pháp

Dynamic hints theo lifecycle user.

## Cases

### Case 1 — No transactions

"Thử nhập 'ăn sáng 30k' 👇"

### Case 2 — Có transaction nhưng chưa có budget

"Bạn có muốn đặt ngân sách cho Ăn uống không?"

### Case 3 — Sau vài ngày sử dụng

"Bạn đang chi nhiều nhất vào Cà phê ☕"

### Case 4 — Sau 7 ngày

"Tuần này bạn chi nhiều hơn 20% so với tuần trước"

## Implementation

- Rule-based (không cần AI)
- Dựa vào:
  - số transaction
  - thời gian sử dụng
  - category usage

## UI

- Inline text trong Home
- Card nhỏ (dismissible)

## Expected Impact

- Giảm confusion
- Tăng engagement
- Giúp user hiểu value nhanh hơn