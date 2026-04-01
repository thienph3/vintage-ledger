# 🔔 Feature: FCM Race Condition Mitigation

## Type
System Reliability / Notification

---

## Context
- Client-side FCM push (không dùng server)
- Multiple devices có thể cùng gửi notification

---

## Problem

Race condition khi:
- nhiều user/devices cùng trigger notification
- dẫn đến:
  - duplicate notification
  - thứ tự không ổn định

---

## Goal

- Mỗi event (transaction / invite) chỉ notify 1 lần
- Tránh duplicate cross-device

---

## Solution

### 1. Event ID

- Mỗi event có unique ID:
  - transaction → transactionId
  - invite → inviteId

---

### 2. Notification lock (Firestore-based)

Collection: `accounts/{accountId}/notification_events/{eventId}`


Fields:
- created_at

---

### 3. Flow

Before sending notification:

1. Check:
   - eventId đã tồn tại chưa

2. Nếu chưa:
   - create doc (eventId)
   - proceed gửi notification

3. Nếu đã tồn tại:
   - skip gửi

---

### 4. TTL cleanup (optional)

- Xóa events sau 1–3 ngày

---

## Scope
- NotificationService

---

## Success metric
- Không còn duplicate notification cross-device