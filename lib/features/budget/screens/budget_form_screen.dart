import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/amount_input_field.dart';
import 'package:vintage_ledger/common/widgets/form_save_button.dart';
import 'package:vintage_ledger/common/widgets/app_snackbar.dart';
import 'package:vintage_ledger/features/budget/models/budget.dart';
import 'package:vintage_ledger/features/category/models/category.dart';

class BudgetFormScreen extends StatefulWidget {
  final Budget? budget;
  final String? initialCategoryId;

  const BudgetFormScreen({super.key, this.budget, this.initialCategoryId});

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  List<Category> _categories = [];
  String? _categoryId;

  bool get isEdit => widget.budget != null;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.budget?.categoryId ?? widget.initialCategoryId;
    if (isEdit) _amountCtrl.text = widget.budget!.amountLimit.toString();
    _loadCategories();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final cats = await sl.categoryService.getCategoriesByType('expense');
    setState(() {
      _categories = cats;
      _categoryId ??= cats.firstOrNull?.id;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) return;
    final amount = int.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) return;

    try {
      if (isEdit) {
        await sl.budgetService.updateBudget(widget.budget!.id!, amount);
      } else {
        await sl.budgetService.createBudget(_categoryId!, amount);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.toString(), backgroundColor: const Color(0xFF8B1E1E));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: isEdit ? S.of(context, 'editBudget') : S.of(context, 'setBudget'),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: AppSpacing.md),
              if (!isEdit)
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: InputDecoration(labelText: S.of(context, 'category')),
                  items: _categories.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      children: [
                        Icon(getCategoryIcon(c.icon), size: 20, color: AppColors.inkBlue),
                        const SizedBox(width: 8),
                        Text(c.name, style: AppTextStyles.body),
                      ],
                    ),
                  )).toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                  validator: (v) => v == null ? S.of(context, 'selectCategoryRequired') : null,
                ),
              if (!isEdit) const SizedBox(height: AppSpacing.md),
              AmountInputField(controller: _amountCtrl),
              const SizedBox(height: AppSpacing.lg),
              FormSaveButton(isEdit: isEdit, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
