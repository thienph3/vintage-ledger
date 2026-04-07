# R11: Code Cleanup & Style Guide Compliance — Implementation Tasks

> Detailed task breakdown for legacy code removal, localization refactoring, and style guide audit

---

## Overview

**Timeline:** 3 weeks
**Estimated Effort:** 60-80 hours
**Risk Level:** Medium (breaking changes, but well-planned)

---

## Week 1: Legacy Code Removal

### Task 1.1: Debt V1 Removal (Day 1-2, 8 hours)

**Objective:** Remove old debt system, rename V2 files

**Subtasks:**

#### 1.1.1 Backup & Preparation
- [ ] Create feature branch `feature/r11-debt-cleanup`
- [ ] Document all files to be removed
- [ ] Search for all references to old debt files
- [ ] Create rollback plan

#### 1.1.2 Remove Old Files
- [ ] Delete `lib/features/debt/models/debt.dart`
- [ ] Delete `lib/features/debt/models/payment.dart`
- [ ] Delete `lib/features/debt/repositories/debt_repository.dart`
- [ ] Delete `lib/features/debt/services/debt_service.dart`
- [ ] Delete `lib/features/debt/screens/debt_list_screen.dart`
- [ ] Delete `lib/features/debt/screens/debt_form_screen.dart`
- [ ] Delete `lib/features/debt/screens/debt_detail_screen.dart`
- [ ] Delete `lib/features/debt/widgets/debt_progress_bar.dart`
- [ ] Delete `lib/features/debt/widgets/debt_summary_card.dart`

#### 1.1.3 Rename V2 Files
- [ ] Rename `debt_v2.dart` → `debt.dart`
- [ ] Rename `debt_payment_v2.dart` → `debt_payment.dart`
- [ ] Rename `debt_repository_v2.dart` → `debt_repository.dart`
- [ ] Rename `debt_service_v2.dart` → `debt_service.dart`
- [ ] Rename `debt_list_screen_v2.dart` → `debt_list_screen.dart`
- [ ] Rename `debt_form_screen_v2.dart` → `debt_form_screen.dart`
- [ ] Rename `debt_detail_screen_v2.dart` → `debt_detail_screen.dart`

#### 1.1.4 Update Imports
- [ ] Update imports in `service_locator.dart`
- [ ] Update imports in `settings_screen.dart`
- [ ] Update imports in `home_screen.dart`
- [ ] Update imports in `quick_actions_fab.dart`
- [ ] Update imports in `debt_payment_screen.dart`
- [ ] Search and replace all `debt_v2` references
- [ ] Search and replace all `DebtV2` class references

#### 1.1.5 Update Class Names
- [ ] Rename `DebtV2` → `Debt`
- [ ] Rename `DebtPaymentV2` → `DebtPayment`
- [ ] Rename `DebtRepositoryV2` → `DebtRepository`
- [ ] Rename `DebtServiceV2` → `DebtService`
- [ ] Update all references in code

#### 1.1.6 Testing
- [ ] Run `flutter analyze`
- [ ] Fix all analyzer errors
- [ ] Test debt list screen
- [ ] Test debt form screen (create lend)
- [ ] Test debt form screen (create borrow)
- [ ] Test debt detail screen
- [ ] Test debt payment recording
- [ ] Test debt deletion
- [ ] Test debt summary widget on home

#### 1.1.7 Documentation
- [ ] Update README.md (remove V2 references)
- [ ] Update summary_r10.md
- [ ] Add migration notes to CHANGELOG.md

**Acceptance Criteria:**
- ✅ 0 old debt files remaining
- ✅ 0 `_v2` suffixes in debt feature
- ✅ All debt functionality working
- ✅ Flutter analyze: 0 errors

---

### Task 1.2: Goal V1 Removal (Day 3-4, 8 hours)

**Objective:** Remove wallet-based goal system, rename V2 files

**Subtasks:**

#### 1.2.1 Backup & Preparation
- [ ] Create feature branch `feature/r11-goal-cleanup`
- [ ] Document all files to be removed
- [ ] Search for all references to old goal files
- [ ] Create rollback plan

#### 1.2.2 Remove Old Files (Wallet-based Goals)
- [ ] Delete `lib/features/wallet/models/wallet_goal.dart`
- [ ] Delete `lib/features/wallet/repositories/goal_repository.dart`
- [ ] Delete `lib/features/wallet/services/goal_service.dart`
- [ ] Delete `lib/features/wallet/screens/goal_form_screen.dart`
- [ ] Delete `lib/features/wallet/widgets/goal_progress_bar.dart`

#### 1.2.3 Rename V2 Files
- [ ] Rename `goal_v2.dart` → `goal.dart`
- [ ] Rename `goal_repository_v2.dart` → `goal_repository.dart`
- [ ] Rename `goal_service_v2.dart` → `goal_service.dart`

#### 1.2.4 Update Imports
- [ ] Update imports in `service_locator.dart`
- [ ] Update imports in `settings_screen.dart`
- [ ] Update imports in `home_screen.dart`
- [ ] Update imports in `quick_actions_fab.dart`
- [ ] Update imports in `goal_contribution_screen.dart`
- [ ] Update imports in `goal_list_screen.dart`
- [ ] Update imports in `goal_form_screen.dart`
- [ ] Update imports in `goal_detail_screen.dart`
- [ ] Search and replace all `goal_v2` references
- [ ] Search and replace all `GoalV2` class references

#### 1.2.5 Update Class Names
- [ ] Rename `GoalV2` → `Goal`
- [ ] Rename `GoalRepositoryV2` → `GoalRepository`
- [ ] Rename `GoalServiceV2` → `GoalService`
- [ ] Update all references in code

#### 1.2.6 Testing
- [ ] Run `flutter analyze`
- [ ] Fix all analyzer errors
- [ ] Test goal list screen
- [ ] Test goal form screen (all 9 categories)
- [ ] Test goal detail screen
- [ ] Test goal contribution
- [ ] Test goal withdrawal
- [ ] Test auto-saving setup
- [ ] Test goal deletion
- [ ] Test goal summary widget on home

#### 1.2.7 Documentation
- [ ] Update README.md
- [ ] Update summary_r10.md
- [ ] Add migration notes to CHANGELOG.md

**Acceptance Criteria:**
- ✅ 0 wallet-based goal files remaining
- ✅ 0 `_v2` suffixes in goal feature
- ✅ All goal functionality working
- ✅ Flutter analyze: 0 errors

---

### Task 1.3: Transfer V2 Cleanup (Day 5, 4 hours)

**Objective:** Rename transfer V2 files, remove duplicates

**Subtasks:**

#### 1.3.1 Rename V2 Files
- [ ] Rename `transfer_v2.dart` → `transfer.dart`
- [ ] Rename `transfer_repository_v2.dart` → `transfer_repository.dart`
- [ ] Rename `transfer_service_v2.dart` → `transfer_service.dart`

#### 1.3.2 Update Imports
- [ ] Update imports in `service_locator.dart`
- [ ] Update imports in `transfer_screen.dart`
- [ ] Update imports in `quick_actions_fab.dart`
- [ ] Search and replace all `transfer_v2` references
- [ ] Search and replace all `TransferV2` class references

#### 1.3.3 Update Class Names
- [ ] Rename `TransferV2` → `Transfer`
- [ ] Rename `TransferRepositoryV2` → `TransferRepository`
- [ ] Rename `TransferServiceV2` → `TransferService`
- [ ] Update all references in code

#### 1.3.4 Testing
- [ ] Run `flutter analyze`
- [ ] Test transfer screen (internal)
- [ ] Test transfer screen (funding)
- [ ] Test transfer shortcuts

**Acceptance Criteria:**
- ✅ 0 `_v2` suffixes in transfer feature
- ✅ All transfer functionality working

---

### Task 1.4: Misc Cleanup (Day 5, 4 hours)

**Objective:** Remove duplicate widgets, unused files

**Subtasks:**

#### 1.4.1 Audit Duplicate Widgets
- [ ] Check for duplicate progress bars
- [ ] Check for duplicate summary cards
- [ ] Check for unused empty state components
- [ ] Check for deprecated chart widgets

#### 1.4.2 Remove Duplicates
- [ ] Remove identified duplicates
- [ ] Update imports if needed

#### 1.4.3 Final Validation
- [ ] Run `flutter analyze`
- [ ] Fix all errors
- [ ] Run `flutter test` (if tests exist)
- [ ] Manual smoke test all features

#### 1.4.4 Git Cleanup
- [ ] Merge all cleanup branches to `develop`
- [ ] Create PR with detailed changelog
- [ ] Code review
- [ ] Merge to `main`

**Acceptance Criteria:**
- ✅ 0 duplicate widgets
- ✅ 0 unused files
- ✅ Flutter analyze: 0 errors
- ✅ All tests passing

---

## Week 2: Localization Refactoring

### Task 2.1: Vietnamese Locale Structure (Day 1-2, 10 hours)

**Objective:** Create feature-based structure for Vietnamese locale

**Subtasks:**

#### 2.1.1 Create Directory Structure
- [ ] Create `lib/core/l10n/vi/` directory
- [ ] Create `common.dart`
- [ ] Create `home.dart`
- [ ] Create `wallet.dart`
- [ ] Create `transaction.dart`
- [ ] Create `category.dart`
- [ ] Create `budget.dart`
- [ ] Create `debt.dart`
- [ ] Create `goal.dart`
- [ ] Create `transfer.dart`
- [ ] Create `insights.dart`
- [ ] Create `settings.dart`
- [ ] Create `auth.dart`
- [ ] Create `account.dart`
- [ ] Create `recurring.dart`

#### 2.1.2 Move Keys: Common (30 keys)
- [ ] Copy common keys from `app_vi.dart`
- [ ] Paste into `vi/common.dart`
- [ ] Format as `const Map<String, String> commonVi = {...}`
- [ ] Verify all keys present

#### 2.1.3 Move Keys: Home (10 keys)
- [ ] Copy home keys from `app_vi.dart`
- [ ] Paste into `vi/home.dart`
- [ ] Format as `const Map<String, String> homeVi = {...}`

#### 2.1.4 Move Keys: Wallet (20 keys)
- [ ] Copy wallet keys from `app_vi.dart`
- [ ] Paste into `vi/wallet.dart`
- [ ] Format as `const Map<String, String> walletVi = {...}`

#### 2.1.5 Move Keys: Transaction (50 keys)
- [ ] Copy transaction keys from `app_vi.dart`
- [ ] Paste into `vi/transaction.dart`
- [ ] Format as `const Map<String, String> transactionVi = {...}`

#### 2.1.6 Move Keys: Category (15 keys)
- [ ] Copy category keys from `app_vi.dart`
- [ ] Paste into `vi/category.dart`
- [ ] Format as `const Map<String, String> categoryVi = {...}`

#### 2.1.7 Move Keys: Budget (20 keys)
- [ ] Copy budget keys from `app_vi.dart`
- [ ] Paste into `vi/budget.dart`
- [ ] Format as `const Map<String, String> budgetVi = {...}`

#### 2.1.8 Move Keys: Debt (40 keys)
- [ ] Copy debt keys from `app_vi.dart`
- [ ] Remove V1 duplicate keys
- [ ] Paste into `vi/debt.dart`
- [ ] Format as `const Map<String, String> debtVi = {...}`

#### 2.1.9 Move Keys: Goal (45 keys)
- [ ] Copy goal keys from `app_vi.dart`
- [ ] Remove V1 duplicate keys
- [ ] Paste into `vi/goal.dart`
- [ ] Format as `const Map<String, String> goalVi = {...}`

#### 2.1.10 Move Keys: Transfer (20 keys)
- [ ] Copy transfer keys from `app_vi.dart`
- [ ] Paste into `vi/transfer.dart`
- [ ] Format as `const Map<String, String> transferVi = {...}`

#### 2.1.11 Move Keys: Insights (25 keys)
- [ ] Copy insights keys from `app_vi.dart`
- [ ] Paste into `vi/insights.dart`
- [ ] Format as `const Map<String, String> insightsVi = {...}`

#### 2.1.12 Move Keys: Settings (15 keys)
- [ ] Copy settings keys from `app_vi.dart`
- [ ] Paste into `vi/settings.dart`
- [ ] Format as `const Map<String, String> settingsVi = {...}`

#### 2.1.13 Move Keys: Auth (25 keys)
- [ ] Copy auth keys from `app_vi.dart`
- [ ] Paste into `vi/auth.dart`
- [ ] Format as `const Map<String, String> authVi = {...}`

#### 2.1.14 Move Keys: Account (40 keys)
- [ ] Copy account keys from `app_vi.dart`
- [ ] Paste into `vi/account.dart`
- [ ] Format as `const Map<String, String> accountVi = {...}`

#### 2.1.15 Move Keys: Recurring (15 keys)
- [ ] Copy recurring keys from `app_vi.dart`
- [ ] Paste into `vi/recurring.dart`
- [ ] Format as `const Map<String, String> recurringVi = {...}`

#### 2.1.16 Update Main File
- [ ] Update `app_vi.dart` to import all feature files
- [ ] Merge all maps: `const Map<String, String> vi = {...commonVi, ...homeVi, ...}`
- [ ] Verify total key count matches (378 keys)

#### 2.1.17 Testing
- [ ] Run app with Vietnamese locale
- [ ] Test all screens for missing keys
- [ ] Check console for missing key warnings
- [ ] Fix any issues

**Acceptance Criteria:**
- ✅ 14 feature files created
- ✅ All 378 keys moved
- ✅ Vietnamese locale working
- ✅ No missing key warnings

---

### Task 2.2: English Locale Structure (Day 3-4, 10 hours)

**Objective:** Create feature-based structure for English locale

**Subtasks:**

#### 2.2.1 Create Directory Structure
- [ ] Create `lib/core/l10n/en/` directory
- [ ] Create same 14 files as Vietnamese

#### 2.2.2 Move Keys: All Features
- [ ] Repeat Task 2.1.2 - 2.1.15 for English
- [ ] Copy keys from `app_en.dart`
- [ ] Paste into corresponding `en/*.dart` files
- [ ] Format as `const Map<String, String> {feature}En = {...}`

#### 2.2.3 Update Main File
- [ ] Update `app_en.dart` to import all feature files
- [ ] Merge all maps
- [ ] Verify total key count matches (378 keys)

#### 2.2.4 Testing
- [ ] Run app with English locale
- [ ] Test all screens for missing keys
- [ ] Check console for missing key warnings
- [ ] Fix any issues

**Acceptance Criteria:**
- ✅ 14 feature files created
- ✅ All 378 keys moved
- ✅ English locale working
- ✅ No missing key warnings

---

### Task 2.3: Cleanup & Validation (Day 5, 8 hours)

**Objective:** Remove duplicates, standardize naming, validate

**Subtasks:**

#### 2.3.1 Remove Duplicate Keys
- [ ] Identify V1 vs V2 duplicate keys
- [ ] Remove old V1 keys (debt, goal)
- [ ] Update key count in both locales
- [ ] Verify consistency between vi and en

#### 2.3.2 Standardize Naming
- [ ] Audit all key names
- [ ] Fix inconsistent naming (camelCase)
- [ ] Update references in code if needed
- [ ] Document naming convention

#### 2.3.3 Add Missing Keys
- [ ] Check for missing translations
- [ ] Add missing keys to both locales
- [ ] Verify completeness

#### 2.3.4 Full Testing
- [ ] Test all screens in Vietnamese
- [ ] Test all screens in English
- [ ] Test locale switching
- [ ] Test all empty states
- [ ] Test all error messages
- [ ] Test all button labels

#### 2.3.5 Documentation
- [ ] Create `docs/localization_guide.md`
- [ ] Document new structure
- [ ] Document naming convention
- [ ] Add examples for adding new keys
- [ ] Update README.md

#### 2.3.6 Git Commit
- [ ] Commit all locale changes
- [ ] Create PR with detailed changelog
- [ ] Code review
- [ ] Merge to `main`

**Acceptance Criteria:**
- ✅ 0 duplicate keys
- ✅ Consistent naming
- ✅ Both locales working
- ✅ Documentation complete

---

## Week 3: Style Guide Audit

### Task 3.1: Automated Audit (Day 1, 4 hours)

**Objective:** Create audit script, run checks, generate report

**Subtasks:**

#### 3.1.1 Create Audit Script
- [ ] Create `scripts/style_audit.sh`
- [ ] Add check for inline colors
- [ ] Add check for inline TextStyle
- [ ] Add check for magic spacing
- [ ] Add check for hardcoded strings
- [ ] Add check for relative imports
- [ ] Add check for CircularProgressIndicator
- [ ] Add check for deprecated withOpacity
- [ ] Make script executable: `chmod +x scripts/style_audit.sh`

#### 3.1.2 Run Audit
- [ ] Run `./scripts/style_audit.sh`
- [ ] Save output to `docs/style_audit_report.md`
- [ ] Analyze results
- [ ] Prioritize fixes

#### 3.1.3 Generate Detailed Report
- [ ] List all violations by file
- [ ] Group by violation type
- [ ] Estimate fix effort
- [ ] Create fix plan

**Acceptance Criteria:**
- ✅ Audit script created
- ✅ Audit report generated
- ✅ Fix plan documented

---

### Task 3.2: High Priority Fixes (Day 2-3, 12 hours)

**Objective:** Fix critical style violations

**Subtasks:**

#### 3.2.1 Replace CircularProgressIndicator
- [ ] Search for all `CircularProgressIndicator` usage
- [ ] Replace with `ShimmerPlaceholder`
- [ ] Update imports
- [ ] Test loading states

**Files to check:**
- [ ] All list screens
- [ ] All form screens
- [ ] All detail screens
- [ ] Bootstrap screen

#### 3.2.2 Replace withOpacity
- [ ] Search for all `.withOpacity(` usage
- [ ] Replace with `.withValues(alpha: value)`
- [ ] Test visual appearance

**Files to check:**
- [ ] All screens with semi-transparent colors
- [ ] All widgets with opacity

#### 3.2.3 Fix Relative Imports
- [ ] Search for all `import '../` or `import '../../`
- [ ] Replace with `package:vintage_ledger/...`
- [ ] Run `flutter analyze`
- [ ] Fix any errors

**Files to check:**
- [ ] All feature files
- [ ] All common widgets
- [ ] All core files

#### 3.2.4 Remove Hardcoded Strings
- [ ] Search for `Text('` without `S.of`
- [ ] Add missing keys to locale files
- [ ] Replace hardcoded strings with `S.of(context, 'key')`
- [ ] Test all screens

**Files to check:**
- [ ] All screens
- [ ] All widgets
- [ ] All dialogs

#### 3.2.5 Testing
- [ ] Run `flutter analyze`
- [ ] Fix all errors
- [ ] Test all affected screens
- [ ] Verify visual consistency

**Acceptance Criteria:**
- ✅ 0 CircularProgressIndicator
- ✅ 0 withOpacity usage
- ✅ 0 relative imports
- ✅ 0 hardcoded strings

---

### Task 3.3: Medium Priority Fixes (Day 4, 6 hours)

**Objective:** Fix styling violations

**Subtasks:**

#### 3.3.1 Replace Inline Colors
- [ ] Search for `Color(0xFF...)`
- [ ] Search for `Colors.red`, `Colors.blue`, etc.
- [ ] Replace with `AppColors.*`
- [ ] Test visual appearance

#### 3.3.2 Replace Inline TextStyle
- [ ] Search for `TextStyle(` without `copyWith`
- [ ] Replace with `AppTextStyles.*`
- [ ] Use `.copyWith()` for modifications
- [ ] Test typography

#### 3.3.3 Replace Magic Spacing
- [ ] Search for `EdgeInsets.all(16)`
- [ ] Search for `SizedBox(height: 8)`
- [ ] Replace with `AppSpacing.*`
- [ ] Test layouts

#### 3.3.4 Testing
- [ ] Run `flutter analyze`
- [ ] Test visual consistency
- [ ] Check spacing on all screens

**Acceptance Criteria:**
- ✅ <10 inline colors
- ✅ <10 inline TextStyle
- ✅ <10 magic spacing numbers

---

### Task 3.4: Validation & Documentation (Day 5, 6 hours)

**Objective:** Final validation, update documentation

**Subtasks:**

#### 3.4.1 Final Audit
- [ ] Run `./scripts/style_audit.sh` again
- [ ] Compare with initial report
- [ ] Verify improvements
- [ ] Document remaining violations (if any)

#### 3.4.2 Flutter Analyze
- [ ] Run `flutter analyze`
- [ ] Fix all errors
- [ ] Fix all warnings (if possible)
- [ ] Document any remaining warnings

#### 3.4.3 Manual Testing
- [ ] Test all screens
- [ ] Test all features
- [ ] Test both locales
- [ ] Test all loading states
- [ ] Test all empty states
- [ ] Test all error states

#### 3.4.4 Update Documentation
- [ ] Update `docs/style_guides/design.md`
- [ ] Update `docs/style_guides/coding.md`
- [ ] Create `docs/style_audit_report.md`
- [ ] Update README.md
- [ ] Create CHANGELOG.md entry

#### 3.4.5 Create Compliance Checklist
- [ ] Create PR template with style checklist
- [ ] Add pre-commit hook (optional)
- [ ] Document review process

#### 3.4.6 Git Commit
- [ ] Commit all style fixes
- [ ] Create PR with detailed changelog
- [ ] Code review
- [ ] Merge to `main`

**Acceptance Criteria:**
- ✅ Style compliance >95%
- ✅ Flutter analyze: 0 errors
- ✅ All tests passing
- ✅ Documentation updated

---

## Summary Checklist

### Week 1: Legacy Code Removal
- [ ] Task 1.1: Debt V1 Removal (8h)
- [ ] Task 1.2: Goal V1 Removal (8h)
- [ ] Task 1.3: Transfer V2 Cleanup (4h)
- [ ] Task 1.4: Misc Cleanup (4h)
- **Total:** 24 hours

### Week 2: Localization Refactoring
- [ ] Task 2.1: Vietnamese Locale Structure (10h)
- [ ] Task 2.2: English Locale Structure (10h)
- [ ] Task 2.3: Cleanup & Validation (8h)
- **Total:** 28 hours

### Week 3: Style Guide Audit
- [ ] Task 3.1: Automated Audit (4h)
- [ ] Task 3.2: High Priority Fixes (12h)
- [ ] Task 3.3: Medium Priority Fixes (6h)
- [ ] Task 3.4: Validation & Documentation (6h)
- **Total:** 28 hours

### Grand Total: 80 hours (3 weeks)

---

## Success Metrics

### Before R11
- Files: 164
- LOC: ~20,400
- Locale keys: 378 (flat structure)
- Legacy files: ~20
- Style violations: TBD

### After R11 (Target)
- Files: ~145 (-19 files)
- LOC: ~19,500 (-900 lines)
- Locale keys: 378 (grouped by feature)
- Legacy files: 0
- Style violations: <5%

### Quality Gates
- ✅ Flutter analyze: 0 errors
- ✅ All tests passing
- ✅ Both locales working
- ✅ All features functional
- ✅ Documentation complete
- ✅ Code review approved

---

## Notes

**Breaking Changes:**
- File renames will break imports (use IDE refactoring)
- Class renames will break references (use find & replace)
- Locale structure change is non-breaking (internal only)

**Testing Strategy:**
- Test after each major change
- Use git branches for isolation
- Keep rollback plan ready

**Communication:**
- Update team on progress daily
- Document all breaking changes
- Create detailed PR descriptions

**Risk Mitigation:**
- Incremental changes (week by week)
- Thorough testing at each step
- Code review before merge
- Keep git history clean for rollback
