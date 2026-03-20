import 'package:flutter/material.dart';

import '../../models/wallet.dart';
import '../../services/wallet_service.dart';

import '../../widgets/amount_input_field.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/ledger_header.dart';

class WalletFormScreen extends StatefulWidget {

  final Wallet? wallet;

  const WalletFormScreen({
    super.key,
    this.wallet,
  });

  @override
  State<WalletFormScreen> createState() => _WalletFormScreenState();
}

class _WalletFormScreenState extends State<WalletFormScreen> {

  final WalletService walletService = WalletService();

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

      await walletService.updateWallet(updated.id!, updated.name, updated.balance);

    } else {

      final created = Wallet(
        name: name,
        balance: balance,
        createdAt: DateTime.now().toIso8601String(),
      );

      await walletService.createWallet(created.name, created.balance);

    }

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {

    return AppScaffold(

      title: "",

      body: Padding(

        padding: const EdgeInsets.all(16),

        child: Form(

          key: _formKey,

          child: ListView(

            children: [
              LedgerHeader(
                title: isEdit ? "SỬA VÍ" : "THÊM VÍ MỚI",
                showBackButton: true, // false nếu là home-screen
              ),
              /// NAME
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Tên ví",
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Vui lòng nhập tên ví";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// BALANCE
              AmountInputField(
                controller: balanceController,
              ),
              const SizedBox(height: 24),

              /// SAVE BUTTON
              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: save,
                  child: const Text("Lưu"),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}