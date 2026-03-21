import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/locale_toggle.dart';
import 'package:vintage_ledger/features/auth/services/auth_service.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final AuthService _authService = AuthService();

  bool _loading = false;
  String? _error;

  Future<void> _unlock() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await _authService.authenticate();

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _loading = false;
        _error = S.of(context, 'authFailed');
      });
    }
  }

  void _exitApp() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                const LocaleToggle(),

                const SizedBox(height: 8),

                const Icon(Icons.lock_outline, size: 80),

                const SizedBox(height: 24),

                Text(
                  S.of(context, 'appLocked'),
                  style: AppTextStyles.headline,
                ),

                const SizedBox(height: 8),

                Text(
                  S.of(context, 'authenticateToContinue'),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_error!, style: AppTextStyles.error),
                  ),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _unlock,

                    icon: const Icon(Icons.fingerprint),

                    label: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(S.of(context, 'unlock')),
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: _exitApp,
                  child: Text(S.of(context, 'exitApp')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
