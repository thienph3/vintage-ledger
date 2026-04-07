import 'package:flutter/material.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/debt/models/debt.dart';
import 'package:vintage_ledger/features/debt/services/debt_service.dart';
import 'package:vintage_ledger/features/debt/screens/debt_list_screen_v2.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

class DebtSummaryWidget extends StatelessWidget {
  const DebtSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final service = DebtService();

    return StreamBuilder<List<Debt>>(
      stream: service.watchActiveDebts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final debts = snapshot.data!;
        if (debts.isEmpty) {
          return const SizedBox.shrink();
        }

        final lentDebts = debts.where((d) => d.type == DebtType.lend).toList();
        final borrowedDebts = debts.where((d) => d.type == DebtType.borrow).toList();

        final totalLent = lentDebts.fold<int>(0, (sum, d) => sum + d.remainingAmount);
        final totalBorrowed = borrowedDebts.fold<int>(0, (sum, d) => sum + d.remainingAmount);

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DebtListScreen()),
          ),
          child: LedgerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.trending_up, color: AppColors.primary, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text('Nợ', style: AppTextStyles.titleSmall),
                    ),
                    Text(
                      'Xem tất cả',
                      style: AppTextStyles.link,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _buildDebtStat(
                        label: 'Cho vay',
                        amount: totalLent,
                        count: lentDebts.length,
                        color: AppColors.income,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.divider,
                    ),
                    Expanded(
                      child: _buildDebtStat(
                        label: 'Vay mượn',
                        amount: totalBorrowed,
                        count: borrowedDebts.length,
                        color: AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDebtStat({
    required String label,
    required int amount,
    required int count,
    required Color color,
  }) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Text(
          AmountFormatter.formatCompactCurrency(amount, 'vi'),
          style: AppTextStyles.amount.copyWith(color: color),
        ),
        const SizedBox(height: 2),
        Text(
          '$count khoản',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
