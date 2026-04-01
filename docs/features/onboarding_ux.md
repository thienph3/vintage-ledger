# 🚀 Feature: Onboarding & First Experience

## Problem
- App mở lâu (login → chọn account → chọn wallet)
- User drop sớm

---

## Goal
User mở app → dùng ngay (không friction)

---

## Solution

### 1. Anonymous first
- Cho phép dùng ngay (account local)
- Không bắt login

---

### 2. Delayed login
Chỉ ask login khi:
- user muốn sync
- user đổi device

---

### 3. Auto context
- Auto chọn:
  - account
  - wallet

---

### 4. First-run setup
- Tạo sẵn:
  - 1 wallet
  - default categories

---

## Flow

Open app → Home → Add transaction

---

## Scope v1
- Skip login
- Auto-create wallet
- Persist last context

---

## Success metric
- Time to first transaction < 10s