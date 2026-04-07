import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/shimmer_placeholder.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/goal/models/goal.dart';
import 'package:vintage_ledger/features/goal/models/goal_contribution.dart';
import 'package:vintage_ledger/features/goal/models/auto_saving_rule.dart';
import 'package:vintage_ledger/features/goal/services/goal_service.dart';
import 'package:vintage_ledger/features/goal/screens/goal_form_screen.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

class GoalDetailScreen extends StatefulWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final _service = GoalService();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Goal?>(
      future: _service.getGoal(widget.goalId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return AppScaffold(
            title: '',
            body: ShimmerPlaceholder(),
          );
        }

        final goal = snapshot.data!;
        return AppScaffold(
          title: S.of(context, 'goalTitle'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _navigateToEdit(goal),
            ),
          ],
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _buildGoalInfo(goal),
              const SizedBox(height: AppSpacing.lg),
              _buildProgressCard(goal),
              const SizedBox(height: AppSpacing.lg),
              _buildAutoSavingCard(goal),
              const SizedBox(height: AppSpacing.lg),
              if (!goal.isCompleted) _buildContributionSection(goal),
              if (!goal.isCompleted) const SizedBox(height: AppSpacing.lg),
              _buildContributionHistory(goal),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoalInfo(Goal goal) {
    return LedgerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(goal.category.emoji, style: AppTextStyles.emojiLarge),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(goal.name, style: AppTextStyles.headline),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
            ),
            child: Text(
              goal.category.displayName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.primary,
              ),
            ),
          ),
          if (goal.targetDate != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: goal.isOverdue ? AppColors.error : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Hạn: ${_formatDate(goal.targetDate!)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: goal.isOverdue ? AppColors.error : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressCard(Goal goal) {
    return LedgerCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.of(context, 'currentAmount'), style: AppTextStyles.caption),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AmountFormatter.formatCurrency(goal.currentAmount, 'vi'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.income,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.of(context, 'targetGoal'), style: AppTextStyles.caption),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AmountFormatter.formatCurrency(goal.targetAmount, 'vi'),
                      style: AppTextStyles.headline,
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
              Text(S.of(context, 'remaining'), style: AppTextStyles.caption),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AmountFormatter.formatCurrency(goal.remainingAmount, 'vi'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
            child: LinearProgressIndicator(
              value: goal.progressPercentage,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.income),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(goal.progressText, style: AppTextStyles.caption),
          if (goal.isCompleted) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: AppColors.income, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  S.of(context, 'goalCompleted'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.income,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAutoSavingCard(Goal goal) {
    return StreamBuilder<AutoSavingRule?>(
      stream: _service.watchAutoSavingRule(goal.id),
      builder: (context, snapshot) {
        final rule = snapshot.data;
        
        return LedgerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.autorenew, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(S.of(context, 'autoSaving'), style: AppTextStyles.titleSmall),
                  ),
                  if (rule != null)
                    Switch(
                      value: rule.isActive,
                      onChanged: (value) => value
                          ? _service.resumeAutoSaving(goal.id)
                          : _service.pauseAutoSaving(goal.id),
                    ),
                ],
              ),
              if (rule != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${AmountFormatter.formatCurrency(rule.amount, 'vi')} / ${rule.frequency.displayName}',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Lần tiếp theo: ${_formatDate(rule.nextRunDate)}',
                  style: AppTextStyles.caption,
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.sm),
                Text(S.of(context, 'noAutoSaving'), style: AppTextStyles.hint),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: () => _showAutoSavingDialog(goal),
                  icon: const Icon(Icons.add),
                  label: Text(S.of(context, 'setupAutoSavingButton')),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildContributionSection(Goal goal) {
    return LedgerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.of(context, 'contributeToGoal'), style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: S.of(context, 'contributionAmount'),
              hintText: S.of(context, 'enterAmount'),
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: '${S.of(context, 'note')} (tùy chọn)',
              hintText: S.of(context, 'noteHint'),
              prefixIcon: Icon(Icons.note),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _contribute(goal),
              child: Text(S.of(context, 'contribute')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionHistory(Goal goal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.of(context, 'contributionHistory'), style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.md),
        StreamBuilder<List<GoalContribution>>(
          stream: _service.watchContributions(goal.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const ShimmerPlaceholder();
            }

            final contributions = snapshot.data!;
            if (contributions.isEmpty) {
              return LedgerCard(
                child: Center(
                  child: Text(S.of(context, 'noContributions'), style: AppTextStyles.hint),
                ),
              );
            }

            return Column(
              children: contributions.map((c) => _buildContributionItem(c)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContributionItem(GoalContribution contribution) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: LedgerCard(
        child: Row(
          children: [
            Icon(
              contribution.isContribution ? Icons.add_circle : Icons.remove_circle,
              color: contribution.isContribution ? AppColors.income : AppColors.expense,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AmountFormatter.formatCurrency(contribution.absoluteAmount, 'vi'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: contribution.isContribution ? AppColors.income : AppColors.expense,
                    ),
                  ),
                  if (contribution.note != null)
                    Text(contribution.note!, style: AppTextStyles.caption),
                ],
              ),
            ),
            Text(_formatDate(contribution.date), style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _contribute(Goal goal) async {
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

    try {
      await _service.napVaoMucTieu(
        goal.id,
        amount,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );

      _amountController.clear();
      _noteController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context, 'contributionRecorded'))),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${S.of(context, 'error')}: $e')),
        );
      }
    }
  }

  Future<void> _showAutoSavingDialog(Goal goal) async {
    final amountController = TextEditingController();
    RecurrenceType frequency = RecurrenceType.monthly;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(S.of(context, 'setupAutoSaving')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: S.of(context, 'autoSavingAmount'),
                  hintText: S.of(context, 'enterAmount'),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<RecurrenceType>(
                initialValue: frequency,
                decoration: InputDecoration(labelText: S.of(context, 'recurrence')),
                items: RecurrenceType.values.map((f) {
                  return DropdownMenuItem(
                    value: f,
                    child: Text(f.displayName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => frequency = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.of(context, 'cancel')),
            ),
            TextButton(
              onPressed: () async {
                final amount = int.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  await _service.thietLapTietKiemTuDong(
                    goalId: goal.id,
                    amount: amount,
                    frequency: frequency,
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(S.of(context, 'save')),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEdit(Goal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GoalFormScreen(goal: goal)),
    );
  }
}
