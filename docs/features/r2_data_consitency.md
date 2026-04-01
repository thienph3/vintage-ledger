# 🔒 Feature: Data Consistency (Atomic Balance)

## Type
System Reliability / Data Integrity

---

## Problem
- Tạo transaction và update wallet balance là 2 operations riêng biệt
- Nếu app crash giữa chừng → balance sai
- Mất niềm tin user (critical)

---

## Goal
Đảm bảo balance luôn đúng 100%

---

## Solution

### Option v1 (recommended)
- Sử dụng Firestore transaction:
  - create/update/delete transaction
  - update wallet balance
→ trong cùng 1 transaction

---

## Behavior

### Create transaction
- +amount (income)
- -amount (expense)

---

### Update transaction
- revert old amount
- apply new amount

---

### Delete transaction
- revert amount

---

## Scope
- Áp dụng cho tất cả write operations liên quan đến transaction

---

## Out of scope
- Cloud Function (v2)

---

## Success metric
- Không còn mismatch giữa balance và transaction