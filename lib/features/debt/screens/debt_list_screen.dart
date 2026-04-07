import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/shimmer_placeholder.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/debt/models/debt.dart';
import 'package:vintage_ledger/features/debt/services/debt_service.dart';
import 'package:vintage_ledger/features/debt/screens/debt_form_screen.dart';
import 'package:vintage_ledger/features/debt/screens/debt_detail_screen.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

enum DebtFilter { all, lend, borrow, overdue }

class DebtListScreen extends StatefulWidget {
  const DebtListScreen({super.key});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen> {
  final _service = DebtService();
  DebtFilter _filter = DebtFilter.all;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'debtTitle'),
      body: Column(
        children: [
          _buildFilterRow(),
          Expanded(child: _buildDebtList()),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          _buildFilterChip(DebtFilter.all, Icons.all_inclusive),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip(DebtFilter.lend, Icons.trending_up),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip(DebtFilter.borrow, Icons.trending_down),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip(DebtFilter.overdue, Icons.warning_amber),
        ],
      ),
    );
  }

  Widget _buildFilterChip(DebtFilter filter, IconData icon) {
    final isSelected = _filter == filter;
    final labels = {
      DebtFilter.all: S.of(context, 'allDebts'),
      DebtFilter.lend: S.of(context, 'lendDebts'),
      DebtFilter.borrow: S.of(context, 'borrowDebts'),
      DebtFilter.overdue: S.of(context, 'overdueDebts'),
    };
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
              const SizedBox(height: AppSpacing.xs),
              Text(
                labels[filter]!,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebtList() {
    return StreamBuilder<List<Debt>>(
      stream: _service.watchActiveDebts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerPlaceholder();
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('${S.of(context, 'error')}: ${snapshot.error}', style: AppTextStyles.error),
          );
        }

        var debts = snapshot.data ?? [];
        debts = _filterDebts(debts);

        if (debts.isEmpty) {
          return Center(
            child: Text(S.of(context, 'noDebts'), style: AppTextStyles.hint),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: debts.length,
            itemBuilder: (context, index) => _buildDebtItem(debts[index]),
          ),
        );
      },
    );
  }

  List<Debt> _filterDebts(List<Debt> debts) {
    switch (_filter) {
      case DebtFilter.lend:
        return debts.where((d) => d.type == DebtType.lend).toList();
      case DebtFilter.borrow:
        return debts.where((d) => d.type == DebtType.borrow).toList();
      case DebtFilter.overdue:
        return debts.where((d) => d.isOverdue).toList();
      case DebtFilter.all:
        return debts;
    }
  }

  Widget _buildDebtItem(Debt debt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Dismissible(
        key: Key(debt.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (_) => _confirmDelete(debt),
        onDismissed: (_) => _service.deleteDebt(debt.id),
        child: GestureDetector(
          onTap: () => _navigateToDetail(debt),
          child: LedgerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      debt.type == DebtType.lend ? Icons.trending_up : Icons.trending_down,
                      color: debt.type == DebtType.lend ? AppColors.income : AppColors.expense,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(debt.displayTitle, style: AppTextStyles.bodyBold),
                    ),
                    if (debt.isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          S.of(context, 'overdue'),
                          style: AppTextStyles.caption.copyWith(color: AppColors.error),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(S.of(context, 'totalAmount'), style: AppTextStyles.caption),
                          Text(
                            AmountFormatter.formatCurrency(debt.totalAmount, 'vi'),
                            style: AppTextStyles.amount,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(S.of(context, 'remainingAmount'), style: AppTextStyles.caption),
                          Text(
                            AmountFormatter.formatCurrency(debt.remainingAmount, 'vi'),
                            style: AppTextStyles.amount.copyWith(
                              color: debt.type == DebtType.lend ? AppColors.income : AppColors.expense,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: debt.progressPercentage,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(
                      debt.type == DebtType.lend ? AppColors.income : AppColors.expense,
                    ),
                    minHeight: 6,
                  ),
                ),
                if (debt.dueDate != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${S.of(context, 'goalDeadline')}: ${_formatDate(debt.dueDate!)}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _navigateToForm,
          icon: const Icon(Icons.add),
          label: Text(S.of(context, 'addDebt')),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<bool?> _confirmDelete(Debt debt) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context, 'deleteDebtQuestion')),
        content: Text(S.of(context, 'deleteDebtMessage').replaceAll('{name}', debt.displayTitle)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.of(context, 'delete'), style: AppTextStyles.buttonLabel.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _navigateToForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DebtFormScreen()),
    );
  }

  void _navigateToDetail(Debt debt) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DebtDetailScreen(debtId: debt.id)),
    );
  }
}
