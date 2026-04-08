# Tài liệu Yêu cầu

## Giới thiệu

Ứng dụng Vintage Ledger hiện đang sử dụng hai lớp cache tùy chỉnh (CacheService và AppCache) song song với Firestore persistence đã được bật sẵn (`persistenceEnabled: true`, `cacheSizeBytes: CACHE_SIZE_UNLIMITED`). Việc duy trì hai lớp cache tùy chỉnh này tạo ra sự phức tạp không cần thiết, vì Firestore đã tự động cache dữ liệu offline. Yêu cầu này nhằm loại bỏ hoàn toàn lớp cache tùy chỉnh và chuyển sang sử dụng trực tiếp Firestore.

## Thuật ngữ

- **CacheService**: Lớp cache in-memory với TTL (Time-To-Live) 5 phút, tự động dọn dẹp, được sử dụng trong AccountService để cache dữ liệu tài khoản và hồ sơ thành viên. Nằm tại `lib/core/cache/cache_service.dart`.
- **AppCache**: Lớp lưu trữ dữ liệu in-memory đơn giản, chứa categories, wallets, currentAccount, memberProfiles, lastWalletId. Được nạp dữ liệu trong quá trình bootstrap và sử dụng rộng rãi trong UI. Nằm tại `lib/core/app_cache.dart`.
- **Service_Cache**: Cache in-memory nội bộ (`_cache` field) trong CategoryService, BudgetService, và SettingService. Mỗi service lưu dữ liệu vào biến `_cache` sau lần đọc đầu tiên.
- **ServiceLocator**: Singleton quản lý tất cả service instances, đăng ký cả `cache` (AppCache) và `cacheService` (CacheService). Nằm tại `lib/core/service_locator.dart`.
- **BootstrapService**: Service khởi tạo ứng dụng, nạp dữ liệu vào AppCache khi app khởi động. Nằm tại `lib/core/bootstrap/bootstrap_service.dart`.
- **AccountService**: Service quản lý tài khoản, sử dụng CacheService để cache dữ liệu account và member profiles. Nằm tại `lib/features/account/services/account_service.dart`.
- **Firestore_Persistence**: Cơ chế cache offline tích hợp sẵn của Firestore, đã được bật với dung lượng không giới hạn.

## Yêu cầu

### Yêu cầu 1: Xóa CacheService

**User Story:** Là một nhà phát triển, tôi muốn loại bỏ CacheService khỏi codebase, để giảm độ phức tạp và tránh trùng lặp chức năng với Firestore persistence.

#### Tiêu chí chấp nhận

1. WHEN CacheService bị xóa, THE AccountService SHALL truy vấn dữ liệu account trực tiếp từ Firestore thay vì kiểm tra cache trước
2. WHEN CacheService bị xóa, THE AccountService SHALL truy vấn member profiles trực tiếp từ Firestore thay vì kiểm tra cache trước
3. WHEN CacheService bị xóa, THE AccountService SHALL loại bỏ trường `_accountCache` map nội bộ
4. WHEN CacheService bị xóa, THE ServiceLocator SHALL không còn đăng ký thuộc tính `cacheService`
5. WHEN CacheService bị xóa, THE Hệ thống SHALL xóa file `lib/core/cache/cache_service.dart`

### Yêu cầu 2: Xóa AppCache

**User Story:** Là một nhà phát triển, tôi muốn loại bỏ AppCache khỏi codebase, để tất cả dữ liệu được đọc trực tiếp từ Firestore (với offline cache tích hợp).

#### Tiêu chí chấp nhận

1. WHEN AppCache bị xóa, THE ServiceLocator SHALL không còn đăng ký thuộc tính `cache`
2. WHEN AppCache bị xóa, THE Hệ thống SHALL xóa file `lib/core/app_cache.dart`
3. WHEN AppCache bị xóa, THE BootstrapService SHALL không còn nạp dữ liệu vào AppCache trong quá trình khởi động
4. WHEN AppCache bị xóa, THE BootstrapService SHALL vẫn thực hiện các bước khởi tạo cần thiết (auth, account, settings) mà không lưu kết quả vào AppCache

### Yêu cầu 3: Cập nhật các điểm truy cập dữ liệu trong UI

**User Story:** Là một nhà phát triển, tôi muốn tất cả các màn hình UI đọc dữ liệu trực tiếp từ service thay vì từ AppCache, để dữ liệu luôn nhất quán.

#### Tiêu chí chấp nhận

1. WHEN một màn hình UI cần danh sách categories, THE Màn_hình SHALL gọi `CategoryService.getCategories()` thay vì đọc từ `sl.cache.categories`
2. WHEN một màn hình UI cần danh sách wallets hoặc wallet name map, THE Màn_hình SHALL gọi `WalletService.getWallets()` thay vì đọc từ `sl.cache.wallets` hoặc `sl.cache.walletNameMap`
3. WHEN một màn hình UI cần thông tin account hiện tại, THE Màn_hình SHALL gọi `AccountService.getAccount()` thay vì đọc từ `sl.cache.currentAccount`
4. WHEN một màn hình UI cần danh sách member profiles, THE Màn_hình SHALL gọi `AccountService.getMemberProfiles()` thay vì đọc từ `sl.cache.memberProfiles`
5. WHEN một màn hình UI cần lastWalletId, THE Màn_hình SHALL gọi `SettingService.getLastWalletId()` thay vì đọc từ `sl.cache.lastWalletId`
6. WHEN một màn hình UI cần category name map, THE Màn_hình SHALL tự xây dựng map từ kết quả `CategoryService.getCategories()` thay vì đọc từ `sl.cache.categoryNameMap`

### Yêu cầu 4: Cập nhật logic xóa cache khi logout/chuyển tài khoản

**User Story:** Là một nhà phát triển, tôi muốn loại bỏ các lệnh gọi `sl.cache.clear()` khi logout hoặc chuyển tài khoản, vì không còn cache tùy chỉnh để xóa.

#### Tiêu chí chấp nhận

1. WHEN người dùng logout, THE SettingScreen SHALL không gọi `sl.cache.clear()` nữa
2. WHEN người dùng chuyển tài khoản, THE AccountPickerScreen SHALL không gọi `sl.cache.clear()` nữa
3. WHEN người dùng logout hoặc chuyển tài khoản, THE SettingScreen SHALL không gọi `sl.settingService.clearCache()` nữa vì method này đã bị xóa
4. WHEN người dùng logout hoặc chuyển tài khoản, THE Hệ thống SHALL vẫn xóa các trạng thái khác (appState, FeedHelper cache) như hiện tại

### Yêu cầu 5: Xóa cache nội bộ trong các Service

**User Story:** Là một nhà phát triển, tôi muốn loại bỏ cache in-memory nội bộ (`_cache` field) trong CategoryService, BudgetService, và SettingService, để tất cả dữ liệu được đọc trực tiếp từ Firestore persistence.

#### Tiêu chí chấp nhận

1. WHEN cache nội bộ bị xóa, THE CategoryService SHALL gọi repository trực tiếp mỗi lần `getCategories()` được gọi, thay vì trả về `_cache`
2. WHEN cache nội bộ bị xóa, THE BudgetService SHALL gọi repository trực tiếp mỗi lần `getBudgets()` được gọi, thay vì trả về `_cache`
3. WHEN cache nội bộ bị xóa, THE SettingService SHALL đọc từ Firestore mỗi lần setting được truy vấn, thay vì trả về `_cache`
4. WHEN cache nội bộ bị xóa, THE SettingService SHALL loại bỏ method `clearCache()` và field `_cache`
5. WHEN cache nội bộ bị xóa, THE CategoryService SHALL loại bỏ logic `_invalidateCache` (set `_cache = null` sau create/update/delete)
6. WHEN cache nội bộ bị xóa, THE BudgetService SHALL loại bỏ method `_invalidateCache()` và field `_cache`

### Yêu cầu 6: Cập nhật test liên quan

**User Story:** Là một nhà phát triển, tôi muốn cập nhật hoặc xóa các test liên quan đến CacheService, để test suite vẫn chạy thành công sau khi xóa cache layer.

#### Tiêu chí chấp nhận

1. WHEN CacheService bị xóa, THE Test_Suite SHALL xóa hoặc cập nhật các test trong `test/performance/firebase_optimization_test.dart` liên quan đến CacheService
2. WHEN tất cả thay đổi hoàn tất, THE Test_Suite SHALL biên dịch thành công mà không có lỗi liên quan đến cache
