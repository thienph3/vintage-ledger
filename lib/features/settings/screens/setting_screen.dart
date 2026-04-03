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
import 'package:vintage_ledger/features/export/export_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vintage_ledger/features/auth/screens/login_screen.dart';
import 'package:vintage_ledger/features/account/screens/account_picker_screen.dart';
import 'package:vintage_ledger/features/auth/screens/register_screen.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/features/recurring/screens/recurring_list_screen.dart';
import 'package:vintage_ledger/features/wallet/screens/wallet_list_screen.dart';
import 'package:vintage_ledger/features/category/screens/category_list_screen.dart';
import 'package:vintage_ledger/main.dart';
import 'package:vintage_ledger/common/widgets/app_snackbar.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  String _currentLocale = 'vi';
  String _defaultCurrency = 'VND';
  bool _exporting = false;
  String? _defaultWalletId;
  List<Wallet> _wallets = [];
  bool _reminderEnabled = false;
  int _reminderHour = 20;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final locale = await sl.settingService.getLocale();
    final currency = await sl.settingService.getDefaultCurrency();
    final walletId = await sl.settingService.getLastWalletId();
    final wallets = await sl.walletService.getWallets();
    final reminderEnabled = await sl.settingService.getSetting('reminder_enabled');
    final reminderHour = await sl.settingService.getSetting('reminder_hour');
    setState(() {
      _currentLocale = locale;
      _defaultCurrency = currency;
      _defaultWalletId = walletId;
      _wallets = wallets;
      _reminderEnabled = reminderEnabled == 'true';
      _reminderHour = int.tryParse(reminderHour ?? '20') ?? 20;
    });
  }

  Future<void> _changeLocale(String locale) async {
    await sl.settingService.setLocale(locale);
    if (!mounted) return;
    setState(() => _currentLocale = locale);
    MyApp.setLocale(context, Locale(locale));
  }

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final path = await ExportService().exportTransactionsCsv();
      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(
        files: [XFile(path)],
        subject: 'Vintage Ledger Export',
      ));
      if (!mounted) return;
      showAppSnackBar(context, S.of(context, 'exportSuccess'));
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.toString(), backgroundColor: const Color(0xFF8B1E1E));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showPrivacyInfo() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.of(ctx, 'privacy'), style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.md),
            Text(S.of(ctx, 'privacyDetail'), style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _loginExisting() async {
    final anonAccountId = sl.appState.currentAccountId;
    final anonUserId = sl.appState.currentUserId;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(ctx, 'login')),
        content: Text(S.of(ctx, 'loginMigrateWarning')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.of(ctx, 'cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(S.of(ctx, 'done'))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    await sl.authService.logout();
    sl.appState.currentUserId = null;
    sl.appState.currentAccountId = '';
    sl.settingService.clearCache();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(anonAccountIdToMigrate: anonAccountId)),
      (_) => false,
    );
  }

  Future<void> _logout() async {    await sl.notificationService.removeToken();
    await sl.authService.logout();
    sl.appState.currentUserId = null;
    sl.appState.currentAccountId = '';
    sl.settingService.clearCache();
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
      showBackButton: false,
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
              onTap: () async {
                final result = await context.pushScreen(const RegisterScreen());
                if (result == true && mounted) setState(() {});
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            ListTile(
              leading: const Icon(Icons.login, color: AppColors.inkBlue),
              title: Text(S.of(context, 'login')),
              subtitle: Text(S.of(context, 'loginExisting')),
              onTap: _loginExisting,
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
          if (!isAnonymous)
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: AppColors.inkBlue),
              title: Text(S.of(context, 'switchAccount')),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountPickerScreen()),
                  (_) => false,
                );
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          const Divider(),

          // Default wallet section
          if (_wallets.length > 1) ...[
            const SizedBox(height: AppSpacing.md),
            Text(S.of(context, 'defaultWallet'), style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            ..._wallets.map((w) {
              final isSelected = _defaultWalletId == w.id || (_defaultWalletId == null && w.id == _wallets.firstOrNull?.id);
              return ListTile(
                leading: const Icon(Icons.account_balance_wallet, size: 20, color: AppColors.inkBlue),
                title: Text(w.name),
                trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.inkBlue) : null,
                onTap: () async {
                  await sl.settingService.setLastWalletId(w.id!);
                  setState(() => _defaultWalletId = w.id);
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: isSelected ? AppColors.inkBlue.withValues(alpha: 0.1) : null,
              );
            }),
          ],
          const Divider(),

          // Currency section (VND only for now)
          const SizedBox(height: AppSpacing.md),
          Text(S.of(context, 'currency'), style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          ...Currency.all.where((c) => c.code == 'VND').map((c) {
            final isSelected = _defaultCurrency == c.code;
            return ListTile(
              leading: Text(c.symbol, style: AppTextStyles.emoji),
              title: Text(c.code),
              trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
              onTap: () async {
                await sl.settingService.setDefaultCurrency(c.code);
                setState(() => _defaultCurrency = c.code);
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: isSelected ? AppColors.primary.withValues(alpha: 0.08) : null,
            );
          }),
          const Divider(),

          // Wallet & Category management
          const SizedBox(height: AppSpacing.md),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
            title: Text(S.of(context, 'manageWallets')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.pushScreen(const WalletListScreen()),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined, color: AppColors.primary),
            title: Text(S.of(context, 'manageCategories')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.pushScreen(const CategoryListScreen()),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          const Divider(),

          // Language section
          const SizedBox(height: AppSpacing.md),
          Text(S.of(context, 'language'), style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          _buildLanguageTile('vi', S.of(context, 'vietnamese'), '🇻🇳'),
          _buildLanguageTile('en', S.of(context, 'english'), '🇺🇸'),
          const Divider(),

          // Recurring section
          const SizedBox(height: AppSpacing.md),
          ListTile(
            leading: const Icon(Icons.repeat, color: AppColors.inkBlue),
            title: Text(S.of(context, 'recurringRules')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.pushScreen(const RecurringListScreen()),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          const Divider(),

          // Reminder section
          const SizedBox(height: AppSpacing.md),
          Text(S.of(context, 'dailyReminder'), style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined, color: AppColors.inkBlue),
            title: Text(S.of(context, 'dailyReminder')),
            value: _reminderEnabled,
            onChanged: (v) async {
              setState(() => _reminderEnabled = v);
              await sl.settingService.setSetting('reminder_enabled', v.toString());
              if (v) {
                await sl.reminderService.schedule(context, _reminderHour);
              } else {
                await sl.reminderService.cancel();
              }
            },
          ),
          if (_reminderEnabled)
            ListTile(
              leading: const Icon(Icons.access_time, color: AppColors.inkBlue),
              title: Text(S.of(context, 'reminderTime')),
              trailing: Text('${_reminderHour.toString().padLeft(2, '0')}:00', style: AppTextStyles.bodyBold),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: _reminderHour, minute: 0),
                );
                if (picked == null) return;
                setState(() => _reminderHour = picked.hour);
                await sl.settingService.setSetting('reminder_hour', picked.hour.toString());
                await sl.reminderService.schedule(context, picked.hour);
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          const Divider(),

          // Export section
          const SizedBox(height: AppSpacing.md),
          ListTile(
            leading: _exporting
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download_outlined, color: AppColors.inkBlue),
            title: Text(S.of(context, 'exportCsv')),
            onTap: _exporting ? null : _exportCsv,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),

          // Privacy section
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Text(S.of(context, 'privacy'), style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            leading: const Icon(Icons.shield_outlined, color: AppColors.inkBlue),
            title: Text(S.of(context, 'dataSecure')),
            subtitle: Text(S.of(context, 'onlyYouCanAccess')),
            onTap: _showPrivacyInfo,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),

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
