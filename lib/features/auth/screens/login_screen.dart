import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/error_mapper.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/locale_toggle.dart';
import 'package:vintage_ledger/features/account/screens/account_picker_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? anonAccountIdToMigrate;

  const LoginScreen({super.key, this.anonAccountIdToMigrate});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;
  bool _showEmailLogin = false;

  // Email form (deprecated)
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = await sl.authService.signInWithGoogle();
      if (!mounted || user == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      sl.appState.currentUserId = user.uid;
      final accountId = await sl.accountService.getOrCreatePersonalAccountId(
        user.uid, user.email ?? '', user.displayName ?? '',
      );
      sl.appState.currentAccountId = accountId;
      sl.settingService.setLastAccountId(accountId);

      // Sync Google profile
      await sl.accountService.updateUserProfile(
        userId: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
      );

      // Migrate anonymous data
      if (widget.anonAccountIdToMigrate != null && widget.anonAccountIdToMigrate!.isNotEmpty) {
        await sl.accountService.migrateAccount(widget.anonAccountIdToMigrate!, accountId);
        await sl.accountService.deleteAccount(widget.anonAccountIdToMigrate!);
      }

      _goHome();
    } catch (e) {
      final mapped = ErrorMapper.map(e);
      if (mounted) setState(() { _loading = false; _error = S.of(context, mapped.message); });
    }
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final user = await sl.authService.loginWithEmail(
        _emailCtrl.text.trim(), _passwordCtrl.text,
      );
      if (!mounted || user == null) return;

      sl.appState.currentUserId = user.uid;
      final accountId = await sl.accountService.getOrCreatePersonalAccountId(
        user.uid, user.email!, user.displayName ?? '',
      );
      sl.appState.currentAccountId = accountId;
      sl.settingService.setLastAccountId(accountId);

      if (widget.anonAccountIdToMigrate != null && widget.anonAccountIdToMigrate!.isNotEmpty) {
        await sl.accountService.migrateAccount(widget.anonAccountIdToMigrate!, accountId);
        await sl.accountService.deleteAccount(widget.anonAccountIdToMigrate!);
      }

      _goHome();
    } catch (e) {
      final mapped = ErrorMapper.map(e);
      if (mounted) setState(() { _loading = false; _error = S.of(context, mapped.message); });
    }
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AccountPickerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ListView(
            children: [
              const Align(alignment: Alignment.topRight, child: LocaleToggle()),
              const SizedBox(height: AppSpacing.xl),
              const Icon(Icons.menu_book_rounded, size: 64, color: AppColors.primary),
              const SizedBox(height: AppSpacing.md),
              Text('Vintage Ledger', style: AppTextStyles.title, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(S.of(context, 'anonymousExplanation'), style: AppTextStyles.hint, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(_error!, style: AppTextStyles.error, textAlign: TextAlign.center),
                ),

              // Google SSO — primary
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: const Icon(Icons.g_mobiledata, size: 24),
                        label: Text(S.of(context, 'signInWithGoogle')),
                      ),
                    ),
              const SizedBox(height: AppSpacing.lg),

              // Email login — deprecated, hidden by default
              GestureDetector(
                onTap: () => setState(() => _showEmailLogin = !_showEmailLogin),
                child: Text(
                  S.of(context, 'loginWithEmail'),
                  style: AppTextStyles.link,
                  textAlign: TextAlign.center,
                ),
              ),

              if (_showEmailLogin) ...[
                const SizedBox(height: AppSpacing.md),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: S.of(context, 'email'),
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        validator: (v) => v == null || !v.contains('@') ? S.of(context, 'invalidEmail') : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: S.of(context, 'password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                        validator: (v) => v == null || v.length < 6 ? S.of(context, 'weakPassword') : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _loading ? null : _loginWithEmail,
                          child: Text(S.of(context, 'login')),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
