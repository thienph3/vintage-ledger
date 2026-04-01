# 🔄 Feature: Transaction Edge Case Handling

## Type
Data Integrity

---

## Problem
- Các case update phức tạp có thể làm lệch balance

---

## Goal
Balance luôn đúng trong mọi case

---

## Cases

### 1. Change amount

- old: 100k → new: 200k

Expected:
- revert 100k
- apply 200k

---

### 2. Change type

- expense → income

Expected:
- revert expense
- apply income

---

### 3. Change wallet

- wallet A → wallet B

Expected:
- revert A
- apply B

---

### 4. Delete transaction

Expected:
- revert đúng amount

---

## Implementation

- Tất cả logic nằm trong:
  firestore.runTransaction()

---

## Success metric
- Balance luôn đúng sau mọi thao tác