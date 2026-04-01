# 📚 Feature: Budget Composite Index Fix

## Type
Infrastructure / Stability

---

## Problem
- Query budget:
  where(category_id) + where(type) + where(date >=)

- Thiếu composite index → query fail

---

## Goal
Tất cả budget queries chạy ổn định

---

## Solution

### Add index:

Collection: transactions

Fields:
- category_id ASC
- type ASC
- date DESC

---

## Implementation

- Update firestore.indexes.json
- Deploy index

---

## Scope
- BudgetService:
  - checkBudget()
  - getBudgetStatuses()

---

## Success metric
- Không còn lỗi Firestore index