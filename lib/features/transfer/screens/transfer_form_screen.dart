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
import 'package:vintage_ledger/common/widgets/amount_input_field.dart';
import 'package:vintage_ledger/common/widgets/form_save_button.dart';
import 'package:vintage_ledger/common/widgets/dropdown_field.dart';
import 'package:vintage_ledger/common/widgets/selection_sheet.dart';

import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/features/wallet/models/account_wallets.dart';
import 'package:vintage_ledger/core/service_locator.dart';

class TransferFormScreen extends StatefulWidget {
  final TransactionWithItems? existing;

  const TransferFormScreen({super.key, this.existing});

  bool get isEdit => existing != null;

  @override
  State<TransferFormScreen> createState() => _TransferFormScreenState();
}

class _TransferFormScreenState extends State<TransferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  List<Wallet> _wallets = [];
  List<AccountWallets> _allAccountWallets = [];
  List<Map<String, dynamic>> _members = [];

  String? _walletId;
  String? _toWalletId;
  String? _toAccountId;
  String? _createdBy;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();

    if (widget.existing != null) {
      final t = widget.existing!.transaction;
      _amountCtrl.text = t.amount > 0 ? t.amount.toString() : '0';
      if (t.walletId.isNotEmpty) _walletId = t.walletId;
      if (t.toWalletId != null) _toWalletId = t.toWalletId;
      if (t.toAccountId != null) _toAccountId = t.toAccountId;
      _date = DateTime.fromMillisecondsSinceEpoch(t.date);
      _noteCtrl.text = t.note ?? '';
      _createdBy = t.createdBy;
    } else {
      _amountCtrl.text = '0';
    }

    _loadWallets();
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
    super.dispose();
  }

  Future<void> _loadWallets() async {
    final list = await sl.walletService.getWallets();
    final lastWalletId = await sl.settingService.getLastWalletId();
    setState(() {
      _wallets = list;
      if (_walletId == null && lastWalletId != null && list.any((w) => w.id == lastWalletId)) {
        _walletId = lastWalletId;
      }
      _walletId ??= _wallets.isNotEmpty ? _wallets.first.id : null;
      // Default toWallet: first wallet that isn't the source
      if (_toWalletId == null && _wallets.length >= 2) {
        _toWalletId = _wallets.where((w) => w.id != _walletId).first.id;
      }
    });
    _loadAllAccountWallets();
  }

  Future<void> _loadAllAccountWallets() async {
    final userId = sl.appState.currentUserId;
    if (userId == null) return;
    final accounts = await sl.accountService.getAccountsForUser(userId);
    final result = <AccountWallets>[];
    for (final a in accounts) {
      final wallets = a.id == sl.appState.currentAccountId
          ? _wallets
          : await sl.walletService.getWalletsForAccount(a.id);
      result.add(AccountWallets(accountId: a.id, accountName: a.name, wallets: wallets));
    }
    if (mounted) setState(() => _allAccountWallets = result);
  }

  Future<void> _loadMembers() async {
    final account = await sl.accountService.getAccount(sl.appState.currentAccountId);
    if (account != null && account.memberIds.length > 1) {
      final profiles = await sl.accountService.getMemberProfiles(account.memberIds);
      if (mounted) setState(() => _members = profiles.cast<Map<String, dynamic>>());
    }
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

    final amount = int.tryParse(_amountCtrl.text) ?? 0;

    if (_toWalletId == null) {
      showAppSnackBar(context, S.of(context, 'selectDestWallet'));
      return;
    }
    if (_walletId == _toWalletId && (_toAccountId == null || _toAccountId == sl.appState.currentAccountId)) {
      showAppSnackBar(context, S.of(context, 'sameWalletError'));
      return;
    }
    if (amount <= 0) {
      showAppSnackBar(context, S.of(context, 'amountMustBePositive'));
      return;
    }

    try {
      if (widget.isEdit) {
        final existing = widget.existing!.transaction;
        await sl.transactionService.updateTransfer(
          txnId: existing.id!,
          linkedTxnId: existing.linkedTransactionId!,
          linkedAccountId: existing.toAccountId,
          oldAmount: existing.amount,
          sourceWalletId: _walletId!,
          destWalletId: _toWalletId!,
          oldSourceWalletId: existing.walletId,
          oldDestWalletId: existing.toWalletId!,
          newAmount: amount,
          note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
          date: _date.millisecondsSinceEpoch,
          createdBy: _createdBy,
        );
      } else {
        await sl.transactionService.createTransfer(
          sourceWalletId: _walletId!,
          destWalletId: _toWalletId!,
          amount: amount,
          note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
          date: _date.millisecondsSinceEpoch,
          destAccountId: _toAccountId,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showAppSnackBar(context, e.toString(), backgroundColor: AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.isEdit ? S.of(context, 'editTransaction') : S.of(context, 'transferTitle'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AmountInputField(controller: _amountCtrl),
            const SizedBox(height: AppSpacing.md),
            _buildSourceWalletDropdown(),
            const SizedBox(height: AppSpacing.md),
            _buildToWalletDropdown(),
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
            TextFormField(
              controller: _noteCtrl, maxLines: 2,
              decoration: InputDecoration(
                labelText: S.of(context, 'note'), hintText: S.of(context, 'noteHint'),
              ),
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (widget.isEdit && _members.length > 1) _buildMemberDropdown(),
            FormSaveButton(isEdit: widget.isEdit, onPressed: _save),
            if (widget.isEdit) _buildDeleteButton(),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceWalletDropdown() {
    final walletName = _wallets.where((w) => w.id == _walletId).firstOrNull?.name;
    return DropdownField<String>(
      label: S.of(context, 'fromWallet'),
      value: walletName,
      prefixIcon: Icons.account_balance_wallet_outlined,
      items: _wallets.map((w) => SelectionItem(value: w.id!, label: w.name, icon: Icons.account_balance_wallet_outlined)).toList(),
      selected: _walletId,
      onChanged: (v) => setState(() => _walletId = v),
      validator: (v) => v == null && _walletId == null ? S.of(context, 'selectWalletRequired') : null,
    );
  }

  Widget _buildToWalletDropdown() {
    final items = <SelectionItem<String>>[];
    String? displayName;

    // Internal transfer: only show wallets from current account
    for (final w in _wallets.where((w) => w.id != _walletId)) {
      items.add(SelectionItem(value: ':${w.id}', label: w.name, icon: Icons.account_balance_wallet_outlined));
      if (w.id == _toWalletId) displayName = w.name;
    }

    return DropdownField<String>(
      label: S.of(context, 'toWallet'),
      value: displayName,
      prefixIcon: Icons.account_balance_wallet_outlined,
      items: items,
      selected: ':$_toWalletId',
      onChanged: (v) {
        if (v == null) return;
        final parts = v.split(':');
        setState(() {
          _toAccountId = parts[0].isNotEmpty ? parts[0] : null;
          _toWalletId = parts[1];
        });
      },
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
        items: _members.map((m) => SelectionItem<String>(value: m['id']!, label: m['name'] ?? '?', icon: Icons.person_outline)).toList(),
        selected: _createdBy,
        onChanged: (v) => setState(() => _createdBy = v),
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
