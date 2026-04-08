# Implementation Plan: Remove Cache Layer

## Overview

Loại bỏ toàn bộ lớp cache tùy chỉnh (CacheService, AppCache, service-level caches) khỏi ứng dụng Vintage Ledger. Thực hiện theo thứ tự: xóa core cache → cập nhật services → cập nhật UI → cập nhật tests → verify.

## Tasks

- [x] 1. Xóa CacheService và cập nhật AccountService
  - [x] 1.1 Xóa file `lib/core/cache/cache_service.dart`
    - _Requirements: 1.5_
  - [x] 1.2 Cập nhật `AccountService.getAccount()` — xóa CacheService lookup, xóa `_accountCache` map, gọi Firestore trực tiếp
    - Xóa import `cache_service.dart`
    - Xóa field `_accountCache`
    - Đơn giản hóa method: chỉ đọc từ Firestore và return
    - _Requirements: 1.1, 1.3_
  - [x] 1.3 Cập nhật `AccountService.getMemberProfiles()` — xóa CacheService lookup, gọi Firestore trực tiếp
    - Xóa cache check và cache set calls
    - Giữ nguyên batch read logic và ReadCounter tracking
    - _Requirements: 1.2_

- [x] 2. Xóa AppCache và cập nhật ServiceLocator
  - [x] 2.1 Xóa file `lib/core/app_cache.dart`
    - _Requirements: 2.2_
  - [x] 2.2 Cập nhật `lib/core/service_locator.dart` — xóa `cache` và `cacheService` fields, xóa imports
    - _Requirements: 1.4, 2.1_

- [x] 3. Xóa cache nội bộ trong Services
  - [x] 3.1 Cập nhật `CategoryService` — xóa `_cache` field, đơn giản hóa `getCategories()` thành `return await _repo.getAll()`, xóa `_cache = null` trong create/update/delete
    - _Requirements: 5.1, 5.5_
  - [x] 3.2 Cập nhật `BudgetService` — xóa `_cache` field, đơn giản hóa `getBudgets()` thành `return await _repo.getAll()`, xóa `_invalidateCache()` và các calls
    - _Requirements: 5.2, 5.6_
  - [x] 3.3 Cập nhật `SettingService` — xóa `_cache` field, thay `_ensureCache()` bằng `_loadSettings()` (đọc Firestore mỗi lần), xóa `clearCache()`, cập nhật `_write()` để không update `_cache`
    - _Requirements: 5.3, 5.4_

- [x] 4. Cập nhật BootstrapService
  - [x] 4.1 Đơn giản hóa `_runSettings()` — xóa `sl.cache.lastWalletId = lastWalletId`
    - _Requirements: 2.3_
  - [x] 4.2 Đơn giản hóa `_runData()` — xóa tất cả `sl.cache.*` calls, chỉ giữ FeedHelper.preloadNames logic
    - _Requirements: 2.3, 2.4_

- [x] 5. Checkpoint — Đảm bảo services biên dịch thành công
  - Chạy `flutter analyze` để kiểm tra lỗi biên dịch
  - Hỏi user nếu có vấn đề

- [x] 6. Cập nhật UI screens — thay thế sl.cache.* bằng service calls
  - [x] 6.1 Cập nhật `home_screen.dart` — thay `sl.cache.lastWalletId`, `sl.cache.categoryNameMap`, `sl.cache.currentAccount`, `sl.cache.walletNameMap` bằng service calls
    - _Requirements: 3.1, 3.2, 3.3, 3.5, 3.6_
  - [x] 6.2 Cập nhật `transaction_list_screen.dart` — thay `sl.cache.categories`, `sl.cache.categoryNameMap`, `sl.cache.lastWalletId`, `sl.cache.memberProfiles`, `sl.cache.walletNameMap` bằng service calls
    - _Requirements: 3.1, 3.2, 3.4, 3.5, 3.6_
  - [x] 6.3 Cập nhật `transaction_form_screen.dart` — thay `sl.cache.categories`, `sl.cache.lastWalletId`, `sl.cache.currentAccount`, `sl.cache.memberProfiles` bằng service calls
    - _Requirements: 3.1, 3.3, 3.4, 3.5_
  - [x] 6.4 Cập nhật `transaction_service.dart` — thay `sl.cache.walletNameMap` và `sl.cache.currentAccount` bằng dữ liệu từ Firestore snapshots hoặc service calls
    - _Requirements: 3.2, 3.3_
  - [x] 6.5 Cập nhật `quick_add_bar.dart` — thay `sl.cache.categories` bằng service call
    - _Requirements: 3.1_
  - [x] 6.6 Cập nhật `category_list_screen.dart` — thay `sl.cache.categories` bằng service call
    - _Requirements: 3.1_
  - [x] 6.7 Cập nhật `recurring_list_screen.dart` và `recurring_form_screen.dart` — thay `sl.cache.categories` bằng service call
    - _Requirements: 3.1_
  - [x] 6.8 Cập nhật `wallet_detail_screen.dart` — thay `sl.cache.categories` và `sl.cache.walletNameMap` bằng service calls
    - _Requirements: 3.1, 3.2_
  - [x] 6.9 Cập nhật `setting_screen.dart` — xóa `sl.cache.clear()` và `sl.settingService.clearCache()`, thay `sl.cache.currentAccount` và `sl.cache.memberProfiles` bằng service calls
    - _Requirements: 4.1, 4.3, 3.3, 3.4_
  - [x] 6.10 Cập nhật `account_picker_screen.dart` — xóa `sl.cache.clear()`
    - _Requirements: 4.2_

- [x] 7. Checkpoint — Đảm bảo toàn bộ app biên dịch thành công
  - Chạy `flutter analyze` để kiểm tra lỗi biên dịch
  - Hỏi user nếu có vấn đề

- [x] 8. Cập nhật tests
  - [x] 8.1 Cập nhật `test/performance/firebase_optimization_test.dart` — xóa CacheService import, xóa các test liên quan đến CacheService (cache set/get, cache key generation, cache cleanup, cache reduces reads), giữ nguyên ReadCounter và ListenerManager tests
    - _Requirements: 6.1_
  - [ ]* 8.2 Write property test cho category name map construction equivalence
    - **Property 3: Category name map construction equivalence**
    - **Validates: Requirements 3.6**

- [-] 9. Final checkpoint — Đảm bảo tất cả tests pass
  - Chạy `flutter test` để đảm bảo tất cả test pass
  - Chạy `flutter analyze` để đảm bảo không có warnings/errors
  - Hỏi user nếu có vấn đề
  - _Requirements: 6.2_
