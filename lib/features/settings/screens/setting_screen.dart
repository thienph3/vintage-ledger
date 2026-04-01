import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/core/constants/currency.dart';
import 'package:vintage_ledger/features/quick_add/quick_add_parser.dart';
import 'package:vintage_ledger/core/debug/read_counter.dart';
import 'package:vintage_ledger/features/auth/screens/login_screen.dart';
import 'package:vintage_ledger/features/auth/screens/register_screen.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';
import 'package:vintage_ledger/main.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  String _currentLocale = 'vi';
  String _defaultCurrency = 'VND';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final locale = await sl.settingService.getLocale();
    final currency = await sl.settingService.getDefaultCurrency();
    setState(() {
      _currentLocale = locale;
      _defaultCurrency = currency;
    });
  }

  Future<void> _changeLocale(String locale) async {
    await sl.settingService.setLocale(locale);
    if (!mounted) return;
    setState(() => _currentLocale = locale);
    MyApp.setLocale(context, Locale(locale));
  }

  Future<void> _logout() async {
    await sl.notificationService.removeToken();
    await sl.authService.logout();
    sl.appState.currentUserId = null;
    sl.appState.currentAccountId = '';
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = sl.authService.currentUser;
    final isAnonymous = sl.authService.isAnonymous;

    return AppScaffold(
      title: S.of(context, 'settings'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Account section
          const SizedBox(height: AppSpacing.md),
          Text(S.of(context, 'account'), style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),

          if (isAnonymous) ...[
            ListTile(
              leading: const Icon(Icons.person_add, color: AppColors.inkBlue),
              title: Text(S.of(context, 'register')),
              subtitle: Text(S.of(context, 'registerToSync')),
              onTap: () => context.pushScreen(const RegisterScreen()),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ] else if (user != null) ...[
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: Text(user.email ?? ''),
              subtitle: Text(user.displayName ?? ''),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.inkRed),
              title: Text(S.of(context, 'logout'),
                  style: AppTextStyles.body.copyWith(color: AppColors.inkRed)),
              onTap: _logout,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ],
          const Divider(),

          // Currency section
          const SizedBox(height: AppSpacing.md),
          Text(S.of(context, 'currency'), style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          ...Currency.all.map((c) {
            final isSelected = _defaultCurrency == c.code;
            return ListTile(
              leading: Text(c.symbol, style: AppTextStyles.emoji),
              title: Text(c.code),
              trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.inkBlue) : null,
              onTap: () async {
                await sl.settingService.setDefaultCurrency(c.code);
                setState(() => _defaultCurrency = c.code);
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: isSelected ? AppColors.inkBlue.withValues(alpha: 0.1) : null,
            );
          }),
          const Divider(),

          // Language section
          const SizedBox(height: AppSpacing.md),
          Text(S.of(context, 'language'), style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          _buildLanguageTile('vi', S.of(context, 'vietnamese'), '🇻🇳'),
          _buildLanguageTile('en', S.of(context, 'english'), '🇺🇸'),

          if (QuickAddParser.learnedCount > 0) ...[
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined, color: AppColors.inkRed),
              title: Text(S.of(context, 'clearLearnedKeywords')),
              subtitle: Text('${QuickAddParser.learnedCount} ${S.of(context, 'keywords')}'),
              onTap: () async {
                await QuickAddParser.clearLearned();
                setState(() {});
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ],

          // Debug
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Firestore reads'),
            subtitle: Text('${ReadCounter.count} reads\n${ReadCounter.breakdown}'),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () { ReadCounter.reset(); setState(() {}); },
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(String locale, String label, String flag) {
    final isSelected = _currentLocale == locale;
    return ListTile(
      leading: Text(flag, style: AppTextStyles.emoji),
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.inkBlue) : null,
      onTap: () => _changeLocale(locale),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isSelected ? AppColors.inkBlue.withValues(alpha: 0.1) : null,
    );
  }
}
