import 'package:flutter/material.dart';

import '../l10n/s.dart';
import '../screens/category/category_list_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/amount_text.dart';
import '../utils/date_formatter.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../screens/transaction/transaction_list_screen.dart';

import '../../services/transaction_service.dart';
import '../../models/category.dart';

class TransactionSection extends StatelessWidget {
  final int? walletId;
  final List<TransactionWithItems> transactions;
  final Map<int, Category> categoryMap;

  final Future<void> Function() onAddTransaction;
  final Future<void> Function(TransactionWithItems transaction) onTapTransaction;
  final Future<void> Function(TransactionWithItems transaction) onDeleteTransaction;

  const TransactionSection({
    super.key,
    this.walletId,
    required this.transactions,
    required this.categoryMap,
    required this.onAddTransaction,
    required this.onTapTransaction,
    required this.onDeleteTransaction,
  });

  static Map<int, IconData> iconMap = {
    0: Icons.fastfood,
    1: Icons.directions_car,
    2: Icons.shopping_cart,
    3: Icons.home,
    4: Icons.sports_soccer,
    5: Icons.movie,
    6: Icons.local_cafe,
    7: Icons.health_and_safety,
    8: Icons.phone_iphone,
    9: Icons.school,
    10: Icons.pets,
    11: Icons.flight,
    12: Icons.music_note,
    13: Icons.local_hospital,
  };

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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransactionListScreen(walletId: walletId),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    S.of(context, 'viewAll'),
                    style: const TextStyle(
                      color: AppColors.inkBlack,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 16, color: AppColors.inkBlack),
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CategoryListScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      S.of(context, 'category'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.inkBlack,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_outward, size: 16),
                  ],
                ),
              ),
            ),
            SizedBox(
              child: Text(
                S.of(context, 'amount'),
                textAlign: TextAlign.right,
                style: AppTextStyles.body,
              ),
            ),
          ],
        ),
        Divider(color: AppColors.divider, thickness: 1.2),

        if (transactions.isEmpty)
          EmptyState(message: S.of(context, 'noTransactions')),
        if (transactions.isNotEmpty)
          ...transactions.map((transaction) {
            final category = categoryMap[transaction.transaction.categoryId];
            return InkWell(
              onTap: () async => await onTapTransaction(transaction),
              onLongPress: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(S.of(context, 'deleteTransaction')),
                    content: Text(S.of(context, 'deleteTransactionConfirm')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(S.of(context, 'cancel')),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(S.of(context, 'delete')),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await onDeleteTransaction(transaction);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        DateFormatter.short(transaction.transaction.date),
                        style: AppTextStyles.body,
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          if (category?.icon != null) ...[
                            Icon(
                            (category?.icon != null && iconMap.containsKey(category!.icon))
                                ? iconMap[category.icon]!
                                : Icons.category,
                            size: 20,
                            color: AppColors.inkBlue,
                          ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            category?.name ?? S.of(context, 'other'),
                            style: AppTextStyles.body,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      child: AmountText(
                        amount: transaction.transaction.amount,
                        type: transaction.transaction.type,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onAddTransaction,
            icon: const Icon(Icons.add, size: 16),
            label: Text(
              S.of(context, 'addTransaction'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: AppColors.inkBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
