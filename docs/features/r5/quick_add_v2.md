# Feature: Quick Add V2 (Smart Suggestions)

## Mục tiêu

Biến Quick Add thành core advantage của app.

## Hiện tại

- Parse text tốt
- Có keyword learning

## Thiếu

- Không tận dụng history

## Giải pháp

### Suggest recent entries

Hiển thị 3–5 entries gần nhất:

- "cafe 30k"
- "ăn trưa 50k"
- "grab 25k"

Tap → auto add

### Behavior

- Hiển thị khi focus vào Quick Add
- Sort theo frequency hoặc recent

## Data

quick_add_history/
  - text
  - count
  - last_used

## UI

[ Quick Add Input ]
[ Suggestions chips ]

## Expected Impact

- Giảm effort xuống 1 tap
- Tăng speed nhập liệu
- Tạo habit usage