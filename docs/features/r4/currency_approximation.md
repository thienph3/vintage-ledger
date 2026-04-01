# 💱 Feature: Currency Approximation

## Type
UX Improvement

---

## Problem

- Multi-currency wallets
- Không có tổng balance → hiển thị "Nhiều loại tiền"

→ user không biết tổng tài sản

---

## Goal

Hiển thị tổng balance ước tính

---

## Solution

### 1. Static exchange rates

Hardcode rates (update manual):

- USD → VND
- EUR → VND
- ...

---

### 2. Convert tất cả về default currency

- defaultCurrency từ settings

---

### 3. UI

Hiển thị: `≈ 1,250,000đ`
hoặc: `≈ $52.3`


---

### 4. Label rõ ràng

- prefix:
  - "≈" hoặc "Ước tính"

---

## Scope
- Home balance card

---

## Out of scope
- realtime exchange rate API

---

## Success metric

- User hiểu tổng tài sản
