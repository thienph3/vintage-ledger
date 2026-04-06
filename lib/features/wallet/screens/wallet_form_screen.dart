import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/constants/currency.dart';

import 'package:vintage_ledger/common/widgets/amount_input_field.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/app_snackbar.dart';
import 'package:vintage_ledger/common/widgets/form_save_button.dart';
import 'package:vintage_ledger/common/widgets/amount_history.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';

class WalletFormScreen extends StatefulWidget {
  final Wallet? wallet;

  const WalletFormScreen({super.key, this.wallet});

  @override
  State<WalletFormScreen> createState() => _WalletFormScreenState();
}

class _WalletFormScreenState extends State<WalletFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _initialBalanceCtrl = TextEditingController();
  String _currency = Currency.defaultCurrency.code;
  WalletType _walletType = WalletType.spending;

  bool get isEdit => widget.wallet != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _nameCtrl.text = widget.wallet!.name;
      _initialBalanceCtrl.text = widget.wallet!.initialBalance.toString();
      _currency = widget.wallet!.currency;
      _walletType = widget.wallet!.type;
    } else {
      _initialBalanceCtrl.text = '0';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _initialBalanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final initialBalance = int.tryParse(_initialBalanceCtrl.text) ?? 0;

    try {
      if (isEdit) {
        await sl.walletService.updateWallet(
          widget.wallet!.id!, name,
          currency: _currency,
          type: _walletType != widget.wallet!.type ? _walletType : null,
          initialBalance: initialBalance != widget.wallet!.initialBalance ? initialBalance : null,
        );
      } else {
        await sl.walletService.createWallet(name, initialBalance, currency: _currency, type: _walletType);
      }
      if (!mounted) return;
      if (initialBalance > 0) AmountHistory.record(initialBalance);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.toString(), backgroundColor: AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: isEdit ? S.of(context, 'editWallet') : S.of(context, 'addNewWallet'),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildWalletTypePicker(),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: S.of(context, 'walletName')),
                validator: (v) => v == null || v.trim().isEmpty ? S.of(context, 'walletNameRequired') : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: InputDecoration(labelText: S.of(context, 'currency')),
                items: Currency.all.where((c) => c.code == 'VND').map((c) => DropdownMenuItem(
                  value: c.code,
                  child: Text('${c.symbol}  ${c.code}', style: AppTextStyles.body),
                )).toList(),
                onChanged: (v) => setState(() => _currency = v ?? _currency),
              ),
              const SizedBox(height: AppSpacing.md),
              AmountInputField(
                controller: _initialBalanceCtrl,
                label: S.of(context, 'initialBalance'),
                showZero: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              FormSaveButton(isEdit: isEdit, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletTypePicker() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.divider.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _typePill(WalletType.spending, '💳 ${S.of(context, 'walletTypeSpending')}'),
          const SizedBox(width: 4),
          _typePill(WalletType.savings, '🏦 ${S.of(context, 'walletTypeSavings')}'),
        ],
      ),
    );
  }

  Widget _typePill(WalletType type, String label) {
    final selected = _walletType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _walletType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(label, style: AppTextStyles.buttonLabel.copyWith(
            color: selected ? AppColors.primary : AppColors.textPrimary, fontSize: 16,
          )),
        ),
      ),
    );
  }
}
