import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/locale_toggle.dart';
import 'package:vintage_ledger/core/database.dart';
import 'package:vintage_ledger/features/auth/screens/register_screen.dart';
import 'package:vintage_ledger/features/account/screens/account_picker_screen.dart';
import 'package:vintage_ledger/features/home/screens/home_screen.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await sl.authService.loginWithEmail(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (!mounted || user == null) return;

      // Set app state
      sl.appState.currentUserId = user.uid;
      final accountId = await sl.accountService.getOrCreatePersonalAccountId(
        user.uid, user.email!, user.displayName ?? '',
      );
      sl.appState.currentAccountId = accountId;

      // Migrate local data
      await AppDatabase.instance.migrateLocalDataToAccount(accountId);

      // Import from cloud if available
      if (mounted) await _maybeImportFromCloud(accountId);

      _goAccountPicker();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _maybeImportFromCloud(String accountId) async {
    try {
      final wallets = await sl.walletService.getWallets();
      if (wallets.isEmpty) {
        await sl.syncService.syncAccount(accountId);
      }
    } catch (_) {}
  }

  Future<void> _skip() async {
    await sl.settingService.markSetupDone();
    if (!mounted) return;
    _goHome();
  }

  void _goAccountPicker() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AccountPickerScreen()),
    );
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _openRegister() async {
    final result = await context.pushScreen(const RegisterScreen());
    if (result == true && mounted) _goAccountPicker();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Align(
                  alignment: Alignment.topRight,
                  child: LocaleToggle(),
                ),
                const SizedBox(height: AppSpacing.xl),

                Icon(Icons.menu_book_rounded, size: 80, color: AppColors.inkBlue),
                const SizedBox(height: AppSpacing.lg),

                Text(
                  S.of(context, 'login'),
                  style: AppTextStyles.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: S.of(context, 'email'),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (v) =>
                      v == null || !v.contains('@') || !v.contains('.') ? S.of(context, 'email') : null,
                ),
                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: S.of(context, 'password'),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  validator: (v) =>
                      v == null || v.length < 6 ? S.of(context, 'password') : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(_error!, style: AppTextStyles.error),
                  ),

                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          child: Text(S.of(context, 'login')),
                        ),
                      ),
                const SizedBox(height: AppSpacing.md),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _openRegister,
                    child: Text(S.of(context, 'register')),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Center(
                  child: TextButton(
                    onPressed: _skip,
                    child: Text(
                      S.of(context, 'skipLogin'),
                      style: AppTextStyles.link,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
