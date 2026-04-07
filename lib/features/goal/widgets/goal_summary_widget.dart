import 'package:flutter/material.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/goal/models/goal.dart';
import 'package:vintage_ledger/features/goal/services/goal_service.dart';
import 'package:vintage_ledger/features/goal/screens/goal_list_screen.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

class GoalSummaryWidget extends StatelessWidget {
  const GoalSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final service = GoalService();

    return StreamBuilder<List<Goal>>(
      stream: service.watchGoalsProgress(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final goals = snapshot.data!;
        if (goals.isEmpty) {
          return const SizedBox.shrink();
        }

        final totalTarget = goals.fold<int>(0, (sum, g) => sum + g.targetAmount);
        final totalCurrent = goals.fold<int>(0, (sum, g) => sum + g.currentAmount);
        final overallProgress = totalTarget > 0 ? totalCurrent / totalTarget : 0.0;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GoalListScreen()),
          ),
          child: LedgerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag, color: AppColors.primary, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text('Mục tiêu', style: AppTextStyles.titleSmall),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Đang thực hiện', style: AppTextStyles.caption),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${goals.length} mục tiêu',
                            style: AppTextStyles.bodyBold,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tiến độ', style: AppTextStyles.caption),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${(overallProgress * 100).toInt()}%',
                            style: AppTextStyles.bodyBold.copyWith(color: AppColors.income),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: overallProgress,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation(AppColors.income),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AmountFormatter.formatCompactCurrency(totalCurrent, 'vi'),
                      style: AppTextStyles.caption.copyWith(color: AppColors.income),
                    ),
                    Text(
                      AmountFormatter.formatCompactCurrency(totalTarget, 'vi'),
                      style: AppTextStyles.caption,
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
}
