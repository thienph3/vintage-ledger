# 📉 Feature: Firestore Read Optimization

## Type
Performance / Cost

---

## Problem
- Firestore reads có limit (Spark)

---

## Goal
Giảm reads per user

---

## Solution

### 1. Use ReadCounter

- track reads per screen

---

### 2. Optimize queries

- tránh load toàn bộ data
- dùng date range

---

## Target
< 1000 reads / user / day

---

## Scope
- Repository layer

---

## Success metric
- Giảm reads đáng kể