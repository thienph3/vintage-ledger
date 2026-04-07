# R11: Code Cleanup & Style Guide Compliance

> Dọn dẹp legacy code, tái cấu trúc localization, và audit style guide compliance

---

## Objectives

1. **Remove Legacy Code** — Xóa bỏ code cũ không còn dùng để giảm maintenance burden
2. **Refactor Localization** — Tái cấu trúc locale files để dễ maintain và mở rộng
3. **Style Guide Audit** — Review toàn bộ codebase, fix các chỗ chưa tuân thủ style guide

---

## 1. Legacy Code Removal

### 1.1 Old Debt System (V1)

**Files to Remove:**
```
lib/features/debt/
├── models/
│   ├── debt.dart ❌ REMOVE
│   └── payment.dart ❌ REMOVE
├── repositories/
│   └── debt_repository.dart ❌ REMOVE
├── services/
│   └── debt_service.dart ❌ REMOVE
├── screens/
│   ├── debt_list_screen.dart ❌ REMOVE
│   ├── debt_form_screen.dart ❌ REMOVE
│   └── debt_detail_screen.dart ❌ REMOVE
└── widgets/
    ├── debt_progress_bar.dart ❌ REMOVE (duplicate)
    └── debt_summary_card.dart ❌ REMOVE (old version)
```

**Keep & Rename:**
- `debt_v2.dart` → `debt.dart`
- `debt_payment_v2.dart` → `debt_payment.dart`
- `debt_repository_v2.dart` → `debt_repository.dart`
- `debt_service_v2.dart` → `debt_service.dart`
- `debt_list_screen_v2.dart` → `debt_list_screen.dart`
- `debt_form_screen_v2.dart` → `debt_form_screen.dart`
- `debt_detail_screen_v2.dart` → `debt_detail_screen.dart`
- `debt_payment_screen.dart` ✅ KEEP
- `debt_summary_widget.dart` ✅ KEEP

**Firestore Collections:**
- `debts` collection → Mark as deprecated (no migration)
- `debts_v2` collection → Keep as is (don't rename in Firestore)

### 1.2 Old Goal System (Wallet-based)

**Files to Remove:**
```
lib/features/wallet/
├── models/
│   └── wallet_goal.dart ❌ REMOVE
├── repositories/
│   └── goal_repository.dart ❌ REMOVE
├── services/
│   └── goal_service.dart ❌ REMOVE
├── screens/
│   └── goal_form_screen.dart ❌ REMOVE (wallet-specific)
└── widgets/
    └── goal_progress_bar.dart ❌ REMOVE (duplicate)
```

**Keep & Rename in lib/features/goal/:**
- `goal_v2.dart` → `goal.dart`
- `goal_contribution.dart` ✅ KEEP
- `auto_saving_rule.dart` ✅ KEEP
- `goal_repository_v2.dart` → `goal_repository.dart`
- `goal_service_v2.dart` → `goal_service.dart`
- `goal_list_screen.dart` ✅ KEEP
- `goal_form_screen.dart` ✅ KEEP
- `goal_detail_screen.dart` ✅ KEEP
- `goal_contribution_screen.dart` ✅ KEEP
- `goal_summary_widget.dart` ✅ KEEP

**Firestore Collections:**
- `wallets/{id}/goals` subcollection → Mark as deprecated
- `goals_v2` collection → Keep as is

### 1.3 Old Transfer Logic

**Rename:**
- `transfer_v2.dart` → `transfer.dart`
- `transfer_repository_v2.dart` → `transfer_repository.dart`
- `transfer_service_v2.dart` → `transfer_service.dart`

**Firestore Collections:**
- `transfers_v2` → Keep as is

### 1.4 Summary

**Total files to remove:** ~15 files
**Total files to rename:** ~9 files
**Estimated LOC reduction:** ~900 lines

---

## 2. Localization Refactoring

### 2.1 Current Issues

1. **Flat structure** — 378 keys in single Map, hard to navigate
2. **Inconsistent naming** — Mix of patterns
3. **Duplicate keys** — Similar keys for V1 and V2
4. **No grouping** — Keys scattered
5. **Hard to extend** — Must scroll through 378 keys

### 2.2 Proposed Structure

**Group by Feature:**

```
lib/core/l10n/
├── s.dart                    # Helper (unchanged)
├── app_vi.dart               # Main Vietnamese map (imports all)
├── app_en.dart               # Main English map (imports all)
├── vi/                       # Vietnamese strings by feature
│   ├── common.dart           # cancel, save, delete, error, etc.
│   ├── home.dart             # homeTitle, totalBalance, etc.
│   ├── wallet.dart           # wallet, balance, addWallet, etc.
│   ├── transaction.dart      # income, expense, addTransaction, etc.
│   ├── category.dart         # category, addCategory, etc.
│   ├── budget.dart           # budget, budgetLimit, etc.
│   ├── debt.dart             # debt, lend, borrow, etc.
│   ├── goal.dart             # goal, targetAmount, contribute, etc.
│   ├── transfer.dart         # transfer, fromWallet, toWallet, etc.
│   ├── insights.dart         # insights, chart types, etc.
│   ├── settings.dart         # settings, language, logout, etc.
│   ├── auth.dart             # login, register, email, etc.
│   ├── account.dart          # account, family, invite, etc.
│   └── recurring.dart        # recurring, frequency, etc.
└── en/                       # English (same structure)
    ├── common.dart
    ├── home.dart
    └── ...
```

**Example: lib/core/l10n/vi/common.dart**

```dart
const Map<String, String> commonVi = {
  // Actions
  'cancel': 'Hủy',
  'save': 'Lưu',
  'delete': 'Xóa',
  'edit': 'Sửa',
  'add': 'Thêm',
  'update': 'Cập nhật',
  'done': 'Xong',
  'dismiss': 'Bỏ qua',
  'retry': 'Thử lại',
  'undo': 'Hoàn tác',
  
  // Status
  'loading': 'Đang tải...',
  'success': 'Thành công',
  'error': 'Lỗi',
  
  // Common fields
  'name': 'Tên',
  'amount': 'Số tiền',
  'date': 'Ngày',
  'note': 'Ghi chú',
  
  // Empty states
  'noData': 'Chưa có dữ liệu',
};
```

**Example: lib/core/l10n/vi/debt.dart**

```dart
const Map<String, String> debtVi = {
  // Screen
  'debtTitle': 'Nợ',
  'debts': 'Nợ',
  
  // Types
  'lend': 'Cho vay',
  'borrow': 'Vay mượn',
  'allDebts': 'Tất cả',
  'overdueDebts': 'Quá hạn',
  
  // Actions
  'addDebt': 'Thêm khoản nợ',
  'editDebt': 'Sửa khoản nợ',
  'deleteDebt': 'Xóa khoản nợ',
  'deleteDebtConfirm': 'Xóa khoản nợ này luôn hả?',
  'recordPayment': 'Ghi nhận trả nợ',
  
  // Fields
  'partyName': 'Ai',
  'totalAmount': 'Tổng số',
  'remainingAmount': 'Còn lại',
  'dueDate': 'Hạn trả',
  'overdue': 'Quá hạn',
  
  // Status
  'settled': 'Đã tất toán',
  'paymentHistory': 'Lịch sử trả nợ',
  'noDebts': 'Chưa có khoản nợ nào',
};
```

**Main file: lib/core/l10n/app_vi.dart**

```dart
import 'vi/common.dart';
import 'vi/home.dart';
import 'vi/wallet.dart';
import 'vi/transaction.dart';
import 'vi/category.dart';
import 'vi/budget.dart';
import 'vi/debt.dart';
import 'vi/goal.dart';
import 'vi/transfer.dart';
import 'vi/insights.dart';
import 'vi/settings.dart';
import 'vi/auth.dart';
import 'vi/account.dart';
import 'vi/recurring.dart';

const Map<String, String> vi = {
  ...commonVi,
  ...homeVi,
  ...walletVi,
  ...transactionVi,
  ...categoryVi,
  ...budgetVi,
  ...debtVi,
  ...goalVi,
  ...transferVi,
  ...insightsVi,
  ...settingsVi,
  ...authVi,
  ...accountVi,
  ...recurringVi,
};
```

### 2.3 Migration Strategy

**Phase 1: Create new structure (non-breaking)**
1. Create `lib/core/l10n/vi/` and `lib/core/l10n/en/` directories
2. Create feature-specific files
3. Move keys from `app_vi.dart` to feature files
4. Update `app_vi.dart` to import and merge all maps
5. Repeat for English
6. Test both locales

**Phase 2: Cleanup**
1. Remove duplicate keys (V1 vs V2)
2. Standardize naming convention
3. Add missing keys
4. Update documentation

### 2.4 Naming Convention

**Standard Format:**
- Screen titles: `{feature}Title` — e.g., `debtTitle`, `goalTitle`
- Actions: `{action}{Entity}` — e.g., `addDebt`, `editGoal`
- Fields: `{feature}{Field}` — e.g., `debtPartyName`, `goalTargetAmount`
- Status: `{feature}{Status}` — e.g., `debtOverdue`, `goalCompleted`

---

## 3. Style Guide Compliance Audit

### 3.1 Audit Checklist

**Colors:**
- [ ] No inline `Color(0xFF...)` — use `AppColors.*`
- [ ] No `Colors.red`, `Colors.blue` — use theme colors
- [ ] No `withOpacity()` — use `withValues(alpha:)`

**Typography:**
- [ ] No inline `TextStyle()` — use `AppTextStyles.*`
- [ ] No inline `fontSize`, `fontWeight`
- [ ] Consistent font usage

**Spacing:**
- [ ] No magic numbers — use `AppSpacing.*`
- [ ] No inline `EdgeInsets.all(16)`
- [ ] No inline `SizedBox(height: 8)`

**Components:**
- [ ] All screens use `AppScaffold`
- [ ] All cards use `LedgerCard`
- [ ] All loading use `ShimmerPlaceholder` (no `CircularProgressIndicator`)
- [ ] All empty states use `EmptyState`

**Localization:**
- [ ] No hardcoded strings — use `S.of(context, 'key')`

**Imports:**
- [ ] No relative imports — use `package:vintage_ledger/...`

**Architecture:**
- [ ] No direct repository calls from screens

### 3.2 Automated Audit Script

**scripts/style_audit.sh:**

```bash
#!/bin/bash
echo "🔍 Style Guide Compliance Audit"
echo ""

# Inline colors
echo "❌ Inline colors:"
grep -r "Color(0x" lib/ --include="*.dart" | wc -l

# Inline TextStyle
echo "❌ Inline TextStyle:"
grep -r "TextStyle(" lib/ --include="*.dart" | grep -v "copyWith" | wc -l

# Magic spacing
echo "❌ Magic spacing:"
grep -r "EdgeInsets.all([0-9]" lib/ --include="*.dart" | wc -l

# Hardcoded strings
echo "❌ Hardcoded strings (sample):"
grep -r "Text('" lib/features --include="*.dart" | grep -v "S.of" | head -5

# Relative imports
echo "❌ Relative imports:"
grep -r "import '\.\." lib/ --include="*.dart" | wc -l

# CircularProgressIndicator
echo "❌ CircularProgressIndicator:"
grep -r "CircularProgressIndicator" lib/ --include="*.dart" | wc -l

# Deprecated withOpacity
echo "❌ Deprecated withOpacity:"
grep -r "\.withOpacity(" lib/ --include="*.dart" | wc -l

echo ""
echo "✅ Run 'flutter analyze' for details"
```

### 3.3 Priority Fixes

**High Priority:**
1. Remove `CircularProgressIndicator` → `ShimmerPlaceholder`
2. Replace `withOpacity()` → `withValues(alpha:)`
3. Fix relative imports → `package:vintage_ledger/...`
4. Remove hardcoded strings → `S.of(context, 'key')`

**Medium Priority:**
5. Replace inline colors → `AppColors.*`
6. Replace inline TextStyle → `AppTextStyles.*`
7. Replace magic spacing → `AppSpacing.*`

**Low Priority:**
8. Organize imports
9. Add documentation
10. Extract reusable widgets

---

## 4. Implementation Plan

### Week 1: Legacy Code Removal

**Day 1-2: Debt V1**
- Remove old debt files
- Rename V2 files (remove `_v2`)
- Update imports
- Test debt functionality

**Day 3-4: Goal V1**
- Remove wallet-based goal files
- Rename V2 files
- Update imports
- Test goal functionality

**Day 5: Transfer & Cleanup**
- Rename transfer V2 files
- Remove duplicate widgets
- Run flutter analyze

### Week 2: Localization Refactoring

**Day 1-2: Vietnamese**
- Create `vi/` directory structure
- Create feature files
- Move keys from app_vi.dart
- Test Vietnamese locale

**Day 3-4: English**
- Create `en/` directory structure
- Create feature files
- Move keys from app_en.dart
- Test English locale

**Day 5: Cleanup**
- Remove duplicate keys
- Standardize naming
- Test all screens

### Week 3: Style Guide Audit

**Day 1: Audit**
- Create audit script
- Run automated checks
- Generate report

**Day 2-3: High Priority Fixes**
- Replace CircularProgressIndicator
- Replace withOpacity
- Fix relative imports
- Remove hardcoded strings

**Day 4: Medium Priority Fixes**
- Replace inline colors
- Replace inline TextStyle
- Replace magic spacing

**Day 5: Validation**
- Run flutter analyze
- Test all screens
- Update documentation

---

## 5. Success Criteria

### Legacy Code Removal
- [ ] 0 V1 debt files
- [ ] 0 V1 goal files
- [ ] 0 `_v2` suffixes
- [ ] All imports updated
- [ ] Flutter analyze: 0 errors

### Localization Refactoring
- [ ] Feature-based structure
- [ ] Consistent naming
- [ ] 0 duplicate keys
- [ ] Both locales working
- [ ] Documentation updated

### Style Guide Compliance
- [ ] 0 CircularProgressIndicator
- [ ] 0 withOpacity
- [ ] 0 relative imports
- [ ] 0 hardcoded strings
- [ ] Compliance >95%

---

## 6. Metrics

### Before R11
- Files: 164
- LOC: ~20,400
- Locale keys: 378 (flat)
- Legacy files: ~20
- Style violations: TBD

### After R11 (Target)
- Files: ~145 (-19)
- LOC: ~19,500 (-900)
- Locale keys: 378 (grouped)
- Legacy files: 0
- Style violations: <5%

---

## 7. Risks & Mitigation

**Risk 1: Breaking Changes**
- Use IDE refactoring
- Test incrementally
- Keep git history clean

**Risk 2: Missing Translations**
- Create key inventory
- Use diff tools
- Test all screens

**Risk 3: Style Violations Reintroduced**
- Add pre-commit hooks
- Update PR template
- Regular code reviews

---

## Summary

R11 focuses on **technical debt reduction**:

1. **Remove 20+ legacy files** — Debt V1, Goal V1
2. **Refactor 378 locale keys** — Group by feature
3. **Audit & fix style violations** — 100% compliance

**Benefits:**
- Easier maintenance
- Better developer experience
- Consistent codebase
- Faster onboarding

**Timeline:** 3 weeks

**Risk:** Medium (breaking changes)

**Impact:** High (foundation for future)
