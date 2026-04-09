import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/shimmer_placeholder.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/goal/models/goal.dart';
import 'package:vintage_ledger/features/goal/services/goal_service.dart';
import 'package:vintage_ledger/features/wallet/services/wallet_service.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

class GoalContributionScreen extends StatefulWidget {
  const GoalContributionScreen({super.key});

  @override
  State<GoalContributionScreen> createState() => _GoalContributionScreenState();
}

class _GoalContributionScreenState extends State<GoalContributionScreen> {
  final _service = GoalService();
  final _walletService = WalletService();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  Goal? _selectedGoal;
  bool _isLoading = false;
  int? _availableBalance;
  bool _isLoadingBalance = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {});
  }

  Future<void> _fetchAvailableBalance(Goal goal) async {
    setState(() => _isLoadingBalance = true);
    try {
      final wallet = await _walletService.getWallet(goal.fundingWalletId);
      if (wallet == null) {
        setState(() {
          _availableBalance = null;
          _isLoadingBalance = false;
        });
        return;
      }
      final earmarked = await _service.getEarmarkedAmount(goal.fundingWalletId);
      setState(() {
        _availableBalance = wallet.balance - earmarked;
        _isLoadingBalance = false;
      });
    } catch (_) {
      setState(() {
        _availableBalance = null;
        _isLoadingBalance = false;
      });
    }
  }

  bool get _amountExceedsAvailable {
    if (_availableBalance == null) return false;
    final amount = int.tryParse(_amountController.text) ?? 0;
    return amount > _availableBalance!;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'contributeToGoal'),
      body: StreamBuilder<List<Goal>>(
        stream: _service.watchGoalsProgress(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerPlaceholder();
          }

          final goals = snapshot.data ?? [];
          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(S.of(context, 'noGoals'), style: AppTextStyles.hint),
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
              Text(S.of(context, 'goalCategory'), style: AppTextStyles.titleSmall),
              const SizedBox(height: AppSpacing.md),
              ...goals.map((goal) => _buildGoalOption(goal)),
              if (_selectedGoal != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _buildContributionForm(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildGoalOption(Goal goal) {
    final isSelected = _selectedGoal?.id == goal.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedGoal = goal);
          _fetchAvailableBalance(goal);
        },
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
              Text(goal.category.emoji, style: AppTextStyles.emoji),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: AppTextStyles.bodyBold),
                    Text(
                      '${AmountFormatter.formatCurrency(goal.currentAmount, 'vi')} / ${AmountFormatter.formatCurrency(goal.targetAmount, 'vi')}',
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

  Widget _buildContributionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Available balance display
        if (_isLoadingBalance)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_availableBalance != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${S.of(context, 'availableBalanceLabel')}: ',
                    style: AppTextStyles.caption,
                  ),
                  Text(
                    AmountFormatter.formatCurrency(_availableBalance!, 'vi'),
                    style: AppTextStyles.bodyBold.copyWith(
                      color: _availableBalance! > 0 ? AppColors.income : AppColors.expense,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Text(S.of(context, 'contributionAmount'), style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: S.of(context, 'amount'),
            hintText: S.of(context, 'enterAmount'),
            prefixIcon: const Icon(Icons.attach_money),
            errorText: _amountExceedsAvailable ? S.of(context, 'amountExceedsAvailable') : null,
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
            onPressed: (_isLoading || _amountExceedsAvailable) ? null : _contribute,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(S.of(context, 'contribute')),
          ),
        ),
      ],
    );
  }

  Future<void> _contribute() async {
    if (_selectedGoal == null) return;

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
      await _service.napVaoMucTieu(
        _selectedGoal!.id,
        amount,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context, 'contributionRecorded'))),
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
