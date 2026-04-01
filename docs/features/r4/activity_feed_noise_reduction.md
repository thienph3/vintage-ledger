# 📜 Feature: Activity Feed Noise Reduction

## Type
UX Improvement

---

## Problem

Activity feed hiện tại:
- log nhiều event
- dễ bị spam khi nhiều transaction

---

## Goal

- Feed dễ đọc
- không spam

---

## Solution

### 1. Group transactions

Nếu:
- cùng user
- cùng ngày

→ group: `A đã thêm 3 giao dịch hôm nay`


---

### 2. Priority events

Hiển thị rõ hơn:

- join family
- leave family

---

### 3. Limit feed

- chỉ load:
  - 20–30 items gần nhất

---

## Scope
- Activity UI
- ActivityService

---

## Success metric

- Feed dễ đọc hơn
