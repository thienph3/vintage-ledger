# ☁️ Feature: Data Layer V2 (Firestore-first)

## Type
Architecture / Core System

---

## Context
App chuyển từ:
- Local-first (SQLite + sync)

→ sang:

- Firestore-first (cloud as source of truth)

---

## Goal
- Loại bỏ sync phức tạp
- Đảm bảo data luôn nhất quán
- Tận dụng realtime + offline cache của Firestore

---

## Principles

- Firestore = source of truth
- Client = thin layer
- Không manual sync
- Realtime by default

---

## Key Features

### 1. Realtime listeners
- Sử dụng snapshot listener cho:
  - wallets
  - transactions
  - categories

→ UI auto update khi data thay đổi

---

### 2. Offline support
- Bật Firestore offline persistence
- Cho phép:
  - đọc khi offline
  - write queue khi offline

---

### 3. Optimistic UI
- Khi user tạo transaction:
  - update UI ngay
  - Firestore sync ngầm

---

### 4. Error handling
- Hiển thị trạng thái:
  - saving...
  - failed → retry

---

### 5. Network awareness
- Detect offline/online
- Hiển thị trạng thái (optional v1)

---

### 6. Data consistency
- Dùng:
  - server timestamp
  - atomic updates (transactions nếu cần)

---

## Removed Concepts

- ❌ manual push/pull
- ❌ sync_deletes (tombstone)
- ❌ is_synced flag
- ❌ remote_id mapping

---

## Trade-offs

### Pros
- Code đơn giản hơn nhiều
- Ít bug sync
- Realtime UX tốt hơn

---

### Cons
- Phụ thuộc Firestore
- Cost tăng theo usage

---

## Scope v1
- Realtime wallets + transactions
- Offline persistence basic
- Basic error handling

---

## Out of scope
- advanced retry logic
- complex conflict resolution

---

## Success metric
- User không cần nghĩ về sync
- Data luôn consistent giữa devices