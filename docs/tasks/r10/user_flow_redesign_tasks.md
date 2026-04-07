# R10: User Flow Redesign Tasks

## Phase 1: Data Model & Migration (Week 1-2)

### Task 1: Enhanced Debt Model Design ✅ COMPLETED
**Priority**: 🔥 Critical  
**Effort**: 8 hours  
**Files**: 
- `lib/features/debt/models/debt_v2.dart` ✅
- `lib/features/debt/models/debt_payment_v2.dart` ✅

Create enhanced debt models with better user flow support:

```dart
enum DebtType { lend, borrow }
enum DebtStatus { active, completed, cancelled }

class DebtV2 {
  final String id;
  final String accountId;
  final DebtType type;
  final String partyName;
  final String? partyContact;
  final int totalAmount;
  final int paidAmount;
  final DateTime? dueDate;
  final double? interestRate;
  final String? description;
  final DebtStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  int get remainingAmount => totalAmount - paidAmount;
  bool get isCompleted => status == DebtStatus.completed || remainingAmount <= 0;
  double get progressPercentage => paidAmount / totalAmount;
}

class DebtPaymentV2 {
  final String id;
  final String debtId;
  final int amount;
  final DateTime date;
  final String? note;
  final String? transactionId;
  final String createdBy;
}
```

### Task 2: Enhanced Goal Model Design ✅ COMPLETED (except auto_saving_rule)
**Priority**: 🔥 Critical  
**Effort**: 6 hours  
**Files**:
- `lib/features/goal/models/goal_v2.dart` ✅
- `lib/features/goal/models/goal_contribution.dart` ✅
- `lib/features/goal/models/auto_saving_rule.dart` (TODO)

Create flexible goal system supporting any wallet:

```dart
enum GoalCategory { 
  vacation, emergency, purchase, education, 
  wedding, home, car, investment, other 
}

enum GoalStatus { active, paused, completed, cancelled }

class GoalV2 {
  final String id;
  final String accountId;
  final String name;
  final GoalCategory category;
  final int targetAmount;
  final int currentAmount;
  final DateTime? targetDate;
  final String fundingWalletId;
  final GoalStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  int get remainingAmount => targetAmount - currentAmount;
  double get progressPercentage => currentAmount / targetAmount;
  bool get isCompleted => currentAmount >= targetAmount;
}

class GoalContribution {
  final String id;
  final String goalId;
  final int amount;
  final DateTime date;
  final String? note;
  final String? transactionId;
  final String createdBy;
}

enum RecurrenceType { daily, weekly, monthly }

class AutoSavingRule {
  final String id;
  final String goalId;
  final int amount;
  final RecurrenceType frequency;
  final DateTime nextRunDate;
  final bool isActive;
}
```

### Task 3: Transfer Model Simplification ✅ COMPLETED
**Priority**: 🔥 Critical  
**Effort**: 4 hours  
**Files**:
- `lib/features/transfer/models/transfer_v2.dart` ✅

Simplify transfer concepts:

```dart
enum TransferType {
  internal,     // Between wallets in same account
  funding,      // Personal → Family wallet  
  crossAccount, // Between different accounts
}

enum TransferStatus { pending, completed, failed }

class TransferV2 {
  final String id;
  final TransferType type;
  final String sourceWalletId;
  final String sourceAccountId;
  final String destWalletId;
  final String? destAccountId;
  final int amount;
  final String? note;
  final DateTime date;
  final String createdBy;
  final TransferStatus status;
  
  bool get isCrossAccount => destAccountId != null && destAccountId != sourceAccountId;
  bool get isFamilyFunding => type == TransferType.funding;
}
```

### Task 4: Data Migration Scripts
**Priority**: 🔥 Critical  
**Effort**: 12 hours  
**Files**:
- `lib/core/migration/debt_migration.dart` (new)
- `lib/core/migration/goal_migration.dart` (new)
- `lib/core/migration/transfer_migration.dart` (new)

Create migration utilities:

```dart
class DebtMigration {
  static Future<void> migrateFromV1ToV2(String accountId);
  static Future<void> validateMigration(String accountId);
  static Future<void> rollbackMigration(String accountId);
}

class GoalMigration {
  static Future<void> migrateWalletGoalsToGlobalGoals(String accountId);
  static Future<void> createDefaultGoalCategories();
}

class TransferMigration {
  static Future<void> createTransferHistoryFromTransactions(String accountId);
  static Future<void> simplifyTransferTypes();
}
```

## Phase 2: Service Layer Implementation (Week 3-4)

### Task 5: Enhanced Debt Service ✅ COMPLETED
**Priority**: 🔥 Critical  
**Effort**: 10 hours  
**Files**:
- `lib/features/debt/services/debt_service_v2.dart` ✅
- `lib/features/debt/repositories/debt_repository_v2.dart` ✅

Implement user-friendly debt operations:

```dart
class DebtServiceV2 {
  // Core operations
  Future<String> lendMoney({
    required String partyName,
    required int amount,
    String? contact,
    DateTime? dueDate,
    double? interestRate,
    String? description,
  });
  
  Future<String> borrowMoney({
    required String partyName,
    required int amount,
    String? contact,
    DateTime? dueDate,
    double? interestRate,
    String? description,
  });
  
  Future<void> recordPaymentReceived(String debtId, int amount, {String? note});
  Future<void> recordPaymentMade(String debtId, int amount, {String? note});
  
  // Queries
  Future<List<DebtV2>> getLentMoney();
  Future<List<DebtV2>> getBorrowedMoney();
  Future<List<DebtV2>> getOverdueDebts();
  Stream<List<DebtV2>> watchActiveDebts();
  
  // Integration
  Future<void> linkTransactionToPayment(String paymentId, String transactionId);
  Future<void> setPaymentReminder(String debtId, DateTime reminderDate);
}
```

### Task 6: Enhanced Goal Service ✅ COMPLETED
**Priority**: 🔥 Critical  
**Effort**: 10 hours  
**Files**:
- `lib/features/goal/services/goal_service_v2.dart` ✅
- `lib/features/goal/repositories/goal_repository_v2.dart` ✅

Implement flexible goal management:

```dart
class GoalServiceV2 {
  // Core operations
  Future<String> createGoal({
    required String name,
    required GoalCategory category,
    required int targetAmount,
    required String fundingWalletId,
    DateTime? targetDate,
  });
  
  Future<void> contributeToGoal(String goalId, int amount, {String? note});
  Future<void> withdrawFromGoal(String goalId, int amount, {String? note});
  
  // Auto-saving
  Future<void> setupAutoSaving({
    required String goalId,
    required int amount,
    required RecurrenceType frequency,
  });
  
  Future<void> pauseAutoSaving(String goalId);
  Future<void> resumeAutoSaving(String goalId);
  
  // Queries
  Future<List<GoalV2>> getActiveGoals();
  Future<List<GoalV2>> getGoalsByCategory(GoalCategory category);
  Future<List<GoalV2>> getCompletedGoals();
  Stream<List<GoalV2>> watchGoalsProgress();
  
  // Analytics
  Future<GoalAnalytics> getGoalAnalytics(String goalId);
  Future<Map<GoalCategory, int>> getGoalDistribution();
}
```

### Task 7: Simplified Transfer Service ✅ COMPLETED
**Priority**: 🔥 Critical  
**Effort**: 8 hours  
**Files**:
- `lib/features/transfer/services/transfer_service_v2.dart` ✅
- `lib/features/transfer/repositories/transfer_repository_v2.dart` ✅

Implement intuitive transfer operations:

```dart
class TransferServiceV2 {
  // Internal transfers
  Future<String> transferBetweenWallets({
    required String fromWalletId,
    required String toWalletId,
    required int amount,
    String? note,
  });
  
  // Family funding
  Future<String> fundFamilyWallet({
    required String personalWalletId,
    required String familyWalletId,
    required int amount,
    String? note,
  });
  
  Future<String> fundFamilyExpense({
    required String personalWalletId,
    required String familyWalletId,
    required int amount,
    required String categoryId,
    String? note,
  });
  
  // Cross-account transfers
  Future<String> sendToFamilyMember({
    required String fromWalletId,
    required String toAccountId,
    required String toWalletId,
    required int amount,
    String? note,
  });
  
  // Queries
  Future<List<TransferV2>> getTransferHistory();
  Future<List<TransferV2>> getPendingTransfers();
  Stream<List<TransferV2>> watchRecentTransfers();
  
  // Quick actions
  Future<List<TransferShortcut>> getQuickTransferOptions();
  Future<void> saveTransferShortcut(String name, String fromWallet, String toWallet);
}
```

### Task 8: Integration Service
**Priority**: ⚠️ Medium  
**Effort**: 6 hours  
**Files**:
- `lib/features/integration/financial_integration_service.dart` (new)

Connect debt, goals, and transfers:

```dart
class FinancialIntegrationService {
  // Debt-Transaction integration
  Future<void> createTransactionFromDebtPayment(DebtPaymentV2 payment);
  Future<void> linkExistingTransactionToDebt(String transactionId, String debtId);
  
  // Goal-Transaction integration  
  Future<void> createTransactionFromGoalContribution(GoalContribution contribution);
  Future<void> autoContributeToGoals(); // Run by scheduler
  
  // Transfer-Transaction integration
  Future<void> executeTransferAsTransactions(TransferV2 transfer);
  Future<void> createTransferFromTransactions(String txnOutId, String txnInId);
  
  // Analytics integration
  Future<FinancialSummary> getFinancialOverview();
  Future<CashFlowAnalysis> getCashFlowAnalysis();
}
```

## Phase 3: UI Implementation (Week 5-6)

### Task 9: Debt Management Screens
**Priority**: 🔥 Critical  
**Effort**: 12 hours  
**Files**:
- `lib/features/debt/screens/debt_list_screen.dart` (new)
- `lib/features/debt/screens/debt_form_screen.dart` (new)
- `lib/features/debt/screens/debt_detail_screen.dart` (new)
- `lib/features/debt/screens/payment_form_screen.dart` (new)

Create intuitive debt management UI:

```dart
// Debt List Screen with tabs
class DebtListScreen extends StatefulWidget {
  // Tabs: All, Lent, Borrowed, Overdue
  // Quick actions: Add Debt, Record Payment
  // Search and filter capabilities
}

// Debt Form with clear lend/borrow selection
class DebtFormScreen extends StatefulWidget {
  // Toggle: Lend Money / Borrow Money
  // Party selection with contact integration
  // Amount, due date, interest rate
  // Description and notes
}

// Debt Detail with payment history
class DebtDetailScreen extends StatefulWidget {
  // Progress indicator
  // Payment history timeline
  // Quick payment actions
  // Reminder settings
}
```

### Task 10: Goal Management Screens
**Priority**: 🔥 Critical  
**Effort**: 12 hours  
**Files**:
- `lib/features/goal/screens/goal_list_screen.dart` (new)
- `lib/features/goal/screens/goal_form_screen.dart` (new)
- `lib/features/goal/screens/goal_detail_screen.dart` (new)
- `lib/features/goal/screens/goal_contribution_screen.dart` (new)

Create engaging goal tracking UI:

```dart
// Goal List with visual progress
class GoalListScreen extends StatefulWidget {
  // Grid/List view toggle
  // Category filtering
  // Progress visualization
  // Quick contribute actions
}

// Goal Form with category selection
class GoalFormScreen extends StatefulWidget {
  // Goal category picker
  // Target amount and date
  // Funding wallet selection
  // Auto-saving setup
}

// Goal Detail with progress tracking
class GoalDetailScreen extends StatefulWidget {
  // Visual progress indicator
  // Contribution history
  // Auto-saving settings
  // Achievement milestones
}
```

### Task 11: Transfer & Funding Screens
**Priority**: 🔥 Critical  
**Effort**: 10 hours  
**Files**:
- `lib/features/transfer/screens/transfer_screen.dart` (new)
- `lib/features/transfer/screens/transfer_history_screen.dart` (new)
- `lib/features/transfer/widgets/transfer_type_selector.dart` (new)

Create simplified transfer UI:

```dart
// Transfer Screen with type selection
class TransferScreen extends StatefulWidget {
  // Transfer type selector (Internal, Family Funding, Cross-Account)
  // Wallet pickers based on type
  // Amount input with balance validation
  // Quick transfer shortcuts
}

// Transfer History with categorization
class TransferHistoryScreen extends StatefulWidget {
  // Categorized by transfer type
  // Search and filter
  // Transfer status tracking
  // Retry failed transfers
}
```

### Task 12: Navigation & Integration Updates
**Priority**: ⚠️ Medium  
**Effort**: 8 hours  
**Files**:
- `lib/features/main_shell.dart` (update)
- `lib/features/home/screens/home_screen.dart` (update)
- `lib/common/widgets/quick_actions_fab.dart` (new)

Update navigation structure:

```dart
// Main Shell with new tabs
class MainShell extends StatefulWidget {
  // Bottom nav: Home, Transactions, Debts, Goals, More
  // Context-aware FAB menu
}

// Enhanced Home Screen
class HomeScreen extends StatefulWidget {
  // Financial overview dashboard
  // Active goals progress
  // Outstanding debts summary
  // Quick action shortcuts
}

// Quick Actions FAB
class QuickActionsFab extends StatefulWidget {
  // Add Transaction
  // Transfer Money
  // Add to Goal
  // Record Payment
}
```

## Phase 4: Integration & Testing (Week 7-8)

### Task 13: End-to-End Integration
**Priority**: 🔥 Critical  
**Effort**: 10 hours  
**Files**: All service and screen files

Integrate all components:
- Service layer connections
- Data flow validation
- Error handling
- Performance optimization

### Task 14: Migration Testing
**Priority**: 🔥 Critical  
**Effort**: 8 hours  
**Files**: Migration scripts and test files

Validate data migration:
- Migration script testing
- Data integrity validation
- Rollback procedures
- Performance impact assessment

### Task 15: User Flow Testing
**Priority**: ⚠️ Medium  
**Effort**: 6 hours  
**Files**: Test files and documentation

Test complete user journeys:
- Debt management workflows
- Goal setting and tracking
- Transfer operations
- Cross-feature integration

### Task 16: Performance Optimization
**Priority**: ⚠️ Medium  
**Effort**: 4 hours  
**Files**: Service and repository files

Optimize for performance:
- Query optimization
- Cache integration
- Listener management
- Memory usage optimization

## Implementation Guidelines

### Code Quality Standards
- Follow existing architecture patterns
- Maintain backward compatibility during transition
- Use comprehensive error handling
- Implement proper logging and monitoring

### Testing Requirements
- Unit tests for all service methods
- Integration tests for user flows
- Migration validation tests
- Performance benchmarks

### Documentation Standards
- API documentation for all public methods
- User flow documentation
- Migration guides
- Troubleshooting guides

## Success Criteria

### Functional Requirements
- ✅ All debt operations work intuitively
- ✅ Goals can be created for any wallet
- ✅ Transfers are simplified and clear
- ✅ Data migration is successful and reversible

### Performance Requirements
- ✅ Screen load times < 2 seconds
- ✅ Migration completes in < 5 minutes
- ✅ No data loss during migration
- ✅ Memory usage remains stable

### User Experience Requirements
- ✅ Reduced clicks for common operations
- ✅ Clear visual feedback for all actions
- ✅ Intuitive navigation between features
- ✅ Consistent design language

This comprehensive redesign transforms complex financial concepts into user-friendly workflows while maintaining technical excellence and data integrity.