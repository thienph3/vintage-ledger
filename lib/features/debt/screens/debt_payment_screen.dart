import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/shimmer_placeholder.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/debt/models/debt.dart';
import 'package:vintage_ledger/features/debt/services/debt_service.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

class DebtPaymentScreen extends StatefulWidget {
  const DebtPaymentScreen({super.key});

  @override
  State<DebtPaymentScreen> createState() => _DebtPaymentScreenState();
}

class _DebtPaymentScreenState extends State<DebtPaymentScreen> {
  final _service = DebtService();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  Debt? _selectedDebt;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'recordPaymentTitle'),
      body: StreamBuilder<List<Debt>>(
        stream: _service.watchActiveDebts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerPlaceholder();
          }

          final debts = snapshot.data ?? [];
          if (debts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(S.of(context, 'noDebts'), style: AppTextStyles.hint),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(S.of(context, 'cancel')),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(S.of(context, 'debtType'), style: AppTextStyles.titleSmall),
              const SizedBox(height: AppSpacing.md),
              ...debts.map((debt) => _buildDebtOption(debt)),
              if (_selectedDebt != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _buildPaymentForm(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildDebtOption(Debt debt) {
    final isSelected = _selectedDebt?.id == debt.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: () => setState(() => _selectedDebt = debt),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                debt.type == DebtType.lend ? Icons.trending_up : Icons.trending_down,
                color: debt.type == DebtType.lend ? AppColors.income : AppColors.expense,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(debt.displayTitle, style: AppTextStyles.bodyBold),
                    Text(
                      '${S.of(context, 'remainingAmount')}: ${AmountFormatter.formatCurrency(debt.remainingAmount, 'vi')}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.of(context, 'paymentAmount'), style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: S.of(context, 'amount'),
            hintText: S.of(context, 'enterAmount'),
            prefixIcon: const Icon(Icons.attach_money),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _noteController,
          decoration: InputDecoration(
            labelText: '${S.of(context, 'note')} (tùy chọn)',
            hintText: S.of(context, 'noteHint'),
            prefixIcon: const Icon(Icons.note),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _recordPayment,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(S.of(context, 'recordPaymentButton')),
          ),
        ),
      ],
    );
  }

  Future<void> _recordPayment() async {
    if (_selectedDebt == null) return;

    final amountText = _amountController.text;
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context, 'enterAmount'))),
      );
      return;
    }

    final amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context, 'amountMustBePositive'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_selectedDebt!.type == DebtType.lend) {
        await _service.nhanTienTra(
          _selectedDebt!.id,
          amount,
          note: _noteController.text.isEmpty ? null : _noteController.text,
        );
      } else {
        await _service.traNop(
          _selectedDebt!.id,
          amount,
          note: _noteController.text.isEmpty ? null : _noteController.text,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context, 'paymentRecorded'))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${S.of(context, 'error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
