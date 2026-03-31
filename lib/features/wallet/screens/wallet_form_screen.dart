import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/core/service_locator.dart';

import 'package:vintage_ledger/common/widgets/amount_input_field.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/form_save_button.dart';

class WalletFormScreen extends StatefulWidget {
  final Wallet? wallet;

  const WalletFormScreen({super.key, this.wallet});

  @override
  State<WalletFormScreen> createState() => _WalletFormScreenState();
}

class _WalletFormScreenState extends State<WalletFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController balanceController = TextEditingController();

  bool isEdit = false;

  @override
  void initState() {
    super.initState();

    if (widget.wallet != null) {
      isEdit = true;
      nameController.text = widget.wallet!.name;
      balanceController.text = widget.wallet!.balance.toString();
    } else {
      balanceController.text = "0";
    }
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = nameController.text.trim();
    final balance = int.tryParse(balanceController.text) ?? 0;

    if (isEdit) {
      final updated = Wallet(
        id: widget.wallet!.id,
        name: name,
        balance: balance,
        createdAt: widget.wallet!.createdAt,
      );

      await sl.walletService.updateWallet(
        updated.id!,
        updated.name,
        updated.balance,
      );
    } else {
      final created = Wallet(
        name: name,
        balance: balance,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await sl.walletService.createWallet(created.name, created.balance);
    }

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: isEdit
          ? S.of(context, 'editWallet')
          : S.of(context, 'addNewWallet'),
      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Form(
          key: _formKey,

          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: S.of(context, 'walletName'),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return S.of(context, 'walletNameRequired');
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              AmountInputField(controller: balanceController),
              const SizedBox(height: 24),

              FormSaveButton(isEdit: isEdit, onPressed: save),
            ],
          ),
        ),
      ),
    );
  }
}
