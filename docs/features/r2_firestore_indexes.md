# 📚 Feature: Firestore Indexes

## Type
Infrastructure / Performance

---

## Problem
- Thiếu composite indexes
- Query fail hoặc chậm

---

## Goal
Tất cả query hoạt động ổn định

---

## Solution

### Generate indexes
- Export firestore.indexes.json

---

### Common indexes
- wallet_id + date DESC
- account_id + created_at DESC

---

## Scope
- Cover tất cả query hiện tại

---

## Success metric
- Không còn lỗi index