# 📡 Feature: Offline Consistency Validation

## Type
System Reliability

---

## Problem
- Firestore offline cache hoạt động tự động
- Nhưng cần đảm bảo:
  - không duplicate
  - không lệch balance

---

## Goal
App hoạt động đúng khi:
- offline → online

---

## Test Scenarios

### 1. Create offline → sync

- Offline:
  - tạo transaction

- Online:
  - sync

Expected:
- 1 transaction duy nhất
- balance đúng

---

### 2. Update conflict (2 devices)

- Device A:
  - update transaction

- Device B:
  - update cùng transaction

Expected:
- last-write-wins
- không crash
- balance consistent

---

### 3. Delete offline → sync

- Offline:
  - delete transaction

- Online:
  - sync

Expected:
- transaction bị xóa
- balance revert đúng

---

## Scope
- TransactionService
- Wallet balance

---

## Success metric
- Không có inconsistency trong test