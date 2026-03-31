import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/form_save_button.dart';

class FamilyFormScreen extends StatefulWidget {
  const FamilyFormScreen({super.key});

  @override
  State<FamilyFormScreen> createState() => _FamilyFormScreenState();
}

class _FamilyFormScreenState extends State<FamilyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await sl.accountService.createFamilyAccount(
        userId: sl.appState.currentUserId!,
        name: _nameCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'createFamily'),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: S.of(context, 'familyName'),
                  prefixIcon: const Icon(Icons.family_restroom),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? S.of(context, 'familyName') : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(_error!, style: AppTextStyles.error),
                ),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : FormSaveButton(isEdit: false, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
