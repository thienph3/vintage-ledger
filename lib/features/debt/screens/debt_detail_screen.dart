// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/app_snackbar.dart';
import 'package:vintage_ledger/common/widgets/amount_input_field.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/features/debt/models/debt.dart';
import 'package:vintage_ledger/features/debt/models/payment.dart';
import 'package:vintage_ledger/features/debt/widgets/debt_progress_bar.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';

class DebtDetailScreen extends StatefulWidget {
  final Debt debt;

  const DebtDetailScreen({super.key, required this.debt});

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final d = widget.debt;

    return AppScaffold(
      title: d.partyName,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Summary
          LedgerCard(
            child: Column(
              children: [
                Text(
                  '${d.isLend ? S.of(context, 'owesYou') : S.of(context, 'youOwe')} ${AmountFormatter.formatCurrency(d.remaining, locale)}',
                  style: AppTextStyles.title.copyWith(fontSize: 18),
                ),
                const SizedBox(height: AppSpacing.md),
                DebtProgressBar(paidAmount: d.paidAmount, totalAmount: d.totalAmount, isLend: d.isLend),
                if (d.settled)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(S.of(context, 'debtSettled'), style: AppTextStyles.bodyBold.copyWith(color: AppColors.income)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Payment history
          Text(S.of(context, 'paymentHistory'), style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          StreamBuilder<List<Payment>>(
            stream: sl.debtService.watchPayments(d.id!),
            builder: (context, snap) {
              final payments = snap.data ?? [];
              if (payments.isEmpty) {
                return Text(S.of(context, 'noActivity'), style: AppTextStyles.hint);
              }
              return Column(
                children: payments.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: [
                      Text(DateFormatter.date(p.date), style: AppTextStyles.caption),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(p.note ?? '', style: AppTextStyles.bodySmall)),
                      Text(AmountFormatter.formatCompactCurrency(p.amount, locale), style: AppTextStyles.bodyBold),
                    ],
                  ),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Record payment button
          if (!d.settled)
            ElevatedButton.icon(
              onPressed: () => _showPaymentDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: Text(S.of(context, 'recordPayment')),
            ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(S.of(ctx, 'recordPayment'), style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.md),
            AmountInputField(controller: amountCtrl),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(hintText: S.of(ctx, 'noteHint')),
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = int.tryParse(amountCtrl.text) ?? 0;
                  if (amount <= 0) return;
                  Navigator.pop(ctx);
                  try {
                    await sl.debtService.recordPayment(
                      widget.debt.id!,
                      Payment(amount: amount, date: DateTime.now().millisecondsSinceEpoch, note: noteCtrl.text.isEmpty ? null : noteCtrl.text),
                    );
                    if (mounted) setState(() {});
                  } catch (e) {
                    if (mounted) showAppSnackBar(context, e.toString(), backgroundColor: AppColors.error);
                  }
                },
                child: Text(S.of(ctx, 'save')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
