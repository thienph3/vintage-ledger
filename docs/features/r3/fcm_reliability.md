# 🔔 Feature: FCM Reliability (Client-side)

## Type
System Reliability / UX

---

## Context
- Sử dụng Firebase Cloud Messaging (client-side HTTP API)
- Không dùng Cloud Functions (Spark plan constraint)

---

## Problem
- Notification có thể:
  - gửi fail (network, timeout)
  - gửi duplicate
  - gửi cho chính user
- Token lifecycle không ổn định

---

## Goal
Notification:
- gửi đúng người
- không duplicate
- ổn định (retry nếu fail)

---

## Requirements

### 1. Token lifecycle

- On app start:
  - register token vào:
    users/{userId}/fcm_tokens/{token}

- On token refresh:
  - update Firestore

- On logout:
  - remove token

- Prevent duplicate tokens

---

### 2. Deduplication

- Mỗi event có:
  - event_id (transactionId / inviteId)

- Khi gửi:
  - đảm bảo mỗi token chỉ nhận 1 lần / event

---

### 3. Self-notification

- Không gửi notification cho:
  created_by == currentUserId

---

### 4. Retry

- Retry tối đa 2 lần:
  - delay: 500ms → 1s

- Handle:
  - timeout
  - non-200 response

---

### 5. Failure handling

- Nếu fail hoàn toàn:
  - log (debug mode)
  - không crash app

---

## Scope
- Invite notification
- Transaction notification

---

## Out of scope
- Security (server key exposure)

---

## Success metric
- Notification delivery rate > 95% trong test
- Không có duplicate visible