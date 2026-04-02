# Feature: Daily Reminder (Local Notification)

## Mục tiêu

Tăng DAU bằng cách tạo trigger quay lại app mỗi ngày.

## Vấn đề

User phải tự nhớ mở app → retention thấp.

## Giải pháp

Local notification mỗi ngày (không cần backend).

## Behavior

- Thời gian mặc định: 20:00
- Nếu user chưa có transaction hôm nay:
  → gửi notification

## Message examples

- "Hôm nay bạn đã tiêu gì chưa?"
- "Ghi lại chi tiêu hôm nay chỉ mất 5 giây 👇"

## Logic

if (no transaction today) {
  schedule notification
}

## Settings

- Toggle bật/tắt reminder
- Cho phép chọn giờ (optional)

## Technical

- Flutter local_notifications
- Không cần FCM / Cloud Function

## Expected Impact

- Tăng DAU
- Tạo habit loop