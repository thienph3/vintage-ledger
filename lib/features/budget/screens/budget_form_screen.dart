import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/amount_input_field.dart';
import 'package:vintage_ledger/common/widgets/form_save_button.dart';
import 'package:vintage_ledger/common/widgets/dropdown_field.dart';
import 'package:vintage_ledger/common/widgets/selection_sheet.dart';
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
  BudgetPeriod _period = BudgetPeriod.monthly;

  bool get isEdit => widget.budget != null;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.budget?.categoryId ?? widget.initialCategoryId;
    if (isEdit) {
      _amountCtrl.text = widget.budget!.amountLimit.toString();
      _period = widget.budget!.period;
    }
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
        await sl.budgetService.updateBudget(widget.budget!.id!, amount, period: _period);
      } else {
        await sl.budgetService.createBudget(_categoryId!, amount, period: _period);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.toString(), backgroundColor: AppColors.error);
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
                DropdownField<String>(
                  label: S.of(context, 'category'),
                  value: _categories.where((c) => c.id == _categoryId).firstOrNull?.name,
                  prefixIcon: Icons.category_outlined,
                  items: _categories.map((c) => SelectionItem(
                    value: c.id!,
                    label: c.name,
                    icon: getCategoryIcon(c.icon),
                    color: AppColors.expense,
                  )).toList(),
                  selected: _categoryId,
                  onChanged: (v) => setState(() => _categoryId = v),
                  validator: (v) => v == null && _categoryId == null ? S.of(context, 'selectCategoryRequired') : null,
                ),
              if (!isEdit) const SizedBox(height: AppSpacing.md),
              _buildPeriodSelector(),
              const SizedBox(height: AppSpacing.md),
              AmountInputField(controller: _amountCtrl),
              const SizedBox(height: AppSpacing.lg),
              FormSaveButton(isEdit: isEdit, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: BudgetPeriod.values.map((p) {
        final selected = _period == p;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: p != BudgetPeriod.values.last ? AppSpacing.sm : 0),
            child: GestureDetector(
              onTap: () => setState(() => _period = p),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.divider,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    S.of(context, p.l10nKey),
                    style: selected
                        ? TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)
                        : null,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
