import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/features/category/screens/category_list_screen.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';
import 'package:vintage_ledger/common/widgets/amount_text.dart';
import 'package:vintage_ledger/common/widgets/delete_confirmation.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';
import 'package:vintage_ledger/features/transaction/screens/transaction_list_screen.dart';
import 'package:vintage_ledger/features/transaction/screens/transaction_form_screen.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/core/service_locator.dart';

class TransactionSection extends StatelessWidget {
  final String? walletId;
  final List<TransactionWithItems> transactions;
  final Map<String, Category> categoryMap;
  final VoidCallback onDataChanged;

  const TransactionSection({
    super.key,
    this.walletId,
    required this.transactions,
    required this.categoryMap,
    required this.onDataChanged,
  });

  Future<void> _addTransaction(BuildContext context) async {
    final result = await context.pushScreen(TransactionFormScreen(walletId: walletId));
    if (result == true) onDataChanged();
  }

  Future<void> _editTransaction(BuildContext context, TransactionWithItems txn) async {
    final result = await context.pushScreen(TransactionFormScreen(
      walletId: txn.transaction.walletId,
      existing: txn,
    ));
    if (result == true) onDataChanged();
  }

  Future<void> _deleteTransaction(BuildContext context, TransactionWithItems txn) async {
    final confirm = await showDeleteConfirmation(context, titleKey: 'deleteTransaction', contentKey: 'deleteTransactionConfirm');
    if (confirm == true) {
      await sl.transactionService.deleteTransaction(txn.transaction.id!);
      onDataChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(S.of(context, 'recentTransactions'), style: AppTextStyles.title),
            InkWell(
              onTap: () => context.pushScreen(TransactionListScreen(walletId: walletId)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(S.of(context, 'viewAll'), style: AppTextStyles.link),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            SizedBox(width: 120, child: Text(S.of(context, 'date'), style: AppTextStyles.body)),
            Expanded(
              child: InkWell(
                onTap: () => context.pushScreen(const CategoryListScreen()),
                child: Row(
                  children: [
                    Text(S.of(context, 'category'), style: AppTextStyles.columnHeader),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_outward, size: 16),
                  ],
                ),
              ),
            ),
            Text(S.of(context, 'amount'), textAlign: TextAlign.right, style: AppTextStyles.body),
          ],
        ),
        const Divider(),
        if (transactions.isEmpty) EmptyState(message: S.of(context, 'noTransactions')),
        if (transactions.isNotEmpty)
          ...transactions.map((txn) {
            final category = categoryMap[txn.transaction.categoryId];
            return InkWell(
              onTap: () => _editTransaction(context, txn),
              onLongPress: () => _deleteTransaction(context, txn),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    SizedBox(width: 120, child: Text(DateFormatter.short(txn.transaction.date), style: AppTextStyles.body)),
                    Expanded(
                      child: Row(
                        children: [
                          if (category?.icon != null) ...[
                            Icon(getCategoryIcon(category?.icon), size: 20, color: AppColors.inkBlue),
                            const SizedBox(width: 6),
                          ],
                          Text(category?.name ?? S.of(context, 'other'), style: AppTextStyles.body),
                          if (txn.transaction.createdBy != null && txn.transaction.createdBy != sl.appState.currentUserId)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(Icons.people_outline, size: 14, color: AppColors.divider),
                            ),
                        ],
                      ),
                    ),
                    AmountText(amount: txn.transaction.amount, type: txn.transaction.type, compact: true),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _addTransaction(context),
            icon: const Icon(Icons.add, size: 16),
            label: Text(S.of(context, 'addTransaction')),
          ),
        ),
      ],
    );
  }
}
