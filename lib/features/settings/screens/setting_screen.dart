import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/auth/screens/login_screen.dart';
import 'package:vintage_ledger/main.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  String _currentLocale = 'vi';
  String? _lastSync;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final locale = await sl.settingService.getLocale();
    final accountId = sl.appState.currentAccountId;
    final lastPull = await sl.settingService.getSetting('sync_pull_$accountId');
    setState(() {
      _currentLocale = locale;
      _lastSync = lastPull;
    });
  }

  Future<void> _changeLocale(String locale) async {
    await sl.settingService.setLocale(locale);
    if (!mounted) return;
    setState(() => _currentLocale = locale);
    MyApp.setLocale(context, Locale(locale));
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    try {
      await sl.syncService.syncAccount(sl.appState.currentAccountId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context, 'syncSuccess'))),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${S.of(context, 'syncFailed')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _logout() async {
    await sl.authService.logout();
    sl.appState.currentUserId = null;
    sl.appState.currentAccountId = 'local';
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

    return AppScaffold(
      title: S.of(context, 'settings'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Account section
          if (user != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Account', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
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
            const Divider(),
          ],

          // Sync section
          if (user != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(S.of(context, 'sync'), style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(S.of(context, 'lastSync')),
              subtitle: Text(_lastSync != null
                  ? DateTime.fromMillisecondsSinceEpoch(int.parse(_lastSync!)).toString().substring(0, 19)
                  : '-'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            ListTile(
              leading: _syncing
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync, color: AppColors.inkBlue),
              title: Text(S.of(context, 'syncNow')),
              onTap: _syncing ? null : _syncNow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            const Divider(),
          ],

          // Language section
          const SizedBox(height: AppSpacing.md),
          Text(S.of(context, 'language'), style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          _buildLanguageTile('vi', S.of(context, 'vietnamese'), '🇻🇳'),
          _buildLanguageTile('en', S.of(context, 'english'), '🇺🇸'),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(String locale, String label, String flag) {
    final isSelected = _currentLocale == locale;
    return ListTile(
      leading: Text(flag, style: AppTextStyles.emoji),
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.inkBlue)
          : null,
      onTap: () => _changeLocale(locale),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isSelected ? AppColors.inkBlue.withValues(alpha: 0.1) : null,
    );
  }
}
