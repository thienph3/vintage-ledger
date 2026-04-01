# ⚠️ Feature: User-friendly Error Handling

## Type
UX / Reliability

---

## Problem
- Hiển thị raw Firestore exception
- User không hiểu lỗi

---

## Goal
Error rõ ràng, dễ hiểu

---

## Solution

### Map error codes

- network → "Mất kết nối"
- permission → "Không có quyền"
- quota → "Hệ thống quá tải"
- unknown → "Có lỗi xảy ra"

---

## UI

- ErrorSnackBar:
  - message ngắn gọn
  - có nút dismiss

---

## Scope
- Tất cả write operations

---

## Success metric
- User hiểu lỗi và không bị confuse