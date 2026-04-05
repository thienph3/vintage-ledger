import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/locale_toggle.dart';
import 'package:vintage_ledger/features/splash/splash_bootstrap_screen.dart';
import 'package:vintage_ledger/core/bootstrap/bootstrap_models.dart';

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

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _startGoogleLogin() {
    if (_loading) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SplashBootstrapScreen(
        loginIntent: LoginIntent(
          method: LoginMethod.google,
          anonAccountIdToMigrate: widget.anonAccountIdToMigrate,
        ),
      )),
    );
  }

  void _startEmailLogin() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SplashBootstrapScreen(
        loginIntent: LoginIntent(
          method: LoginMethod.email,
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          anonAccountIdToMigrate: widget.anonAccountIdToMigrate,
        ),
      )),
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

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startGoogleLogin,
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: Text(S.of(context, 'signInWithGoogle')),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

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
                          onPressed: _startEmailLogin,
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
