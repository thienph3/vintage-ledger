# Implementation Plan: Home Quick Actions Redesign

## Overview

Refactor QuickActionsFab để hiển thị context-aware action buttons. Tách visibility logic ra pure class, cập nhật HomeScreen để cung cấp reactive data, và thêm GoalService vào ServiceLocator.

## Tasks

- [-] 1. Tạo QuickActionsVisibility logic và data models
  - [x] 1.1 Tạo `lib/common/widgets/quick_actions_visibility.dart` với `QuickActionsInput`, `QuickActionType` enum, và `QuickActionsVisibility.resolve()` pure function
    - `QuickActionsInput`: isFamily (bool), walletCount (int), hasActiveGoals (bool), hasActiveDebts (bool)
    - `QuickActionType`: funding, transfer, goalContribution, debtPayment
    - `resolve()`: trả về `List<QuickActionType>` dựa trên visibility rules (truth table trong design)
    - Thứ tự cố định: funding → transfer → goalContribution → debtPayment
    - _Requirements: 1.1, 2.1, 2.2, 3.1, 3.2, 4.1, 4.2, 5.1, 5.2_

  - [ ]* 1.2 Write property tests cho QuickActionsVisibility.resolve()
    - **Property 1: Funding visibility biconditional** — For any QuickActionsInput, funding appears in result iff isFamily is true
    - **Validates: Requirements 2.1, 2.2**
    - **Property 2: Transfer visibility biconditional** — For any QuickActionsInput, transfer appears in result iff walletCount >= 2
    - **Validates: Requirements 3.1, 3.2**
    - **Property 3: Goal contribution visibility biconditional** — For any QuickActionsInput, goalContribution appears in result iff hasActiveGoals is true
    - **Validates: Requirements 4.1, 4.2**
    - **Property 4: Debt payment visibility biconditional** — For any QuickActionsInput, debtPayment appears in result iff hasActiveDebts is true
    - **Validates: Requirements 5.1, 5.2**

  - [ ]* 1.3 Write unit tests cho edge cases
    - Test: personal account, 1 wallet, no goals, no debts → empty list (Req 7.1)
    - Test: family account, 3 wallets, active goals, active debts → all 4 actions
    - Test: walletCount boundary (0, 1, 2)
    - _Requirements: 7.1, 7.2_

- [x] 2. Thêm GoalService vào ServiceLocator
  - [x] 2.1 Thêm `goalService` field vào `lib/core/service_locator.dart`
    - Import GoalService và thêm `final goalService = GoalService();`
    - _Requirements: 4.1, 4.2 (prerequisite)_

- [x] 3. Refactor QuickActionsFab widget
  - [x] 3.1 Cập nhật `lib/common/widgets/quick_actions_fab.dart`
    - Thêm `required QuickActionsInput actionsInput` parameter
    - Sử dụng `QuickActionsVisibility.resolve(actionsInput)` để xác định danh sách nút
    - Loại bỏ nút "Thêm thu chi" (hardcoded TransactionFormScreen navigation)
    - Map mỗi `QuickActionType` sang label, icon, color, và navigation target
    - Giữ nguyên animation, overlay, và expand/collapse behavior hiện tại
    - Trả về `SizedBox.shrink()` khi resolve trả về list rỗng
    - _Requirements: 1.1, 2.3, 3.3, 4.3, 5.3, 7.1_

- [x] 4. Cập nhật HomeScreen để cung cấp reactive data
  - [x] 4.1 Cập nhật `lib/features/home/screens/home_screen.dart`
    - Thêm streams cho goals (`sl.goalService.watchGoalsProgress()`) và debts (`sl.debtService.watchActiveDebts()`)
    - Lấy Account info để check `isFamily`
    - Tạo `QuickActionsInput` từ dữ liệu reactive (wallets, account, goals, debts)
    - Truyền `actionsInput` xuống QuickActionsFab
    - Ẩn FAB khi resolve trả về list rỗng
    - _Requirements: 2.1, 2.2, 3.1, 3.2, 4.1, 4.2, 5.1, 5.2, 6.1, 6.2, 6.3, 7.1, 7.2_

- [ ] 5. Checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- GoalService cần được thêm vào ServiceLocator trước khi HomeScreen có thể sử dụng
- Property tests tập trung vào pure function `resolve()` — dễ test vì không có side effects
- Widget tests cho navigation và UI behavior nằm ngoài scope property testing
