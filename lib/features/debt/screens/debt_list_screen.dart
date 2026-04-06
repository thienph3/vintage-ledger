import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';
import 'package:vintage_ledger/common/widgets/swipe_list_item.dart';
import 'package:vintage_ledger/common/widgets/delete_confirmation.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/features/debt/models/debt.dart';
import 'package:vintage_ledger/features/debt/screens/debt_form_screen.dart';
import 'package:vintage_ledger/features/debt/screens/debt_detail_screen.dart';
import 'package:vintage_ledger/features/debt/widgets/debt_progress_bar.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

class DebtListScreen extends StatelessWidget {
  const DebtListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'debts'),
      body: StreamBuilder<List<Debt>>(
        stream: sl.debtService.watchDebts(),
        builder: (context, snap) {
          final debts = snap.data ?? [];
          final active = debts.where((d) => !d.settled).toList();
          final lends = active.where((d) => d.isLend).toList();
          final borrows = active.where((d) => d.isBorrow).toList();

          return Column(
            children: [
              Expanded(
                child: active.isEmpty
                    ? EmptyState(emoji: '💰', message: S.of(context, 'noDebts'))
                    : ListView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        children: [
                          if (lends.isNotEmpty) ...[
                            Text(S.of(context, 'lend'), style: AppTextStyles.titleSmall),
                            const SizedBox(height: AppSpacing.sm),
                            ...lends.map((d) => _buildDebtCard(context, d)),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          if (borrows.isNotEmpty) ...[
                            Text(S.of(context, 'borrow'), style: AppTextStyles.titleSmall),
                            const SizedBox(height: AppSpacing.sm),
                            ...borrows.map((d) => _buildDebtCard(context, d)),
                          ],
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.pushScreen(const DebtFormScreen()),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(S.of(context, 'addDebt')),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDebtCard(BuildContext context, Debt d) {
    final locale = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SwipeListItem(
        itemKey: ValueKey(d.id),
        onTap: () => context.pushScreen(DebtDetailScreen(debt: d)),
        confirmDelete: () => showDeleteConfirmation(
          context, titleKey: 'deleteDebt', contentKey: 'deleteDebtConfirm',
        ),
        onDelete: () => sl.debtService.deleteDebt(d.id!),
        child: LedgerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(d.isLend ? Icons.arrow_upward : Icons.arrow_downward, size: 16,
                    color: d.isLend ? AppColors.income : AppColors.expense),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(d.partyName, style: AppTextStyles.bodyBold)),
                  Text(AmountFormatter.formatCompactCurrency(d.remaining, locale),
                    style: AppTextStyles.bodyBold),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              DebtProgressBar(paidAmount: d.paidAmount, totalAmount: d.totalAmount, isLend: d.isLend),
            ],
          ),
        ),
      ),
    );
  }
}
