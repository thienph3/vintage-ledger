# R10: User Flow Redesign - Debt, Goals & Transfers

## Overview

Redesign core financial concepts to provide intuitive user flows for debt management, goal setting, and money transfers. This refactors existing scattered features into cohesive, user-centric workflows that follow the vintage ledger design principles.

## Current State Analysis

### 🔍 Current Issues

1. **Debt Management** (in Settings)
   - Hidden in settings menu
   - Disconnected from main financial flow
   - Limited visibility and tracking
   - No integration with transactions

2. **Goals** (in Saving Wallets only)
   - Restricted to saving wallet type
   - No flexible goal categories
   - Limited progress tracking
   - No automated savings features

3. **Transfers** (Complex transaction types)
   - Confusing transfer_out/transfer_in concepts
   - No clear distinction between internal transfers vs funding
   - Complex cross-account transfer logic
   - Poor user experience for simple operations

## New User Flow Design

### 1. 💰 Debt Management Flow

**User Journey**: "Tôi muốn theo dõi tiền cho vay/vay mượn"

```
Main Screen → Debt Tab → 
├── View All Debts (Cho vay/Vay mượn)
├── Add New Debt
│   ├── Cho vay (Tôi cho ai đó vay tiền)
│   └── Vay mượn (Ai đó cho tôi vay tiền)
├── Record Payment
│   ├── Nhận tiền trả (cho tiền đã cho vay)
│   └── Trả nợ (cho tiền đã vay)
└── Debt Details
    ├── Lịch sử thanh toán
    ├── Số tiền còn lại
    └── Nhắc nhở
```

**Key Features**:
- Clear lend vs borrow distinction with Vietnamese terminology
- Story format integration: "Minh trả nợ 500k 💰"
- Payment reminders with casual tone
- Contact integration for parties
- Interest calculation support

### 2. 🎯 Goal Management Flow

**User Journey**: "Tôi muốn tiết kiệm cho mục đích cụ thể"

```
Main Screen → Goals Tab →
├── Xem tất cả mục tiêu
├── Tạo mục tiêu mới
│   ├── Loại mục tiêu (Du lịch, Khẩn cấp, Mua sắm, etc.)
│   ├── Số tiền & ngày mục tiêu
│   └── Nguồn tiền (ví nào)
├── Tiết kiệm cho mục tiêu
│   ├── Nạp một lần
│   ├── Tiết kiệm định kỳ
│   └── Quy tắc tự động
└── Chi tiết mục tiêu
    ├── Theo dõi tiến độ
    ├── Lịch sử tiết kiệm
    └── Điều chỉnh mục tiêu
```

**Key Features**:
- Multiple goal categories with emoji
- Flexible funding from any wallet
- Visual progress tracking with soft colors
- Automated savings rules
- Goal achievement celebrations with casual tone

### 3. 💸 Transfer & Funding Flow

**User Journey**: "Tôi muốn chuyển tiền giữa các ví"

```
Chuyển tiền →
├── Chuyển nội bộ
│   ├── Giữa các ví của tôi (cùng tài khoản)
│   └── Phím tắt chuyển tiền
├── Nạp tiền gia đình
│   ├── Nạp vào ví gia đình (cá nhân → gia đình)
│   ├── Nạp trực tiếp cho chi tiêu
│   └── Yêu cầu nạp tiền gia đình
└── Chuyển liên tài khoản
    ├── Gửi cho thành viên khác
    └── Nhận từ tài khoản khác
```

**Key Features**:
- Simplified transfer categories with Vietnamese labels
- One-step family funding
- Story format: "Minh nạp 1tr vào ví gia đình 💰"
- Transfer history with casual descriptions
- Quick action shortcuts

## Technical Architecture

### 1. Data Model Redesign

#### Debt Model Enhancement
```dart
class DebtV2 {
  String id;
  String accountId;
  DebtType type; // lend, borrow
  String partyName;
  String? partyContact;
  int totalAmount;
  int paidAmount;
  DateTime? dueDate;
  double? interestRate;
  String? description;
  DebtStatus status; // active, completed, cancelled
  DateTime createdAt;
  DateTime updatedAt;
  
  // Computed properties for story format
  String get displayTitle => type == DebtType.lend 
    ? 'Cho vay $partyName' 
    : 'Vay từ $partyName';
}

class DebtPaymentV2 {
  String id;
  String debtId;
  int amount;
  DateTime date;
  String? note;
  String? transactionId; // Link to actual transaction
  String createdBy;
}
```

#### Goal Model Enhancement
```dart
class GoalV2 {
  String id;
  String accountId;
  String name;
  GoalCategory category; // vacation, emergency, purchase, etc.
  int targetAmount;
  int currentAmount;
  DateTime? targetDate;
  String fundingWalletId; // Can be any wallet now
  GoalStatus status; // active, paused, completed, cancelled
  DateTime createdAt;
  DateTime updatedAt;
  
  // Display with emoji
  String get displayTitle => '${category.emoji} $name';
}

class GoalContribution {
  String id;
  String goalId;
  int amount;
  DateTime date;
  String? note;
  String? transactionId; // Link to actual transaction
  String createdBy;
}

class AutoSavingRule {
  String id;
  String goalId;
  int amount;
  RecurrenceType frequency; // daily, weekly, monthly
  DateTime nextRunDate;
  bool isActive;
}
```

#### Transfer Model Simplification
```dart
enum TransferType {
  internal,     // Giữa các ví trong cùng tài khoản
  funding,      // Cá nhân → Ví gia đình
  crossAccount, // Giữa các tài khoản khác nhau
}

class TransferV2 {
  String id;
  TransferType type;
  String sourceWalletId;
  String sourceAccountId;
  String destWalletId;
  String? destAccountId;
  int amount;
  String? note;
  DateTime date;
  String createdBy;
  TransferStatus status; // pending, completed, failed
  
  // Story format display
  String get storyText => _generateStoryText();
}
```

### 2. Service Layer Redesign

Following the Repository → Service → Screen pattern:

#### DebtServiceV2
```dart
class DebtServiceV2 {
  final DebtRepositoryV2 _repo = DebtRepositoryV2();
  
  // Core operations with Vietnamese terminology
  Future<String> choVay({required String partyName, required int amount, ...});
  Future<String> vayMuon({required String partyName, required int amount, ...});
  Future<void> nhanTienTra(String debtId, int amount, {String? note});
  Future<void> traNop(String debtId, int amount, {String? note});
  
  // Story format integration
  Future<void> createStoryFromPayment(DebtPaymentV2 payment);
  
  // Queries following cache vs fetch pattern
  Future<List<DebtV2>> getTienChoVay();
  Future<List<DebtV2>> getTienVayMuon();
  Stream<List<DebtV2>> watchActiveDebts();
}
```

#### GoalServiceV2
```dart
class GoalServiceV2 {
  final GoalRepositoryV2 _repo = GoalRepositoryV2();
  
  // Core operations
  Future<String> taoMucTieu({required String name, required GoalCategory category, ...});
  Future<void> napVaoMucTieu(String goalId, int amount, {String? note});
  Future<void> rutTuMucTieu(String goalId, int amount, {String? note});
  
  // Auto-saving with casual language
  Future<void> thietLapTietKiemTuDong({required String goalId, ...});
  
  // Progress tracking
  Stream<List<GoalV2>> watchActiveGoals();
  Future<List<GoalV2>> getGoalsByCategory(GoalCategory category);
}
```

#### TransferServiceV2
```dart
class TransferServiceV2 {
  final TransferRepositoryV2 _repo = TransferRepositoryV2();
  
  // Simplified operations with Vietnamese names
  Future<String> chuyenGiuaCacVi({required String fromWallet, required String toWallet, ...});
  Future<String> napVaoViGiaDinh({required String personalWallet, required String familyWallet, ...});
  Future<String> napChoChiTieu({required String personalWallet, required String familyWallet, 
                               required String categoryId, ...});
  
  // Story integration
  Future<void> createStoryFromTransfer(TransferV2 transfer);
  
  // History
  Future<List<TransferV2>> getLichSuChuyenTien();
  Stream<List<TransferV2>> watchRecentTransfers();
}
```

## UI/UX Redesign (Following Design Style Guide)

### 1. Navigation Structure
```
Bottom Navigation (following current pattern):
├── Trang chủ (Home)
├── Giao dịch (Transactions) 
├── Nợ (Debts) - New tab
├── Mục tiêu (Goals) - New tab
└── Thêm (More)
```

### 2. Screen Patterns (Following Style Guide)

#### Debt List Screen
```dart
AppScaffold(
  title: 'NỢ', // UPPERCASE following l10n pattern
  body: Column(
    children: [
      // Filter row with InlineSelector
      Row([
        InlineSelector(label: 'Tất cả', icon: Icons.all_inclusive),
        InlineSelector(label: 'Cho vay', icon: Icons.trending_up),
        InlineSelector(label: 'Vay mượn', icon: Icons.trending_down),
      ]),
      // List with SwipeListItem
      Expanded(
        child: RefreshIndicator(
          child: ListView.builder(
            itemBuilder: (context, index) => SwipeListItem(
              child: LedgerCard(
                child: DebtTile(debt: debts[index]),
              ),
            ),
          ),
        ),
      ),
      // Add button
      ElevatedButton.icon(
        icon: Icon(Icons.add),
        label: Text('Thêm khoản nợ'),
        onPressed: () => _showDebtForm(),
      ),
    ],
  ),
)
```

#### Goal List Screen
```dart
AppScaffold(
  title: 'MỤC TIÊU',
  body: Column(
    children: [
      // Progress summary card
      LedgerCard(
        child: GoalSummaryWidget(),
      ),
      // Category filters
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: GoalCategory.values.map((cat) => 
            FilterChip(
              avatar: Text(cat.emoji),
              label: Text(cat.displayName),
              selected: _selectedCategory == cat,
            ),
          ).toList(),
        ),
      ),
      // Goals grid/list
      Expanded(
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) => GoalCard(goal: goals[index]),
        ),
      ),
    ],
  ),
)
```

### 3. Components Following Design System

#### DebtTile (Story Format)
```dart
class DebtTile extends StatelessWidget {
  final DebtV2 debt;
  
  Widget build(context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(debt.partyName[0]), // Initial avatar
        backgroundColor: AppColors.accent,
      ),
      title: Text(
        debt.displayTitle, // "Cho vay Minh" or "Vay từ Minh"
        style: AppTextStyles.bodyBold,
      ),
      subtitle: Text(
        'Còn lại ${AmountFormatter.formatCurrency(debt.remainingAmount)}',
        style: AppTextStyles.bodySmall,
      ),
      trailing: debt.isOverdue 
        ? Icon(Icons.warning, color: AppColors.expense)
        : null,
    );
  }
}
```

#### GoalCard (Visual Progress)
```dart
class GoalCard extends StatelessWidget {
  final GoalV2 goal;
  
  Widget build(context) {
    return LedgerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goal.displayTitle, // "✈️ Du lịch Đà Lạt"
            style: AppTextStyles.titleSmall,
          ),
          SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: goal.progressPercentage,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            '${AmountFormatter.formatCurrency(goal.currentAmount)} / ${AmountFormatter.formatCurrency(goal.targetAmount)}',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
```

### 4. Quick Actions Integration
```dart
// Home Screen FAB Menu (updated)
QuickActionsFab(
  actions: [
    QuickAction(
      icon: Icons.add,
      label: 'Giao dịch',
      onTap: () => _showTransactionForm(),
    ),
    QuickAction(
      icon: Icons.swap_horiz,
      label: 'Chuyển tiền',
      onTap: () => _showTransferForm(),
    ),
    QuickAction(
      icon: Icons.savings,
      label: 'Tiết kiệm',
      onTap: () => _showGoalContribution(),
    ),
    QuickAction(
      icon: Icons.payment,
      label: 'Trả nợ',
      onTap: () => _showDebtPayment(),
    ),
  ],
)
```

## Migration Strategy

### Phase 1: Data Migration
1. Create migration scripts following `BootstrapService` pattern
2. Migrate existing debt data from settings to new debt model
3. Migrate existing wallet goals to new goal system
4. Create transfer history from existing transaction data
5. Preserve all existing data with backward compatibility

### Phase 2: Service Layer
1. Implement new service classes following Repository → Service → Screen pattern
2. Maintain backward compatibility during transition
3. Gradual migration of existing functionality
4. Update `ServiceLocator` to include new services

### Phase 3: UI Implementation
1. Follow `AppScaffold` + component patterns
2. Use `AppColors`, `AppTextStyles`, `AppSpacing` (no inline styles)
3. Implement story format for debt/goal activities
4. Add to main navigation following current structure
5. Integrate with existing `QuickAddBar` and FAB patterns

### Phase 4: Integration & Testing
1. End-to-end user flow testing
2. Data consistency validation
3. Performance optimization using existing cache patterns
4. Localization with casual Vietnamese tone

## Success Metrics

### User Experience
- **Reduced clicks** for common operations (target: 50% reduction)
- **Improved task completion** rates for debt/goal management
- **Higher feature adoption** for goals and debt tracking
- **Faster transfer operations** (target: <30 seconds)
- **Casual, friendly tone** throughout all interactions

### Technical Metrics
- **Follows style guide** 100% compliance
- **Better data consistency** across related features
- **Improved performance** using existing cache patterns
- **Reduced support tickets** for transfer confusion

## Risk Assessment

### Low Risk
- UI/UX improvements following established patterns
- New feature additions using existing architecture
- Enhanced user flows with familiar components

### Medium Risk
- Data model changes with migration scripts
- Service layer refactoring following established patterns
- Navigation structure updates

### High Risk
- Breaking changes to existing APIs
- Complex transfer logic changes
- Cross-account operation modifications

## Implementation Timeline

- **Week 1-2**: Data model design and migration scripts
- **Week 3-4**: Service layer implementation following patterns
- **Week 5-6**: UI/UX implementation with style guide compliance
- **Week 7-8**: Integration, testing, and refinement

## Future Enhancements

### Advanced Features
- **Smart debt reminders** with casual notifications
- **Goal achievement predictions** with encouraging messages
- **Automated transfer rules** based on spending patterns
- **Integration with external banks** for automatic transfers
- **Debt consolidation** recommendations with friendly advice
- **Goal sharing** within family accounts with reactions

### Analytics & Insights
- **Debt-to-income ratio** tracking with casual explanations
- **Savings rate** analysis per goal with encouraging feedback
- **Transfer pattern** insights with helpful suggestions
- **Goal achievement** success rates with celebration

This redesign transforms scattered financial features into intuitive, user-centric workflows that align with the vintage ledger design principles: human over financial, soft over sharp, social over personal, and fast over detailed.