# 🧠 Feature: Quick Add Learning Persistence

## Type
UX Improvement

---

## Problem
- Keyword learning hiện chỉ in-memory
- Restart app → mất dữ liệu

---

## Goal
Quick Add ngày càng chính xác theo user

---

## Solution

### Storage
- Lưu mapping vào:
  users/{userId}/settings

---

### Behavior
- Ưu tiên learned keywords hơn built-in map

---

## Example

"bún bò" → Ăn uống  
→ lần sau auto map

---

## Scope
- Persist + load khi app start

---

## Success metric
- Tăng accuracy của Quick Add