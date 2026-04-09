import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/constants/category_emojis.dart';
import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/amount_text.dart';
import 'package:vintage_ledger/features/recurring/models/recurring_rule.dart';

/// Widget hiển thị danh sách các khoản thanh toán định kỳ đến hạn.
///
/// Ẩn hoàn toàn khi [dueReminders] rỗng.
/// Tap vào item → [onPay], swipe dismiss → [onDismiss].
class BillReminderWidget extends StatelessWidget {
  final List<RecurringRule> dueReminders;
  final ValueChanged<RecurringRule> onPay;
  final ValueChanged<RecurringRule> onDismiss;

  /// Map categoryId → tên danh mục (để hiển thị tên + emoji).
  final Map<String, String> categoryNames;

  /// Map walletId → tên ví (để hiển thị tên ví nguồn).
  final Map<String, String> walletNames;

  const BillReminderWidget({
    super.key,
    required this.dueReminders,
    required this.onPay,
    required this.onDismiss,
    required this.categoryNames,
    required this.walletNames,
  });

  @override
  Widget build(BuildContext context) {
    if (dueReminders.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm,
            ),
            child: Row(
              children: [
                const Text('⏰', style: AppTextStyles.emoji),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  S.of(context, 'billReminderTitle'),
                  style: AppTextStyles.titleSmall,
                ),
              ],
            ),
          ),
          // Reminder list
          ...dueReminders.map((rule) => _BillReminderItem(
                rule: rule,
                categoryName: categoryNames[rule.categoryId],
                walletName: walletNames[rule.walletId],
                onPay: () => onPay(rule),
                onDismiss: () => onDismiss(rule),
              )),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _BillReminderItem extends StatelessWidget {
  final RecurringRule rule;
  final String? categoryName;
  final String? walletName;
  final VoidCallback onPay;
  final VoidCallback onDismiss;

  const _BillReminderItem({
    required this.rule,
    required this.categoryName,
    required this.walletName,
    required this.onPay,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final label = rule.note?.isNotEmpty == true
        ? rule.note!
        : (categoryName ?? S.of(context, 'other'));
    final emoji = getCategoryEmoji(categoryName ?? '');

    return Dismissible(
      key: ValueKey(rule.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        ),
        child: Text(
          S.of(context, 'billReminderDismiss'),
          style: AppTextStyles.bodySmall,
        ),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onPay,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Text(emoji, style: AppTextStyles.emoji),
              const SizedBox(width: AppSpacing.md2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.body),
                    if (walletName != null)
                      Text(walletName!, style: AppTextStyles.caption),
                  ],
                ),
              ),
              AmountText(
                amount: rule.amount,
                type: rule.type,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
