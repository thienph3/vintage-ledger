# ⚡ Feature: Query Optimization

## Type
Performance / Cost

---

## Problem
- Reuse getDashboard() cho nhiều logic
- Đọc quá nhiều data

---

## Goal
Giảm read operations và improve performance

---

## Solution

### Separate queries
- Monthly transactions
- Budget calculation
- Recent transactions

---

### Avoid
- Load toàn bộ transactions

---

## Scope
- Refactor services liên quan

---

## Success metric
- Giảm Firestore reads
- Load nhanh hơn