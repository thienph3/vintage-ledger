import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/form_save_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  bool get _isUpgrade => sl.authService.isAnonymous;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;
      final name = _nameCtrl.text.trim();

      if (_isUpgrade) {
        // Link anonymous account to email
        final user = await sl.authService.linkWithEmail(email, password, name);
        if (user != null) {
          // Update Firestore user profile
          await sl.accountService.getOrCreatePersonalAccountId(user.uid, email, name);
        }
      } else {
        // Fresh registration
        final user = await sl.authService.registerWithEmail(email, password, name);
        if (user != null) {
          final accountId = await sl.accountService.createUserWithPersonalAccount(
            userId: user.uid, email: email, displayName: name,
          );
          sl.appState.currentUserId = user.uid;
          sl.appState.currentAccountId = accountId;
        }
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'register'),
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
                  labelText: S.of(context, 'displayName'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? S.of(context, 'displayName') : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: S.of(context, 'email'),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (v) => v == null || !v.contains('@') || !v.contains('.') ? S.of(context, 'email') : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: S.of(context, 'password'),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                validator: (v) => v == null || v.length < 6 ? S.of(context, 'password') : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(_error!, style: AppTextStyles.error),
                ),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : FormSaveButton(isEdit: false, onPressed: _register),
            ],
          ),
        ),
      ),
    );
  }
}
