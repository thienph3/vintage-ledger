import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/common/widgets/shimmer_placeholder.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/goal/models/goal.dart';
import 'package:vintage_ledger/features/goal/services/goal_service.dart';
import 'package:vintage_ledger/features/goal/screens/goal_form_screen.dart';
import 'package:vintage_ledger/features/goal/screens/goal_detail_screen.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

class GoalListScreen extends StatefulWidget {
  const GoalListScreen({super.key});

  @override
  State<GoalListScreen> createState() => _GoalListScreenState();
}

class _GoalListScreenState extends State<GoalListScreen> {
  final _service = GoalService();
  GoalCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'goalTitle'),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(child: _buildGoalList()),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 89,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        children: [
          _buildCategoryChip(null, S.of(context, 'allGoals'), '🎯'),
          ...GoalCategory.values.map((cat) => _buildCategoryChip(
            cat,
            cat.displayName,
            cat.emoji,
          )),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(GoalCategory? category, String label, String emoji) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = category),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg + 8),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: AppTextStyles.emoji),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalList() {
    return StreamBuilder<List<Goal>>(
      stream: _service.watchGoalsProgress(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerPlaceholder();
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('${S.of(context, 'error')}: ${snapshot.error}', style: AppTextStyles.error),
          );
        }

        var goals = snapshot.data ?? [];
        if (_selectedCategory != null) {
          goals = goals.where((g) => g.category == _selectedCategory).toList();
        }

        if (goals.isEmpty) {
          return Center(
            child: Text(S.of(context, 'noGoals'), style: AppTextStyles.hint),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: goals.length,
            itemBuilder: (context, index) => _buildGoalItem(goals[index]),
          ),
        );
      },
    );
  }

  Widget _buildGoalItem(Goal goal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Dismissible(
        key: Key(goal.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (_) => _confirmDelete(goal),
        onDismissed: (_) => _service.deleteGoal(goal.id),
        child: GestureDetector(
          onTap: () => _navigateToDetail(goal),
          child: LedgerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(goal.category.emoji, style: AppTextStyles.emoji),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(goal.name, style: AppTextStyles.bodyBold),
                    ),
                    if (goal.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.income.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                        ),
                        child: Text(
                          S.of(context, 'goalCompleted'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.income,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(S.of(context, 'currentAmount'), style: AppTextStyles.caption),
                          Text(
                            AmountFormatter.formatCurrency(goal.currentAmount, 'vi'),
                            style: const TextStyle(
                              fontSize: 16,
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
                          Text(
                            AmountFormatter.formatCurrency(goal.targetAmount, 'vi'),
                            style: AppTextStyles.amount,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                  child: LinearProgressIndicator(
                    value: goal.progressPercentage,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation(AppColors.income),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(goal.progressText, style: AppTextStyles.caption),
                    if (goal.targetDate != null)
                      Text(
                        '${S.of(context, 'goalDeadline')}: ${_formatDate(goal.targetDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: goal.isOverdue ? AppColors.error : AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _navigateToForm,
          icon: const Icon(Icons.add),
          label: Text(S.of(context, 'createGoalButton')),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<bool?> _confirmDelete(Goal goal) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context, 'deleteGoalQuestion')),
        content: Text(S.of(context, 'deleteGoalMessage').replaceAll('{name}', goal.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              S.of(context, 'delete'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GoalFormScreen()),
    );
  }

  void _navigateToDetail(Goal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GoalDetailScreen(goalId: goal.id)),
    );
  }
}
