import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/app_snackbar.dart';
import 'package:vintage_ledger/common/widgets/type_selector.dart';
import 'package:vintage_ledger/common/widgets/amount_input_field.dart';
import 'package:vintage_ledger/common/widgets/form_save_button.dart';
import 'package:vintage_ledger/common/widgets/dropdown_field.dart';
import 'package:vintage_ledger/common/widgets/selection_sheet.dart';
import 'package:vintage_ledger/features/transaction/widgets/category_dropdown.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/features/category/screens/category_form_screen.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/features/recurring/models/recurring_rule.dart';
import 'package:vintage_ledger/features/recurring/services/recurring_service.dart';
import 'package:vintage_ledger/features/debt/models/debt.dart';
import 'package:vintage_ledger/features/goal/models/goal.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

enum _LinkType { none, debt, goal }

class RecurringFormScreen extends StatefulWidget {
  final RecurringRule? existing;

  const RecurringFormScreen({super.key, this.existing});

  bool get isEdit => existing != null;

  @override
  State<RecurringFormScreen> createState() => _RecurringFormScreenState();
}

class _RecurringFormScreenState extends State<RecurringFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  List<Category> _categories = [];
  List<Wallet> _wallets = [];
  List<Debt> _activeDebts = [];
  List<Goal> _activeGoals = [];

  String? _walletId;
  String? _categoryId;
  TransactionType _type = TransactionType.expense;
  Frequency _frequency = Frequency.monthly;
  _LinkType _linkType = _LinkType.none;
  String? _linkedDebtId;
  String? _linkedGoalId;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      final r = widget.existing!;
      _amountCtrl.text = r.amount.toString();
      _type = r.type;
      _categoryId = r.categoryId;
      _walletId = r.walletId;
      _frequency = r.frequency;
      _noteCtrl.text = r.note ?? '';
      _linkedDebtId = r.linkedDebtId;
      _linkedGoalId = r.linkedGoalId;
      if (_linkedDebtId != null) {
        _linkType = _LinkType.debt;
      } else if (_linkedGoalId != null) {
        _linkType = _LinkType.goal;
      }
    } else {
      _amountCtrl.text = '0';
    }
    _loadData();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final allCats = await sl.categoryService.getCategories();
    final cats = allCats.where((c) => c.type?.value == _type.value).toList();
    final wallets = await sl.walletService.getWallets();
    final debts = (await sl.debtService.getTienVayMuon())
        .where((d) => d.status == DebtStatus.active)
        .toList();
    final goals = await sl.goalService.getActiveGoals();
    setState(() {
      _categories = cats;
      _wallets = wallets;
      _activeDebts = debts;
      _activeGoals = goals;
      _categoryId ??= cats.isNotEmpty ? cats.first.id : null;
      _walletId ??= wallets.isNotEmpty ? wallets.first.id : null;
    });
  }

  void _onTypeChanged(String type) {
    final parsed = TransactionType.fromString(type);
    if (_type == parsed) return;
    setState(() => _type = parsed);
    _loadData();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_walletId == null || _categoryId == null) return;

    final amount = int.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      showAppSnackBar(context, S.of(context, 'amountMustBePositive'));
      return;
    }

    final linkedDebtId = _linkType == _LinkType.debt ? _linkedDebtId : null;
    final linkedGoalId = _linkType == _LinkType.goal ? _linkedGoalId : null;

    final now = DateTime.now();
    final nextRun = widget.isEdit
        ? widget.existing!.nextRunAt
        : RecurringService.calcNextRun(_frequency, now.millisecondsSinceEpoch);

    final rule = RecurringRule(
      amount: amount,
      categoryId: _categoryId!,
      walletId: _walletId!,
      type: _type,
      frequency: _frequency,
      note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
      nextRunAt: nextRun,
      linkedDebtId: linkedDebtId,
      linkedGoalId: linkedGoalId,
    );

    final validationError = rule.validateLinkedEntity();
    if (validationError != null) {
      showAppSnackBar(context, validationError, backgroundColor: AppColors.error);
      return;
    }

    try {
      if (widget.isEdit) {
        await sl.recurringService.updateRule(widget.existing!.id!, rule.toMap());
      } else {
        await sl.recurringService.createRule(rule);
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
      title: widget.isEdit ? S.of(context, 'editRecurring') : S.of(context, 'addRecurring'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            TypeSelector(value: _type.value, onChanged: _onTypeChanged),
            const SizedBox(height: AppSpacing.lg),
            AmountInputField(controller: _amountCtrl),
            const SizedBox(height: AppSpacing.md),
            _buildWalletDropdown(),
            const SizedBox(height: AppSpacing.md),
            CategoryDropdown(
              value: _categoryId,
              categories: _categories,
              onChanged: (v) => setState(() => _categoryId = v),
              onAdd: () async {
                final result = await context.pushScreen(CategoryFormScreen(initialType: _type));
                if (result == true) _loadData();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFrequencySelector(),
            const SizedBox(height: AppSpacing.md),
            _buildLinkTypeSelector(),
            if (_linkType == _LinkType.debt) ...[
              const SizedBox(height: AppSpacing.md),
              _buildDebtDropdown(),
            ],
            if (_linkType == _LinkType.goal) ...[
              const SizedBox(height: AppSpacing.md),
              _buildGoalDropdown(),
            ],
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _noteCtrl, maxLines: 2,
              decoration: InputDecoration(
                labelText: S.of(context, 'note'),
                hintText: S.of(context, 'noteHint'),
              ),
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            FormSaveButton(isEdit: widget.isEdit, onPressed: _save),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletDropdown() {
    final walletName = _wallets.where((w) => w.id == _walletId).firstOrNull?.name;
    return DropdownField<String>(
      label: S.of(context, 'selectWallet'),
      value: walletName,
      prefixIcon: Icons.account_balance_wallet_outlined,
      items: _wallets.map((w) => SelectionItem(value: w.id!, label: w.name, icon: Icons.account_balance_wallet_outlined)).toList(),
      selected: _walletId,
      onChanged: (v) => setState(() => _walletId = v),
      validator: (v) => v == null && _walletId == null ? S.of(context, 'selectWalletRequired') : null,
    );
  }

  Widget _buildFrequencySelector() {
    final options = {
      Frequency.daily: S.of(context, 'daily'),
      Frequency.weekly: S.of(context, 'weekly'),
      Frequency.monthly: S.of(context, 'monthly'),
    };
    return DropdownField<Frequency>(
      label: S.of(context, 'frequency'),
      value: options[_frequency],
      items: options.entries.map((e) => SelectionItem(value: e.key, label: e.value)).toList(),
      selected: _frequency,
      onChanged: (v) { if (v != null) setState(() => _frequency = v); },
    );
  }

  Widget _buildLinkTypeSelector() {
    final options = {
      _LinkType.none: S.of(context, 'linkNone'),
      _LinkType.debt: S.of(context, 'linkDebt'),
      _LinkType.goal: S.of(context, 'linkGoal'),
    };
    return DropdownField<_LinkType>(
      label: S.of(context, 'linkWith'),
      value: options[_linkType],
      prefixIcon: Icons.link,
      items: options.entries.map((e) => SelectionItem(value: e.key, label: e.value)).toList(),
      selected: _linkType,
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          _linkType = v;
          if (v != _LinkType.debt) _linkedDebtId = null;
          if (v != _LinkType.goal) _linkedGoalId = null;
        });
      },
    );
  }

  Widget _buildDebtDropdown() {
    final debtName = _activeDebts.where((d) => d.id == _linkedDebtId).firstOrNull?.displayTitle;
    return DropdownField<String>(
      label: S.of(context, 'selectDebt'),
      value: debtName,
      prefixIcon: Icons.receipt_long,
      items: _activeDebts.map((d) => SelectionItem(
        value: d.id,
        label: d.displayTitle,
        icon: Icons.receipt_long,
      )).toList(),
      selected: _linkedDebtId,
      onChanged: (v) => setState(() => _linkedDebtId = v),
    );
  }

  Widget _buildGoalDropdown() {
    final goalName = _activeGoals.where((g) => g.id == _linkedGoalId).firstOrNull?.displayTitle;
    return DropdownField<String>(
      label: S.of(context, 'selectGoal'),
      value: goalName,
      prefixIcon: Icons.flag,
      items: _activeGoals.map((g) => SelectionItem(
        value: g.id,
        label: g.displayTitle,
        icon: Icons.flag,
      )).toList(),
      selected: _linkedGoalId,
      onChanged: (v) => setState(() => _linkedGoalId = v),
    );
  }
}
