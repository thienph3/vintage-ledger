# 📉 Feature: Stream Read Optimization

## Type
Performance / Cost

---

## Problem

Firestore streams:
- mỗi update = 1 read
- nhiều streams → tăng cost nhanh (Spark plan)

---

## Goal

- Giảm reads
- vẫn giữ UX realtime cho phần quan trọng

---

## Strategy

### 1. Keep streams

- wallets (balance thay đổi liên tục)
- recent transactions (limit 10–20)

---

### 2. Replace streams with get()

- charts
- monthly insight
- budget summary

---

### 3. Limit query size

- transactions:
  - limit (e.g. 50)
  - paginate khi scroll

---

### 4. Avoid duplicate listeners

- merge streams khi có thể (đã làm ở HomeScreen)

---

## Scope
- HomeScreen
- TransactionListScreen
- BudgetService

---

## Success metric

- Giảm reads/session
- < 1000 reads/user/day