# Tasks: Quick Add UX Improvements

> Quick Add nhanh nhưng vẫn an toàn. Undo + confidence fallback.

## Phụ thuộc
- Không

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | Undo snackbar | Sau khi quick add thành công, hiển thị snackbar "Đã thêm 50k Ăn uống" với nút "Hoàn tác". Tap undo → deleteTransaction + reload | 🔴 |
| 2 | Confidence threshold | Nếu keyword match chỉ bằng fuzzy (không phải exact keyword hoặc learned) → hiển thị "?" trong preview + tap submit mở full form thay vì save trực tiếp | 🟡 |
| 3 | L10n keys | Thêm: undoSuccess, undone | 🟢 |
