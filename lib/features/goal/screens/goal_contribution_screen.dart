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
import 'package:vintage_ledger/common/widgets/amount_input_field.dart';
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
  List<Goal>? _goals;
  bool _loadingGoals = true;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_validateAmount);
    _loadGoals();
  }

  @override
  void dispose() {
    _amountController.removeListener(_validateAmount);
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    final goals = await _service.getActiveGoals();
    if (!mounted) return;
    setState(() {
      _goals = goals;
      _loadingGoals = false;
    });
  }

  Future<void> _fetchAvailableBalance(Goal goal) async {
    setState(() => _isLoadingBalance = true);
    try {
      final wallet = await _walletService.getWallet(goal.fundingWalletId);
      if (wallet == null) {
        setState(() { _availableBalance = null; _isLoadingBalance = false; });
        return;
      }
      final earmarked = await _service.getEarmarkedAmount(goal.fundingWalletId);
      if (!mounted) return;
      setState(() {
        _availableBalance = wallet.balance - earmarked;
        _isLoadingBalance = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _availableBalance = null; _isLoadingBalance = false; });
    }
  }

  void _validateAmount() {
    final amount = int.tryParse(_amountController.text) ?? 0;
    final exceeds = _availableBalance != null && amount > _availableBalance!;
    final newError = exceeds ? S.of(context, 'amountExceedsAvailable') : null;
    if (newError != _amountError) {
      setState(() => _amountError = newError);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'contributeToGoal'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadingGoals) return const ShimmerPlaceholder();

    final goals = _goals ?? [];
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
                  Text('${S.of(context, 'availableBalanceLabel')}: ', style: AppTextStyles.caption),
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
        AmountInputField(
          controller: _amountController,
          label: S.of(context, 'amount'),
        ),
        if (_amountError != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(_amountError!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
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
            onPressed: (_isLoading || _amountError != null) ? null : _contribute,
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
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
