// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/app_snackbar.dart';
import 'package:vintage_ledger/common/widgets/amount_input_field.dart';
import 'package:vintage_ledger/common/widgets/form_save_button.dart';
import 'package:vintage_ledger/common/widgets/dropdown_field.dart';
import 'package:vintage_ledger/common/widgets/selection_sheet.dart';

import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/core/service_locator.dart';

class FundingFormScreen extends StatefulWidget {
  const FundingFormScreen({super.key});

  @override
  State<FundingFormScreen> createState() => _FundingFormScreenState();
}

class _FundingFormScreenState extends State<FundingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController(text: '0');
  final _noteCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  List<Wallet> _personalWallets = [];
  List<Wallet> _familyWallets = [];
  String? _familyAccountId;

  String? _sourceWalletId;
  String? _destWalletId;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadWallets();
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
    final userId = sl.appState.currentUserId;
    if (userId == null) return;

    // Load personal wallets (current account)
    final personalWallets = await sl.walletService.getWallets();

    // Find family account and load its wallets
    final accounts = await sl.accountService.getAccountsForUser(userId);
    String? familyAccountId;
    List<Wallet> familyWallets = [];

    for (final a in accounts) {
      if (a.isFamily) {
        familyAccountId = a.id;
        familyWallets = await sl.walletService.getWalletsForAccount(a.id);
        break;
      }
    }

    if (mounted) {
      setState(() {
        _personalWallets = personalWallets;
        _familyWallets = familyWallets;
        _familyAccountId = familyAccountId;
        _sourceWalletId ??= _personalWallets.isNotEmpty ? _personalWallets.first.id : null;
        _destWalletId ??= _familyWallets.isNotEmpty ? _familyWallets.first.id : null;
      });
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
    if (_sourceWalletId == null) return;

    final amount = int.tryParse(_amountCtrl.text) ?? 0;

    if (_destWalletId == null) {
      showAppSnackBar(context, S.of(context, 'selectDestWallet'));
      return;
    }

    try {
      await sl.transactionService.createTransfer(
        sourceWalletId: _sourceWalletId!,
        destWalletId: _destWalletId!,
        amount: amount,
        note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
        date: _date.millisecondsSinceEpoch,
        destAccountId: _familyAccountId,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showAppSnackBar(context, e.toString(), backgroundColor: AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'fundingTitle'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AmountInputField(controller: _amountCtrl),
            const SizedBox(height: AppSpacing.md),
            _buildSourceWalletDropdown(),
            const SizedBox(height: AppSpacing.md),
            _buildDestWalletDropdown(),
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
            FormSaveButton(isEdit: false, onPressed: _save),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceWalletDropdown() {
    final walletName = _personalWallets.where((w) => w.id == _sourceWalletId).firstOrNull?.name;
    return DropdownField<String>(
      label: S.of(context, 'personalWallet'),
      value: walletName,
      prefixIcon: Icons.account_balance_wallet_outlined,
      items: _personalWallets.map((w) => SelectionItem(value: w.id!, label: w.name, icon: Icons.account_balance_wallet_outlined)).toList(),
      selected: _sourceWalletId,
      onChanged: (v) => setState(() => _sourceWalletId = v),
      validator: (v) => v == null && _sourceWalletId == null ? S.of(context, 'selectWalletRequired') : null,
    );
  }

  Widget _buildDestWalletDropdown() {
    final walletName = _familyWallets.where((w) => w.id == _destWalletId).firstOrNull?.name;
    return DropdownField<String>(
      label: S.of(context, 'familyWallet'),
      value: walletName,
      prefixIcon: Icons.family_restroom,
      items: _familyWallets.map((w) => SelectionItem(value: w.id!, label: w.name, icon: Icons.family_restroom)).toList(),
      selected: _destWalletId,
      onChanged: (v) => setState(() => _destWalletId = v),
      validator: (v) => v == null && _destWalletId == null ? S.of(context, 'selectDestWallet') : null,
    );
  }
}
