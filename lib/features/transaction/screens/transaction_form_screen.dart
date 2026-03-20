import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/features/transaction/models/transaction.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_item.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';

import 'package:vintage_ledger/features/transaction/services/transaction_service.dart';
import 'package:vintage_ledger/features/category/services/category_service.dart';
import 'package:vintage_ledger/features/wallet/services/wallet_service.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/amount_input_field.dart';

import 'package:vintage_ledger/features/category/screens/category_form_screen.dart';

class TransactionFormScreen extends StatefulWidget {
  final int? walletId;
  final TransactionModel? transaction;

  const TransactionFormScreen({super.key, this.walletId, this.transaction});

  bool get isEdit => transaction != null;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class TransactionItemWithController {
  final TransactionItemModel item;
  final TextEditingController amountController;
  final TextEditingController noteController;

  TransactionItemWithController({
    required this.item,
    required this.amountController,
    required this.noteController,
  });
}

class TransactionWithItemsHelper {
  final TransactionModel transaction;
  final List<TransactionItemWithController> items;

  TransactionWithItemsHelper({
    required this.transaction,
    this.items = const [],
  });

  int get totalItemAmount => items.fold(
    0,
    (sum, i) => sum + (int.tryParse(i.amountController.text) ?? 0),
  );

  int get remainingAmount => transaction.amount - totalItemAmount;
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final TransactionService transactionService = TransactionService();
  final CategoryService categoryService = CategoryService();
  final WalletService walletService = WalletService();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  List<Category> categories = [];
  List<Wallet> wallets = [];

  int? selectedWalletId;
  int type = -1;
  int? categoryId;

  DateTime date = DateTime.now();

  List<TransactionItemWithController> items = [];

  @override
  void initState() {
    super.initState();

    selectedWalletId = widget.walletId;

    loadCategories();

    if (widget.walletId == null) {
      loadWallets();
    }

    if (widget.isEdit) {
      final txn = widget.transaction!;
      amountController.text = txn.amount.toString();
      type = txn.type == "income" ? 1 : -1;
      categoryId = txn.categoryId;
      date = DateTime.fromMillisecondsSinceEpoch(txn.date);
      noteController.text = txn.note ?? '';

      loadItems();
    } else {
      amountController.text = "0";
    }

    _updateDateText();
  }

  void _updateDateText() {
    dateController.text = DateFormat('dd/MM/yyyy HH:mm', 'vi_VN').format(date);
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    dateController.dispose();
    for (var item in items) {
      item.amountController.dispose();
      item.noteController.dispose();
    }
    super.dispose();
  }

  Future<void> loadCategories() async {
    final list = await categoryService.getCategories();

    setState(() {
      categories = list;

      if (categoryId != null && !categories.any((c) => c.id == categoryId)) {
        categoryId = null;
      }

      categoryId ??= categories.isNotEmpty ? categories.first.id : null;
    });
  }

  Future<void> loadWallets() async {
    final list = await walletService.getWallets();

    setState(() {
      wallets = list;
      selectedWalletId ??= wallets.isNotEmpty ? wallets.first.id : null;
    });
  }

  Future<void> loadItems() async {
    if (!widget.isEdit) return;

    final loadedItems = await transactionService.getTransactionItems(
      widget.transaction!.id!,
    );

    setState(() {
      items = loadedItems.map((item) {
        return TransactionItemWithController(
          item: item,
          amountController: TextEditingController(text: item.amount.toString()),
          noteController: TextEditingController(text: item.note ?? ''),
        );
      }).toList();
    });
  }

  Future<void> pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: Localizations.localeOf(context),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: TextTheme(
              titleLarge: AppTextStyles.title,
              bodyMedium: AppTextStyles.body,
            ),
            colorScheme: ColorScheme.light(
              primary: AppColors.inkBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.inkBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(date),
      builder: (builderContext, child) {
        return Localizations.override(
          context: builderContext,
          locale: Localizations.localeOf(context),
          child: child!,
        );
      },
    );

    if (!mounted || pickedTime == null) return;

    final picked = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      date = picked;
      _updateDateText();
    });
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedWalletId == null) return;

    var txnAmount = int.tryParse(amountController.text) ?? 0;

    txnAmount = int.tryParse(amountController.text) ?? 0;

    final totalItemAmount = items.fold<int>(0, (sum, item) {
      return sum + (int.tryParse(item.amountController.text) ?? 0);
    });

    if (txnAmount == 0 && totalItemAmount > 0) {
      txnAmount = totalItemAmount;
      amountController.text = txnAmount.toString();
    }

    if (txnAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context, 'amountMustBePositive')),
          backgroundColor: AppColors.divider,
        ),
      );
      return;
    }

    if (totalItemAmount > txnAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context, 'itemsTotalExceed')),
          backgroundColor: AppColors.divider,
        ),
      );
      return;
    }

    int txnId;

    if (widget.isEdit) {
      final txn = widget.transaction!;

      final updatedTxn = TransactionModel(
        id: txn.id,
        walletId: selectedWalletId!,
        categoryId: categoryId!,
        amount: txnAmount,
        type: type == 1 ? "income" : "expense",
        date: date.millisecondsSinceEpoch,
        note: noteController.text.isEmpty ? null : noteController.text,
      );

      await transactionService.updateTransaction(updatedTxn);
      txnId = txn.id!;
    } else {
      txnId = await transactionService.createTransaction(
        walletId: selectedWalletId!,
        categoryId: categoryId!,
        type: type == 1 ? "income" : "expense",
        amount: txnAmount,
        date: date.millisecondsSinceEpoch,
        note: noteController.text.isEmpty ? null : noteController.text,
      );
    }

    for (var itemCtrl in items) {
      final itemAmount = int.tryParse(itemCtrl.amountController.text) ?? 0;
      if (itemAmount <= 0) continue;

      final item = TransactionItemModel(
        id: itemCtrl.item.id,
        transactionId: txnId,
        amount: itemAmount,
        note: itemCtrl.noteController.text.isEmpty
            ? null
            : itemCtrl.noteController.text,
      );

      if (item.id == null) {
        await transactionService.addTransactionItem(item);
      } else {
        await transactionService.updateTransactionItem(item);
      }
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.isEdit
          ? S.of(context, 'editTransaction')
          : S.of(context, 'addNewTransaction'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              /// TYPE
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => type = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: type == 1
                                ? AppColors.inkBlue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            S.of(context, 'income'),
                            style: AppTextStyles.body.copyWith(
                              color: type == 1
                                  ? Colors.white
                                  : AppColors.inkBlue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => type = -1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: type == -1
                                ? AppColors.inkBlue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            S.of(context, 'expense'),
                            style: AppTextStyles.body.copyWith(
                              color: type == -1
                                  ? Colors.white
                                  : AppColors.inkBlue,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// AMOUNT
              AmountInputField(controller: amountController),

              const SizedBox(height: 16),

              if (widget.walletId == null) ...[
                DropdownButtonFormField<int>(
                  initialValue: selectedWalletId,
                  decoration: InputDecoration(
                    labelText: S.of(context, 'selectWallet'),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    labelStyle: AppTextStyles.body.copyWith(
                      color: AppColors.inkPurple,
                    ),
                  ),
                  items: wallets.map((w) {
                    return DropdownMenuItem(
                      value: w.id,
                      child: Text(w.name, style: AppTextStyles.body),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => selectedWalletId = v),
                  validator: (v) {
                    if (v == null) return S.of(context, 'selectWalletRequired');
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              /// CATEGORY
              DropdownButtonFormField<int>(
                initialValue: categoryId,
                decoration: InputDecoration(
                  labelText: S.of(context, 'category'),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  labelStyle: AppTextStyles.body.copyWith(
                    color: AppColors.inkPurple,
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: -1,
                    child: Row(
                      children: [
                        const Icon(Icons.add, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          S.of(context, 'addCategory'),
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                  ),
                  ...categories.map((c) {
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name, style: AppTextStyles.body),
                    );
                  }),
                ],
                onChanged: (v) async {
                  if (v == -1) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CategoryFormScreen(),
                      ),
                    );

                    if (result == true) {
                      await loadCategories();
                    }
                    return;
                  }

                  setState(() => categoryId = v);
                },
                validator: (v) {
                  if (v == null || v == -1)
                    return S.of(context, 'categoryNameRequired');
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// DATE
              TextFormField(
                readOnly: true,
                controller: dateController,
                decoration: InputDecoration(
                  labelText: S.of(context, 'date'),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  labelStyle: AppTextStyles.body.copyWith(
                    color: AppColors.inkPurple,
                  ),
                ),
                onTap: pickDateTime,
                style: AppTextStyles.body,
              ),

              const SizedBox(height: 16),

              /// TRANSACTION ITEMS
              if (widget.isEdit || true) ...[
                Text(
                  S.of(context, 'transactionDetails'),
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: 8),
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final itemCtrl = entry.value;
                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: itemCtrl.noteController,
                          decoration: InputDecoration(
                            hintText: S.of(context, 'itemNameHint'),
                            labelText: S.of(context, 'itemName'),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: AmountInputField(
                          controller: itemCtrl.amountController,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => setState(() => items.removeAt(index)),
                      ),
                    ],
                  );
                }),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      items.add(
                        TransactionItemWithController(
                          item: TransactionItemModel(
                            transactionId: widget.transaction?.id ?? 0,
                            amount: 0,
                          ),
                          amountController: TextEditingController(),
                          noteController: TextEditingController(),
                        ),
                      );
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: Text(S.of(context, 'addItem')),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: S.of(context, 'note'),
                  hintText: S.of(context, 'noteHint'),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  labelStyle: AppTextStyles.body.copyWith(
                    color: AppColors.inkPurple,
                  ),
                  hintStyle: AppTextStyles.body.copyWith(
                    color: AppColors.inkBlue,
                  ),
                ),
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: save,
                child: Text(
                  widget.isEdit
                      ? S.of(context, 'update')
                      : S.of(context, 'save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
