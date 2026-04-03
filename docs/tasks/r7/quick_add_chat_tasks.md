# Tasks: Quick Add — Chat-like Redesign

Chuyển Quick Add từ "form input" sang "message bar" — giống chat app.

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | Chat-like input style | `quick_add_bar.dart` | Bỏ OutlineInputBorder. Dùng rounded container (radius 24) với subtle background. Giống message input bar (Messenger/Zalo style) |
| 2 | Send button style | `quick_add_bar.dart` | Bỏ `Icons.check_circle` / `Icons.add_circle`. Dùng send arrow icon (Icons.send_rounded) hoặc circular send button. Soft blue color |
| 3 | Suggestion chips redesign | `quick_add_bar.dart` | Chips nhỏ hơn, rounded pill, muted background. Hiện phía trên input (like quick replies in chat) |
| 4 | Preview redesign | `quick_add_bar.dart` | Preview nhẹ hơn: chỉ "{amount} {category}" inline, không cần wallet chip khi 1 ví |
| 5 | Success feedback | `quick_add_bar.dart` | Thay SnackBar bằng inline animation nhẹ: text fade "Đã ghi ✓" rồi biến mất. Non-blocking |
| 6 | Bỏ wallet picker phức tạp | `quick_add_bar.dart` | Nếu 1 ví: ẩn hoàn toàn. Nếu nhiều ví: chip nhỏ phía trên, tap đổi |
