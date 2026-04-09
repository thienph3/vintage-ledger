import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/shimmer_placeholder.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/debt/models/debt.dart';
import 'package:vintage_ledger/features/debt/models/debt_payment.dart';
import 'package:vintage_ledger/features/debt/services/debt_service.dart';
import 'package:vintage_ledger/features/debt/screens/debt_form_screen.dart';
import 'package:vintage_ledger/features/debt/screens/debt_payment_screen.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

class DebtDetailScreen extends StatefulWidget {
  final String debtId;

  const DebtDetailScreen({super.key, required this.debtId});

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  final _service = DebtService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Debt?>(
      future: _service.getDebt(widget.debtId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return AppScaffold(
            title: '',
            body: ShimmerPlaceholder(),
          );
        }

        final debt = snapshot.data!;
        return AppScaffold(
          title: S.of(context, 'debtTitle'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _navigateToEdit(debt),
            ),
          ],
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _buildDebtInfo(debt),
                  const SizedBox(height: AppSpacing.lg),
                  _buildProgressCard(debt),
                  const SizedBox(height: AppSpacing.lg),
                  if (debt.isCompleted) _buildSettledBanner(),
                  if (debt.isCompleted) const SizedBox(height: AppSpacing.lg),
                  _buildPaymentHistory(debt),
                  const SizedBox(height: 80),
                ],
              ),
              if (!debt.isCompleted)
                Positioned(
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: FloatingActionButton.extended(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DebtPaymentScreen()),
                      );
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.payment),
                    label: Text(S.of(context, 'recordPaymentButton')),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDebtInfo(Debt debt) {
    return LedgerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                debt.type == DebtType.lend ? Icons.trending_up : Icons.trending_down,
                color: debt.type == DebtType.lend ? AppColors.income : AppColors.expense,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(debt.displayTitle, style: AppTextStyles.headline),
              ),
            ],
          ),
          if (debt.partyContact != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Text(debt.partyContact!, style: AppTextStyles.bodySmall),
              ],
            ),
          ],
          if (debt.description != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(debt.description!, style: AppTextStyles.body),
          ],
          if (debt.dueDate != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: debt.isOverdue ? AppColors.error : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Hạn: ${_formatDate(debt.dueDate!)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: debt.isOverdue ? AppColors.error : AppColors.textSecondary,
                  ),
                ),
                if (debt.isOverdue) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                    ),
                    child: Text(
                      'Quá hạn',
                      style: AppTextStyles.caption.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (debt.interestRate != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.percent, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Lãi suất: ${debt.interestRate}%',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressCard(Debt debt) {
    return LedgerCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.of(context, 'totalAmount'), style: AppTextStyles.caption),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AmountFormatter.formatCurrency(debt.totalAmount, 'vi'),
                      style: AppTextStyles.headline,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.of(context, 'paidAmount'), style: AppTextStyles.caption),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AmountFormatter.formatCurrency(debt.paidAmount, 'vi'),
                      style: AppTextStyles.headline.copyWith(color: AppColors.income),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.of(context, 'remainingAmount'), style: AppTextStyles.caption),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AmountFormatter.formatCurrency(debt.remainingAmount, 'vi'),
                style: AppTextStyles.headline.copyWith(
                  color: debt.type == DebtType.lend ? AppColors.income : AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
            child: LinearProgressIndicator(
              value: debt.progressPercentage,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(
                debt.type == DebtType.lend ? AppColors.income : AppColors.expense,
              ),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${(debt.progressPercentage * 100).toInt()}% hoàn thành',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildSettledBanner() {
    return LedgerCard(
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.income, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              S.of(context, 'settled'),
              style: AppTextStyles.headline.copyWith(color: AppColors.income),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(Debt debt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.of(context, 'debtPaymentHistory'), style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.md),
        StreamBuilder<List<DebtPayment>>(
          stream: _service.watchPayments(debt.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const ShimmerPlaceholder();
            }

            final payments = snapshot.data!;
            if (payments.isEmpty) {
              return LedgerCard(
                child: Center(
                  child: Text(S.of(context, 'noPayments'), style: AppTextStyles.hint),
                ),
              );
            }

            return Column(
              children: payments.map((p) => _buildPaymentItem(p)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPaymentItem(DebtPayment payment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: LedgerCard(
        child: Row(
          children: [
            const Icon(Icons.payment, color: AppColors.income, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AmountFormatter.formatCurrency(payment.amount, 'vi'),
                    style: AppTextStyles.bodyBold.copyWith(color: AppColors.income),
                  ),
                  if (payment.note != null)
                    Text(payment.note!, style: AppTextStyles.caption),
                ],
              ),
            ),
            Text(_formatDate(payment.date), style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToEdit(Debt debt) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DebtFormScreen(debt: debt)),
    );
  }
}
