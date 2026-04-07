import 'package:flutter/material.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/goal/models/goal_v2.dart';
import 'package:vintage_ledger/features/goal/services/goal_service_v2.dart';
import 'package:vintage_ledger/features/goal/screens/goal_form_screen.dart';
import 'package:vintage_ledger/features/goal/screens/goal_detail_screen.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

class GoalListScreen extends StatefulWidget {
  const GoalListScreen({super.key});

  @override
  State<GoalListScreen> createState() => _GoalListScreenState();
}

class _GoalListScreenState extends State<GoalListScreen> {
  final _service = GoalServiceV2();
  GoalCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'MỤC TIÊU',
      showBackButton: false,
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
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildCategoryChip(null, 'Tất cả', '🎯'),
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
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: AppTextStyles.emoji),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
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
    return StreamBuilder<List<GoalV2>>(
      stream: _service.watchGoalsProgress(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var goals = snapshot.data!;
        if (_selectedCategory != null) {
          goals = goals.where((g) => g.category == _selectedCategory).toList();
        }

        if (goals.isEmpty) {
          return Center(
            child: Text('Chưa có mục tiêu nào', style: AppTextStyles.hint),
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

  Widget _buildGoalItem(GoalV2 goal) {
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
            borderRadius: BorderRadius.circular(16),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Hoàn thành',
                          style: AppTextStyles.caption.copyWith(color: AppColors.income),
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
                          Text('Hiện tại', style: AppTextStyles.caption),
                          Text(
                            AmountFormatter.formatCurrency(goal.currentAmount, 'vi'),
                            style: AppTextStyles.amount.copyWith(color: AppColors.income),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mục tiêu', style: AppTextStyles.caption),
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
                  borderRadius: BorderRadius.circular(4),
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
                        'Hạn: ${_formatDate(goal.targetDate!)}',
                        style: AppTextStyles.caption.copyWith(
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
          label: const Text('Tạo mục tiêu mới'),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<bool?> _confirmDelete(GoalV2 goal) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa mục tiêu?'),
        content: Text('Bạn có chắc muốn xóa "${goal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
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

  void _navigateToDetail(GoalV2 goal) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GoalDetailScreen(goalId: goal.id)),
    );
  }
}
