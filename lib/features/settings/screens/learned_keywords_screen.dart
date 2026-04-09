import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';
import 'package:vintage_ledger/common/widgets/delete_confirmation.dart';
import 'package:vintage_ledger/features/quick_add/quick_add_parser.dart';

class LearnedKeywordsScreen extends StatefulWidget {
  const LearnedKeywordsScreen({super.key});

  @override
  State<LearnedKeywordsScreen> createState() => _LearnedKeywordsScreenState();
}

class _LearnedKeywordsScreenState extends State<LearnedKeywordsScreen> {
  List<(String keyword, String categoryId)> _keywords = [];
  Map<String, String> _categoryNames = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await sl.categoryService.getCategories();
    if (!mounted) return;
    setState(() {
      _categoryNames = {for (var c in cats) if (c.id != null) c.id!: c.name};
      _keywords = QuickAddParser.learnedKeywords.reversed.toList();
    });
  }

  Future<void> _clearAll() async {
    final confirm = await showDeleteConfirmation(
      context,
      titleKey: 'clearLearnedKeywords',
      contentKey: 'deleteCategoryConfirm',
    );
    if (confirm != true) return;
    await QuickAddParser.clearLearned();
    if (!mounted) return;
    setState(() => _keywords = []);
  }

  Future<void> _removeKeyword(String keyword) async {
    await QuickAddParser.removeKeyword(keyword);
    if (!mounted) return;
    setState(() => _keywords.removeWhere((e) => e.$1 == keyword));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'clearLearnedKeywords'),
      actions: [
        if (_keywords.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, size: 20, color: AppColors.expense),
            onPressed: _clearAll,
          ),
      ],
      body: _keywords.isEmpty
          ? const EmptyState(message: 'Chưa có từ khóa nào')
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _keywords.length,
              itemBuilder: (context, index) {
                final (keyword, categoryId) = _keywords[index];
                final catName = _categoryNames[categoryId] ?? '?';

                return Dismissible(
                  key: Key(keyword),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    color: AppColors.expense.withValues(alpha: 0.1),
                    child: const Icon(Icons.delete_outline, color: AppColors.expense),
                  ),
                  onDismissed: (_) => _removeKeyword(keyword),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: ListTile(
                      leading: const Icon(Icons.label_outline, size: 20, color: AppColors.primary),
                      title: Text(keyword, style: AppTextStyles.bodyBold),
                      subtitle: Text(catName, style: AppTextStyles.caption),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                        onPressed: () => _removeKeyword(keyword),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      dense: true,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
