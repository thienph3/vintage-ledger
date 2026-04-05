import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/shimmer_placeholder.dart';
import 'package:vintage_ledger/common/widgets/amount_text.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';
import 'package:vintage_ledger/common/widgets/swipe_list_item.dart';
import 'package:vintage_ledger/common/widgets/delete_confirmation.dart';
import 'package:vintage_ledger/features/recurring/models/recurring_rule.dart';
import 'package:vintage_ledger/features/recurring/screens/recurring_form_screen.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

class RecurringListScreen extends StatefulWidget {
  const RecurringListScreen({super.key});

  @override
  State<RecurringListScreen> createState() => _RecurringListScreenState();
}

class _RecurringListScreenState extends State<RecurringListScreen> {
  Map<String, String> _catNames = {};
  Map<String, int?> _catIcons = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await sl.categoryService.getCategories();
    setState(() {
      _catNames = {for (var c in cats) if (c.id != null) c.id!: c.name};
      _catIcons = {for (var c in cats) if (c.id != null) c.id!: c.icon};
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'recurringRules'),
      body: StreamBuilder<List<RecurringRule>>(
        stream: sl.recurringService.watchRules(),
        builder: (context, snap) {
          final rules = snap.data ?? [];
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const ShimmerPlaceholder();
          }
          return rules.isEmpty
              ? EmptyState(message: S.of(context, 'noRecurring'))
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    ...rules.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _buildRuleTile(r),
                    )),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.pushScreen(const RecurringFormScreen()),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(S.of(context, 'addRecurring')),
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildRuleTile(RecurringRule rule) {
    final catName = _catNames[rule.categoryId] ?? '';
    final catIcon = _catIcons[rule.categoryId];
    final freqLabel = S.of(context, rule.frequency.l10nKey());
    final nextDate = DateFormatter.fullDate(rule.nextRunAt);

    return SwipeListItem(
      itemKey: Key(rule.id!),
      onTap: () => context.pushScreen(RecurringFormScreen(existing: rule)),
      confirmDelete: () => showDeleteConfirmation(context, titleKey: 'deleteRecurring', contentKey: 'deleteRecurringConfirm'),
      onDelete: () => sl.recurringService.deleteRule(rule.id!),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(getCategoryIcon(catIcon), size: 22, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(catName, style: AppTextStyles.bodyBold),
                  Text('$freqLabel · ${S.of(context, 'nextRun')}: $nextDate', style: AppTextStyles.caption),
                  if (rule.note != null && rule.note!.isNotEmpty)
                    Text(rule.note!, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AmountText(amount: rule.amount, type: rule.type),
                Switch(
                  value: rule.enabled,
                  onChanged: (v) => sl.recurringService.updateRule(rule.id!, {'enabled': v}),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
