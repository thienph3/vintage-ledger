# Implementation Plan: Transaction Summary Net Display

## Overview

Triển khai hiển thị Net (thu - chi) trên màn hình danh sách giao dịch và làm nổi bật tên người thực hiện giao dịch. Thay đổi tập trung vào presentation layer với 5 file cần cập nhật.

## Tasks

- [x] 1. Thêm Net vào Summary Area của TransactionListScreen
  - [x] 1.1 Thêm helper method `_netColor(int net)` trả về Color dựa trên dấu của net (income/expense/textSecondary)
    - _Requirements: 1.3, 1.4, 1.5_
  - [x] 1.2 Cập nhật `_buildSummaryChip` thêm parameter `prefix` (String, default '') để hiển thị dấu +/- trước số tiền
    - _Requirements: 1.1_
  - [x] 1.3 Cập nhật `build()` method: tính `totalNet = totalIncome - totalExpense`, thêm Summary_Chip thứ 3 cho Net với label từ `S.of(context, 'net')`, sử dụng `_netColor` và prefix phù hợp
    - _Requirements: 1.1, 1.2, 1.6_
  - [ ]* 1.4 Write property test cho net color mapping
    - **Property 1: Net color mapping**
    - **Validates: Requirements 1.3, 1.4, 1.5, 2.4, 2.5, 2.6**

- [x] 2. Cập nhật IncomeExpenseSummaryRow hỗ trợ Net
  - [x] 2.1 Thêm parameters `showNet` (bool, default false) và `netLabel` (String?) vào `IncomeExpenseSummaryRow`
    - _Requirements: 2.1_
  - [x] 2.2 Thêm cột Net thứ 3 khi `showNet == true`, sử dụng cùng logic màu như `_netColor` (tách thành static helper hoặc dùng inline)
    - _Requirements: 2.2, 2.3, 2.4, 2.5, 2.6_
  - [ ]* 2.3 Write unit test cho IncomeExpenseSummaryRow với showNet true/false
    - _Requirements: 2.1, 2.2, 2.3_

- [ ] 3. Checkpoint - Verify Net display
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Refactor TransactionStory trả về structured data
  - [x] 4.1 Thêm typedef `StoryParts = ({String? actorName, String rest})` và method `formatStructured()` vào `TransactionStory`, giữ nguyên `format()` cho backward compatibility
    - _Requirements: 5.1, 5.2, 5.3_
  - [ ]* 4.2 Write property test cho TransactionStory structured/plain consistency (round-trip)
    - **Property 3: TransactionStory structured/plain consistency**
    - **Validates: Requirements 5.2, 5.3**

- [x] 5. Cập nhật FeedItem và TransactionFeedItem hiển thị tên nổi bật
  - [x] 5.1 Cập nhật `FeedItem`: thêm optional parameters `boldPrefix` và `textAfterPrefix`, render bằng `RichText` với `TextSpan` w600 cho boldPrefix khi có giá trị
    - _Requirements: 3.1, 3.3_
  - [x] 5.2 Cập nhật `TransactionFeedItem`: chuyển từ `TransactionStory.format()` sang `formatStructured()`, truyền `boldPrefix` và `textAfterPrefix` vào `FeedItem`
    - _Requirements: 3.2_
  - [ ]* 5.3 Write unit test cho FeedItem render RichText khi có boldPrefix
    - _Requirements: 3.1, 3.2, 3.3_

- [ ] 6. Net invariant property test
  - [ ]* 6.1 Write property test cho net invariant (net + expense == income) với random transaction lists
    - **Property 2: Net invariant (net + expense == income)**
    - **Validates: Requirements 1.2, 4.1, 4.2, 4.3, 4.4**

- [ ] 7. Final checkpoint
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Logic tính thu/chi (`_countsAsIncome`, `_countsAsExpense`) đã đúng, không cần thay đổi
- Localization key `net` đã tồn tại (EN: "Net", VI: "Chênh lệch")
- Property tests sử dụng `glados` package
