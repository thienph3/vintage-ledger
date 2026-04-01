# 💬 Feature: Notification UX

## Type
UX Improvement

---

## Goal
Notification rõ ràng, hữu ích, không spam

---

## Requirements

### 1. Message content

#### Invite
"Bạn được mời vào gia đình {name}"

#### Transaction
"{user} vừa chi {amount} {category}"

---

### 2. Deep link

- Invite → JoinFamilyScreen
- Transaction → Home + highlight

---

### 3. Avoid spam

- Nếu nhiều transaction liên tiếp:
  - delay 1–2s
  - batch nhẹ (optional)

---

## Scope
- NotificationService

---

## Success metric
- User hiểu ngay notification