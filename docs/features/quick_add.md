# ⚡ Feature: Quick Add Transaction

## Problem
- Flow hiện tại quá nhiều bước (chọn ví, category, type...)
- User muốn ghi nhanh sau khi vừa tiêu tiền
- Friction cao → giảm usage

---

## Goal
Cho phép user thêm transaction trong < 2s

---

## Solution
Input 1 dòng, parse tự động:

Ví dụ:
- "ăn sáng 50k"
- "cf 30"
- "lương 10tr"

---

## Behavior

### 1. Input parsing
- Regex-based (không cần NLP)
- Detect:
  - amount
  - type (income/expense)
  - category (keyword mapping)

---

### 2. Default context
- Auto chọn:
  - wallet (last used)
  - account (current)
  - type (expense mặc định)

---

### 3. Preview realtime
Hiển thị ngay khi user gõ:
- Amount
- Category
- Type

---

### 4. Confirm flow
- Enter = save
- Optional: edit nhẹ trước khi save

---

## Scope v1
- Regex đơn giản (amount + keyword)
- Mapping category cơ bản
- Default wallet

---

## Out of scope
- NLP phức tạp
- multi-language parsing nâng cao

---

## Success metric
- Time to add < 2s
- % transaction dùng quick add > 60%