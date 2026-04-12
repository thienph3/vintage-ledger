---
inclusion: always
---

# Style Guide — Vintage Ledger

Tham khảo chi tiết: #[[file:docs/style_guides/design.md]]

## Nguyên tắc cốt lõi

- App dành cho couple/family — giọng văn gần gũi, thân mật, không phải công cụ tài chính khô khan
- Mọi feed item phải viết thành **1 câu liền mạch** kiểu story: "Minh ăn trưa 80k 🍜"
- Luôn hiển thị "ai làm gì" (actor) — tạo cảm giác chia sẻ, không phải theo dõi
- Giọng văn: casual, "tụi mình", "hôm nay", câu ngắn, nhẹ nhàng

## Feed Item / Transaction Story

- Format: `{tên người} {hành động} {số tiền} {emoji}` — 1 câu duy nhất
- Tên member nổi bật bằng **màu primary** (`AppColors.primary` / `#5B7FA2`), KHÔNG dùng fontWeight bold vì không đáng tin cậy trên mọi device
- Dùng `WidgetSpan` + `Text` widget riêng cho tên member (đảm bảo style độc lập), kết hợp `TextSpan` cho phần còn lại
- KHÔNG tách thành 2 dòng — phải giữ 1 câu liền mạch

## Colors

- Không dùng inline `Color(0xFF...)` — luôn dùng `AppColors.*`
- Income: `AppColors.income` (xanh lá nhạt), Expense: `AppColors.expense` (cam ấm)
- Không dùng đỏ mạnh — dùng cam ấm cho lỗi/chi tiêu
- Primary (`#5B7FA2`): actions, icons, focus, member name highlight

## Typography

- Không dùng inline `TextStyle()` — luôn dùng `AppTextStyles.*` hoặc `.copyWith()`
- System sans-serif, không custom font
- Sentence case — không viết hoa toàn bộ

## Spacing & Layout

- Không dùng magic numbers — luôn dùng `AppSpacing.*`
- Card radius: 16, dialog/bottom sheet: 20, chat input: 24

## Tone & Content

- "Xóa luôn hả?" thay vì "Bạn có chắc chắn muốn xóa?"
- "Hmm, có gì đó sai rồi" thay vì "Có lỗi xảy ra"
- Emoji nhẹ nhàng, không sticker childish

## Loading & Empty States

- Shimmer placeholder, KHÔNG dùng CircularProgressIndicator trần
- Empty state: emoji + hint casual ("Chưa có gì — thử ghi 1 khoản xem 👇")

## Localization

- Mọi string hiển thị phải dùng `S.of(context, 'key')`
