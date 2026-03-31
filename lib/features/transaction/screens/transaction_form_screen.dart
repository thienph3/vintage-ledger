import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/type_selector.dart';
import 'package:vintage_ledger/common/widgets/amount_input_field.dart';
import 'package:vintage_ledger/common/widgets/form_save_button.dart';

import 'package:vintage_ledger/features/transaction/models/transaction.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_item.dart';
import 'package:vintage_ledger/features/transaction/services/transaction_service.dart';
import 'package:vintage_ledger/features/transaction/widgets/category_dropdown.dart';
import 'package:vintage_ledger/features/transaction/widgets/transaction_item_list.dart';

import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/features/category/services/category_service.dart';
import 'package:vintage_ledger/features/category/screens/category_form_screen.dart';

import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/features/wallet/services/wallet_service.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

class TransactionFormScreen extends StatefulWidget {
  final int? walletId;
  final TransactionModel? transaction;

  const TransactionFormScreen({super.key, this.walletId, this.transaction});

  bool get isEdit => transaction != null;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _txnService = TransactionService();
  final _catService = CategoryService();
  final _walletService = WalletService();

  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  List<Category> _categories = [];
  List<Wallet> _wallets = [];
  List<TransactionItemEntry> _items = [];

  int? _walletId;
  int? _categoryId;
  String _type = 'expense';
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _walletId = widget.walletId;

    if (widget.isEdit) {
      final t = widget.transaction!;
      _amountCtrl.text = t.amount.toString();
      _type = t.type;
      _categoryId = t.categoryId;
      _date = DateTime.fromMillisecondsSinceEpoch(t.date);
      _noteCtrl.text = t.note ?? '';
      _loadItems();
    } else {
      _amountCtrl.text = '0';
    }

    _loadCategories();
    if (widget.walletId == null) _loadWallets();
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
    for (var e in _items) {
      e.dispose();
    }
    super.dispose();
  }

  // ── Data loading ──

  Future<void> _loadCategories() async {
    final list = await _catService.getCategoriesByType(_type);
    setState(() {
      _categories = list;
      if (_categoryId != null && !_categories.any((c) => c.id == _categoryId)) {
        _categoryId = null;
      }
      _categoryId ??= _categories.isNotEmpty ? _categories.first.id : null;
    });
  }

  Future<void> _loadWallets() async {
    final list = await _walletService.getWallets();
    setState(() {
      _wallets = list;
      _walletId ??= _wallets.isNotEmpty ? _wallets.first.id : null;
    });
  }

  Future<void> _loadItems() async {
    if (!widget.isEdit) return;
    final loaded = await _txnService.getTransactionItems(widget.transaction!.id!);
    setState(() {
      _items = loaded
          .map((item) => TransactionItemEntry(
                item: item,
                amountController:
                    TextEditingController(text: item.amount.toString()),
                noteController:
                    TextEditingController(text: item.note ?? ''),
              ))
          .toList();
    });
  }

  // ── Actions ──

  void _onTypeChanged(String type) {
    if (_type == type) return;
    setState(() => _type = type);
    _loadCategories();
  }

  Future<void> _onAddCategory() async {
    final result = await context.pushScreen(
      CategoryFormScreen(initialType: _type),
    );
    if (result == true) await _loadCategories();
  }

  void _addItem() {
    setState(() {
      _items.add(TransactionItemEntry(
        item: TransactionItemModel(
          transactionId: widget.transaction?.id ?? 0,
          amount: 0,
        ),
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
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: Localizations.localeOf(context),
    );
    if (!mounted || pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (!mounted || pickedTime == null) return;

    setState(() {
      _date = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      _updateDateText();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_walletId == null) return;

    var amount = int.tryParse(_amountCtrl.text) ?? 0;
    final itemTotal = _items.fold<int>(
        0, (s, e) => s + (int.tryParse(e.amountController.text) ?? 0));

    if (amount == 0 && itemTotal > 0) {
      amount = itemTotal;
      _amountCtrl.text = amount.toString();
    }

    if (amount <= 0) {
      _showError(S.of(context, 'amountMustBePositive'));
      return;
    }
    if (itemTotal > amount) {
      _showError(S.of(context, 'itemsTotalExceed'));
      return;
    }

    int txnId;
    final txn = TransactionModel(
      id: widget.transaction?.id,
      walletId: _walletId!,
      categoryId: _categoryId!,
      amount: amount,
      type: _type,
      date: _date.millisecondsSinceEpoch,
      note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
    );

    if (widget.isEdit) {
      await _txnService.updateTransaction(txn);
      txnId = txn.id!;
    } else {
      txnId = await _txnService.createTransaction(
        walletId: txn.walletId,
        categoryId: txn.categoryId,
        type: txn.type,
        amount: txn.amount,
        date: txn.date,
        note: txn.note,
      );
    }

    await _saveItems(txnId);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _saveItems(int txnId) async {
    for (var e in _items) {
      final amount = int.tryParse(e.amountController.text) ?? 0;
      if (amount <= 0) continue;
      final item = TransactionItemModel(
        id: e.item.id,
        transactionId: txnId,
        amount: amount,
        note: e.noteController.text.isEmpty ? null : e.noteController.text,
      );
      if (item.id == null) {
        await _txnService.addTransactionItem(item);
      } else {
        await _txnService.updateTransactionItem(item);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.isEdit
          ? S.of(context, 'editTransaction')
          : S.of(context, 'addNewTransaction'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            TypeSelector(value: _type, onChanged: _onTypeChanged),
            const SizedBox(height: AppSpacing.lg),

            // Amount
            AmountInputField(controller: _amountCtrl),
            const SizedBox(height: AppSpacing.md),

            // Wallet (only when not pre-selected)
            if (widget.walletId == null) ...[
              _buildWalletDropdown(),
              const SizedBox(height: AppSpacing.md),
            ],

            // Category
            CategoryDropdown(
              value: _categoryId,
              categories: _categories,
              onChanged: (v) => setState(() => _categoryId = v),
              onAdd: _onAddCategory,
            ),
            const SizedBox(height: AppSpacing.md),

            // Date
            TextFormField(
              readOnly: true,
              controller: _dateCtrl,
              decoration: InputDecoration(
                labelText: S.of(context, 'date'),
                suffixIcon: const Icon(Icons.calendar_today, size: 20),
              ),
              onTap: _pickDateTime,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.md),

            // Items
            TransactionItemList(
              items: _items,
              onAdd: _addItem,
              onRemove: _removeItem,
            ),
            const SizedBox(height: AppSpacing.md),

            // Note
            TextFormField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: S.of(context, 'note'),
                hintText: S.of(context, 'noteHint'),
              ),
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.lg),

            FormSaveButton(isEdit: widget.isEdit, onPressed: _save),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletDropdown() {
    return DropdownButtonFormField<int>(
      value: _walletId,
      decoration: InputDecoration(
        labelText: S.of(context, 'selectWallet'),
      ),
      items: _wallets.map((w) {
        return DropdownMenuItem(
          value: w.id,
          child: Text(w.name, style: AppTextStyles.body),
        );
      }).toList(),
      onChanged: (v) => setState(() => _walletId = v),
      validator: (v) {
        if (v == null) return S.of(context, 'selectWalletRequired');
        return null;
      },
    );
  }
}
