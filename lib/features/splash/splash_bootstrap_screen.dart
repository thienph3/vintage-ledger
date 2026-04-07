import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/bootstrap/bootstrap_models.dart';
import 'package:vintage_ledger/core/bootstrap/bootstrap_service.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/main_shell.dart';
import 'package:vintage_ledger/features/auth/screens/login_screen.dart';
import 'package:vintage_ledger/features/account/screens/account_picker_screen.dart';
import 'package:vintage_ledger/main.dart';

class SplashBootstrapScreen extends StatefulWidget {
  final LoginIntent? loginIntent;

  const SplashBootstrapScreen({super.key, this.loginIntent});

  @override
  State<SplashBootstrapScreen> createState() => _SplashBootstrapScreenState();
}

class _SplashBootstrapScreenState extends State<SplashBootstrapScreen> {
  double _progress = 0;
  String _labelKey = 'bootstrapAuth';
  String? _error;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() { _error = null; _navigated = false; });

    await for (final p in BootstrapService(loginIntent: widget.loginIntent).run()) {
      if (!mounted) return;

      setState(() {
        _progress = p.current / p.total;
        _labelKey = p.labelKey;
      });

      if (p.error != null) {
        setState(() => _error = p.error);
        return;
      }

      if (p.done && p.result != null) {
        _navigate(p.result!);
        return;
      }
    }
  }

  void _navigate(BootstrapResult result) {
    if (_navigated || !mounted) return;
    _navigated = true;

    MyApp.setLocale(context, Locale(result.locale));
    sl.reminderService.init(context);

    if (result.needsLogin) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
        ),
        (_) => false,
      );
    } else if (result.needsAccountPick) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const AccountPickerScreen(),
          transitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
        ),
        (_) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const AccountPickerScreen(),
          transitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
        ),
        (_) => false,
      );
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => MainShell(initialTab: result.returnToTab ?? 0),
          transitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl * 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.menu_book_rounded, size: 64, color: AppColors.primary),
              const SizedBox(height: AppSpacing.md),
              Text('Vintage Ledger', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.xl),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 3,
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                S.of(context, _labelKey),
                style: AppTextStyles.hint,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(S.of(context, 'genericError'), style: AppTextStyles.error),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: _run,
                  child: Text(S.of(context, 'retry')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
