import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/features/debt/models/debt.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

class DebtSummaryCard extends StatelessWidget {
  const DebtSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Debt>>(
      stream: sl.debtService.watchDebts(),
      builder: (context, snap) {
        final debts = (snap.data ?? []).where((d) => !d.settled).toList();
        if (debts.isEmpty) return const SizedBox.shrink();

        final locale = Localizations.localeOf(context).languageCode;
        final lendTotal = debts.where((d) => d.isLend).fold<int>(0, (s, d) => s + d.remaining);
        final borrowTotal = debts.where((d) => d.isBorrow).fold<int>(0, (s, d) => s + d.remaining);

        return LedgerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.of(context, 'debts'), style: AppTextStyles.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              if (lendTotal > 0)
                _row(S.of(context, 'othersOweYou'), lendTotal, AppColors.income, locale),
              if (borrowTotal > 0)
                _row(S.of(context, 'youOweOthers'), borrowTotal, AppColors.expense, locale),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, int amount, Color color, String locale) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(AmountFormatter.formatCompactCurrency(amount, locale),
            style: AppTextStyles.bodyBold.copyWith(color: color)),
        ],
      ),
    );
  }
}
