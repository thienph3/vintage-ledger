# 🔐 Feature: Firestore Security Rules

## Type
Security / Production Readiness

---

## Problem
- Rules hiện tại chưa cover schema mới
- Risk data leak giữa users/accounts

---

## Goal
Đảm bảo:
- chỉ member mới đọc/ghi được data
- không access trái phép

---

## Rules

### 1. Account access
- User phải nằm trong `member_ids` của account

---

### 2. Collections

#### wallets / transactions / categories / budgets / activities
- read/write: chỉ members

---

#### invites
- create: member
- read: public (để join bằng link)
- validate expiry

---

#### users
- chỉ read/write chính user

---

## Validation

- Không cho write fields nhạy cảm:
  - account_id giả
  - created_by giả

---

## Scope
- Cover toàn bộ collections

---

## Success metric
- Không thể đọc data của account khác