// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/app_snackbar.dart';
import 'package:vintage_ledger/common/widgets/delete_confirmation.dart';
import 'package:vintage_ledger/common/widgets/type_selector.dart';
import 'package:vintage_ledger/common/widgets/amount_input_field.dart';
import 'package:vintage_ledger/common/widgets/form_save_button.dart';
import 'package:vintage_ledger/common/widgets/dropdown_field.dart';
import 'package:vintage_ledger/common/widgets/selection_sheet.dart';

import 'package:vintage_ledger/features/transaction/models/transaction.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_item.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/features/transaction/widgets/category_dropdown.dart';
import 'package:vintage_ledger/features/transaction/widgets/transaction_item_list.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';

import 'package:vintage_ledger/features/recurring/models/recurring_rule.dart';
import 'package:vintage_ledger/features/recurring/services/recurring_service.dart';
import 'package:vintage_ledger/common/widgets/amount_history.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/features/category/screens/category_form_screen.dart';
import 'package:vintage_ledger/features/budget/models/budget_status.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';
import 'package:vintage_ledger/core/service_locator.dart';

class TransactionFormScreen extends StatefulWidget {
  final String? walletId;
  final TransactionWithItems? existing;
  final TransactionWithItems? prefill;

  const TransactionFormScreen({super.key, this.walletId, this.existing, this.prefill});

  bool get isEdit => existing != null;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  List<Category> _categories = [];
  List<Wallet> _wallets = [];
  List<TransactionItemEntry> _items = [];

  String? _walletId;
  String? _toWalletId;
  String? _categoryId;
  String? _createdBy;
  TransactionType _type = TransactionType.expense;
  TransactionType? _originalType;
  String? _originalWalletId;
  DateTime _date = DateTime.now();
  BudgetStatus? _budgetStatus;
  bool _recurring = false;
  Frequency _frequency = Frequency.monthly;
  List<Map<String, String>> _members = [];

  @override
  void initState() {
    super.initState();
    _walletId = widget.walletId;

    final source = widget.existing ?? widget.prefill;
    if (source != null) {
      final t = source.transaction;
      _amountCtrl.text = t.amount > 0 ? t.amount.toString() : '0';
      _type = t.type;
      _originalType = t.type;
      _originalWalletId = t.walletId;
      if (t.categoryId.isNotEmpty) _categoryId = t.categoryId;
      if (t.walletId.isNotEmpty) _walletId = t.walletId;
      _date = DateTime.fromMillisecondsSinceEpoch(t.date);
      _noteCtrl.text = t.note ?? '';
      _createdBy = t.createdBy;
      _items = source.items.map((i) => TransactionItemEntry(
        item: i,
        amountController: TextEditingController(text: i.amount.toString()),
        noteController: TextEditingController(text: i.note ?? ''),
      )).toList();
    } else {
      _amountCtrl.text = '0';
    }

    _loadCategories();
    if (widget.walletId == null) _loadWallets();
    _loadMembers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDateText();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _dateCtrl.dispose();
    for (var e in _items) { e.dispose(); }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final list = sl.cache.categories.where((c) => c.type?.value == _type.value).toList();
    setState(() {
      _categories = list;
      if (_categoryId != null && !_categories.any((c) => c.id == _categoryId)) {
        _categoryId = null;
      }
      _categoryId ??= _categories.isNotEmpty ? _categories.first.id : null;
    });
    _checkBudget();
  }

  Future<void> _loadWallets() async {
    final list = await sl.walletService.getWallets();
    final lastWalletId = sl.cache.lastWalletId;
    setState(() {
      _wallets = list;
      if (_walletId == null && lastWalletId != null && list.any((w) => w.id == lastWalletId)) {
        _walletId = lastWalletId;
      }
      _walletId ??= _wallets.isNotEmpty ? _wallets.first.id : null;
    });
  }

  Future<void> _loadMembers() async {
    final account = sl.cache.currentAccount;
    if (account != null && account.memberIds.length > 1) {
      setState(() => _members = sl.cache.memberProfiles);
    }
  }

  void _onTypeChanged(String type) {
    final parsed = TransactionType.fromString(type);
    if (_type == parsed) return;
    setState(() { _type = parsed; _budgetStatus = null; _toWalletId = null; });
    if (!parsed.isTransfer) _loadCategories();
  }

  Future<void> _checkBudget() async {
    if (_categoryId == null || _type != TransactionType.expense) {
      setState(() => _budgetStatus = null);
      return;
    }
    final status = await sl.budgetService.checkBudget(_categoryId!);
    if (!mounted) return;
    setState(() => _budgetStatus = status);
  }

  Future<void> _onAddCategory() async {
    final result = await context.pushScreen(CategoryFormScreen(initialType: _type));
    if (result == true) await _loadCategories();
  }

  void _addItem() {
    setState(() {
      _items.add(TransactionItemEntry(
        item: TransactionItemModel(amount: 0),
        amountController: TextEditingController(),
        noteController: TextEditingController(),
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  void _updateDateText() {
    final locale = Localizations.localeOf(context).toString();
    _dateCtrl.text = DateFormat('dd/MM/yyyy HH:mm', locale).format(_date);
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime(2000), lastDate: DateTime(2100),
      locale: Localizations.localeOf(context),
    );
    if (!mounted || pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context, initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (!mounted || pickedTime == null) return;

    setState(() {
      _date = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
      _updateDateText();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_walletId == null) return;

    var amount = int.tryParse(_amountCtrl.text) ?? 0;

    if (_type.isTransfer) {
      if (_toWalletId == null) {
        showAppSnackBar(context, S.of(context, 'selectDestWallet'));
        return;
      }
      if (_walletId == _toWalletId) {
        showAppSnackBar(context, S.of(context, 'sameWalletError'));
        return;
      }
      if (amount <= 0) {
        showAppSnackBar(context, S.of(context, 'amountMustBePositive'));
        return;
      }
      try {
        await sl.transactionService.createTransfer(
          sourceWalletId: _walletId!,
          destWalletId: _toWalletId!,
          amount: amount,
          note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
          date: _date.millisecondsSinceEpoch,
        );
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) showAppSnackBar(context, e.toString(), backgroundColor: AppColors.error);
      }
      return;
    }

    if (_categoryId == null) return;
    final itemTotal = _items.fold<int>(0, (s, e) => s + (int.tryParse(e.amountController.text) ?? 0));

    if (amount == 0 && itemTotal > 0) {
      amount = itemTotal;
      _amountCtrl.text = amount.toString();
    }
    if (amount <= 0) {
      showAppSnackBar(context, S.of(context, 'amountMustBePositive'));
      return;
    }
    if (itemTotal > amount) {
      showAppSnackBar(context, S.of(context, 'itemsTotalExceed'));
      return;
    }

    final items = _items
        .map((e) => TransactionItemModel(
              amount: int.tryParse(e.amountController.text) ?? 0,
              note: e.noteController.text.isEmpty ? null : e.noteController.text,
            ))
        .where((i) => i.amount > 0)
        .toList();

    try {
      if (widget.isEdit) {
        await sl.transactionService.updateTransaction(TransactionWithItems(
          transaction: TransactionModel(
            id: widget.existing!.transaction.id,
            walletId: _walletId!,
            categoryId: _categoryId!,
            amount: amount,
            type: _type,
            date: _date.millisecondsSinceEpoch,
            note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
            createdBy: _createdBy ?? widget.existing!.transaction.createdBy,
          ),
          items: items,
        ));
      } else {
        await sl.transactionService.createTransaction(
          walletId: _walletId!,
          categoryId: _categoryId!,
          type: _type,
          amount: amount,
          date: _date.millisecondsSinceEpoch,
          note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
          items: items,
        );
      }
      if (!mounted) return;
      // Persist last used wallet
      sl.settingService.setLastWalletId(_walletId!);

      // Create recurring rule if toggled
      if (_recurring && !widget.isEdit) {
        await sl.recurringService.createRule(RecurringRule(
          amount: amount,
          categoryId: _categoryId!,
          walletId: _walletId!,
          type: _type,
          frequency: _frequency,
          note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
          nextRunAt: RecurringService.calcNextRun(_frequency, _date.millisecondsSinceEpoch),
        ));
      }

      AmountHistory.record(amount);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.toString(), backgroundColor: AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.isEdit ? S.of(context, 'editTransaction') : S.of(context, 'addNewTransaction'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            TypeSelector(value: _type.value, onChanged: _onTypeChanged),
            const SizedBox(height: AppSpacing.lg),
            AmountInputField(controller: _amountCtrl),
            const SizedBox(height: AppSpacing.md),
            if (widget.walletId == null) ...[
              _buildWalletDropdown(),
              const SizedBox(height: AppSpacing.md),
            ],
            if (_type.isTransfer) ...[
              _buildToWalletDropdown(),
              const SizedBox(height: AppSpacing.md),
            ],
            if (!_type.isTransfer) ...[
              CategoryDropdown(
              value: _categoryId,
              categories: _categories,
              onChanged: (v) {
                setState(() => _categoryId = v);
                _checkBudget();
              },
              onAdd: _onAddCategory,
              ),
            ],
            if (!_type.isTransfer && _budgetStatus != null && (_budgetStatus!.isNearLimit || _budgetStatus!.isExceeded))
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      _budgetStatus!.isExceeded ? Icons.warning_amber : Icons.info_outline,
                      size: 16,
                      color: _budgetStatus!.isExceeded ? AppColors.expense : AppColors.accent,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _budgetStatus!.isExceeded
                            ? S.of(context, 'budgetExceeded')
                            : '${S.of(context, 'budgetNearLimit')}: ${S.of(context, 'remaining')} ${_budgetStatus!.remaining}',
                        style: AppTextStyles.caption.copyWith(
                          color: _budgetStatus!.isExceeded ? AppColors.expense : AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              readOnly: true, controller: _dateCtrl,
              decoration: InputDecoration(
                labelText: S.of(context, 'date'),
                suffixIcon: const Icon(Icons.calendar_today, size: 20),
              ),
              onTap: _pickDateTime, style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.md),
            if (!_type.isTransfer) ...[
              TransactionItemList(items: _items, onAdd: _addItem, onRemove: _removeItem),
              const SizedBox(height: AppSpacing.md),
            ],
            TextFormField(
              controller: _noteCtrl, maxLines: 2,
              decoration: InputDecoration(
                labelText: S.of(context, 'note'), hintText: S.of(context, 'noteHint'),
              ),
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (!_type.isTransfer && widget.isEdit && _members.length > 1) _buildMemberDropdown(),
            if (!_type.isTransfer && !widget.isEdit) _buildRecurringToggle(),
            if (widget.isEdit) _buildTypeChangeWarning(),
            if (widget.isEdit) _buildWalletChangeInfo(),
            FormSaveButton(isEdit: widget.isEdit, onPressed: _save),
            if (widget.isEdit) _buildDeleteButton(),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletDropdown() {
    final walletName = _wallets.where((w) => w.id == _walletId).firstOrNull?.name;
    return DropdownField<String>(
      label: _type.isTransfer ? S.of(context, 'fromWallet') : S.of(context, 'selectWallet'),
      value: walletName,
      prefixIcon: Icons.account_balance_wallet_outlined,
      items: _wallets.map((w) => SelectionItem(value: w.id!, label: w.name, icon: Icons.account_balance_wallet_outlined)).toList(),
      selected: _walletId,
      onChanged: (v) => setState(() => _walletId = v),
      validator: (v) => v == null && _walletId == null ? S.of(context, 'selectWalletRequired') : null,
    );
  }

  Widget _buildToWalletDropdown() {
    final walletName = _wallets.where((w) => w.id == _toWalletId).firstOrNull?.name;
    final available = _wallets.where((w) => w.id != _walletId).toList();
    return DropdownField<String>(
      label: S.of(context, 'toWallet'),
      value: walletName,
      prefixIcon: Icons.account_balance_wallet_outlined,
      items: available.map((w) => SelectionItem(value: w.id!, label: w.name, icon: Icons.account_balance_wallet_outlined)).toList(),
      selected: _toWalletId,
      onChanged: (v) => setState(() => _toWalletId = v),
      validator: (v) => v == null && _toWalletId == null ? S.of(context, 'selectDestWallet') : null,
    );
  }

  Widget _buildMemberDropdown() {
    final currentName = _members.where((m) => m['id'] == _createdBy).firstOrNull?['name'] ?? '?';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DropdownField<String>(
        label: S.of(context, 'member'),
        value: currentName,
        prefixIcon: Icons.person_outline,
        items: _members.map((m) => SelectionItem(value: m['id']!, label: m['name'] ?? '?', icon: Icons.person_outline)).toList(),
        selected: _createdBy,
        onChanged: (v) => setState(() => _createdBy = v),
      ),
    );
  }

  Widget _buildRecurringToggle() {
    return Column(
      children: [
        SwitchListTile(
          title: Text(S.of(context, 'recurring'), style: AppTextStyles.body),
          secondary: const Icon(Icons.repeat, color: AppColors.primary),
          value: _recurring,
          onChanged: (v) => setState(() => _recurring = v),
          contentPadding: EdgeInsets.zero,
        ),
        if (_recurring)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: DropdownField<Frequency>(
              label: S.of(context, 'frequency'),
              value: {
                Frequency.daily: S.of(context, 'daily'),
                Frequency.weekly: S.of(context, 'weekly'),
                Frequency.monthly: S.of(context, 'monthly'),
              }[_frequency],
              items: [
                SelectionItem(value: Frequency.daily, label: S.of(context, 'daily')),
                SelectionItem(value: Frequency.weekly, label: S.of(context, 'weekly')),
                SelectionItem(value: Frequency.monthly, label: S.of(context, 'monthly')),
              ],
              selected: _frequency,
              onChanged: (v) { if (v != null) setState(() => _frequency = v); },
            ),
          ),
      ],
    );
  }

  Widget _buildTypeChangeWarning() {
    if (_originalType == null || _type == _originalType) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 14, color: AppColors.accent),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(S.of(context, 'typeChangeWarning'), style: AppTextStyles.caption.copyWith(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletChangeInfo() {
    if (_originalWalletId == null || _walletId == _originalWalletId) return const SizedBox.shrink();
    final walletName = _wallets.where((w) => w.id == _walletId).firstOrNull?.name ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 14, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              S.of(context, 'walletChangeInfo').replaceAll('{name}', walletName),
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            final confirm = await showDeleteConfirmation(
              context, titleKey: 'deleteTransaction', contentKey: 'deleteTransactionConfirm',
            );
            if (confirm != true || !mounted) return;
            await sl.transactionService.deleteTransaction(widget.existing!.transaction.id!);
            if (mounted) Navigator.pop(context, true);
          },
          icon: const Icon(Icons.delete_outline, size: 18),
          label: Text(S.of(context, 'deleteTransaction')),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.expense),
        ),
      ),
    );
  }
}
