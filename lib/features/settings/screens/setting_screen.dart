import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/error_mapper.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/app_snackbar.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/export/export_service.dart';
import 'package:vintage_ledger/features/quick_add/quick_add_parser.dart';
import 'package:vintage_ledger/core/debug/read_counter.dart';
import 'package:vintage_ledger/features/auth/screens/login_screen.dart';
import 'package:vintage_ledger/features/account/screens/account_picker_screen.dart';
import 'package:vintage_ledger/features/wallet/screens/wallet_list_screen.dart';
import 'package:vintage_ledger/features/category/screens/category_list_screen.dart';
import 'package:vintage_ledger/features/recurring/screens/recurring_list_screen.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';
import 'package:vintage_ledger/main.dart';
import 'package:share_plus/share_plus.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  String _currentLocale = 'vi';
  bool _exporting = false;
  bool _reminderEnabled = false;
  int _reminderHour = 20;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final locale = await sl.settingService.getLocale();
    final reminderEnabled = await sl.settingService.getSetting('reminder_enabled');
    final reminderHour = await sl.settingService.getSetting('reminder_hour');
    setState(() {
      _currentLocale = locale;
      _reminderEnabled = reminderEnabled == 'true';
      _reminderHour = int.tryParse(reminderHour ?? '20') ?? 20;
    });
  }

  // ── Actions ──

  Future<void> _linkWithGoogle() async {
    try {
      final user = await sl.authService.linkEmailUserWithGoogle();
      if (user == null || !mounted) return;
      await sl.accountService.updateUserProfile(
        userId: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
      );
      if (mounted) setState(() {});
      showAppSnackBar(context, S.of(context, 'googleLinked'));
    } catch (e) {
      if (!mounted) return;
      final mapped = ErrorMapper.map(e);
      showAppSnackBar(context, S.of(context, mapped.message), backgroundColor: AppColors.expense);
    }
  }

  Future<void> _signInWithGoogle() async {
    final anonAccountId = sl.appState.currentAccountId;
    try {
      // Sign out anonymous, sign in Google fresh
      await sl.authService.logout();
      final user = await sl.authService.signInWithGoogle();
      if (user == null || !mounted) return;

      sl.appState.currentUserId = user.uid;
      final accountId = await sl.accountService.getOrCreatePersonalAccountId(
        user.uid, user.email ?? '', user.displayName ?? '',
      );
      sl.appState.currentAccountId = accountId;
      sl.settingService.setLastAccountId(accountId);

      await sl.accountService.updateUserProfile(
        userId: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
      );

      // Migrate anonymous data
      if (anonAccountId.isNotEmpty && anonAccountId != accountId) {
        await sl.accountService.migrateAccount(anonAccountId, accountId);
        await sl.accountService.deleteAccount(anonAccountId);
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      final mapped = ErrorMapper.map(e);
      showAppSnackBar(context, S.of(context, mapped.message), backgroundColor: AppColors.expense);
    }
  }

  Future<void> _editDisplayName(User user) async {
    final ctrl = TextEditingController(text: user.displayName ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(ctx, 'displayName')),
        content: TextField(
          controller: ctrl, autofocus: true, style: AppTextStyles.body,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.of(ctx, 'cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: Text(S.of(ctx, 'save'))),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == user.displayName) return;
    await user.updateDisplayName(newName);
    await sl.accountService.updateUserProfile(userId: user.uid, email: user.email ?? '', displayName: newName);
    if (mounted) setState(() {});
  }

  Future<void> _loginExisting() async {
    final anonAccountId = sl.appState.currentAccountId;
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
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => LoginScreen(anonAccountIdToMigrate: anonAccountId)), (_) => false);
  }

  Future<void> _logout() async {
    await sl.notificationService.removeToken();
    await sl.authService.logout();
    sl.appState.currentUserId = null;
    sl.appState.currentAccountId = '';
    sl.settingService.clearCache();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final path = await ExportService().exportTransactionsCsv();
      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(files: [XFile(path)], subject: 'Vintage Ledger Export'));
      if (!mounted) return;
      showAppSnackBar(context, S.of(context, 'exportSuccess'));
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.toString(), backgroundColor: AppColors.expense);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = sl.authService.currentUser;
    final isAnonymous = sl.authService.isAnonymous;

    return AppScaffold(
      title: S.of(context, 'settings'),
      showBackButton: false,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        children: [
          // ── Profile ──
          _buildProfileCard(user, isAnonymous),
          const SizedBox(height: AppSpacing.lg),

          // ── Manage ──
          _sectionLabel(S.of(context, 'manageWallets')),
          _tile(Icons.account_balance_wallet_outlined, S.of(context, 'manageWallets'), onTap: () => context.pushScreen(const WalletListScreen())),
          _tile(Icons.category_outlined, S.of(context, 'manageCategories'), onTap: () => context.pushScreen(const CategoryListScreen())),
          _tile(Icons.repeat, S.of(context, 'recurringRules'), onTap: () => context.pushScreen(const RecurringListScreen())),
          const SizedBox(height: AppSpacing.lg),

          // ── Preferences ──
          _sectionLabel(S.of(context, 'settings')),
          _tile(
            _currentLocale == 'vi' ? Icons.flag : Icons.flag_outlined,
            S.of(context, 'language'),
            trailing: Text(_currentLocale == 'vi' ? '🇻🇳' : '🇺🇸', style: AppTextStyles.emoji),
            onTap: () async {
              final newLocale = _currentLocale == 'vi' ? 'en' : 'vi';
              await sl.settingService.setLocale(newLocale);
              if (!mounted) return;
              setState(() => _currentLocale = newLocale);
              MyApp.setLocale(context, Locale(newLocale));
            },
          ),
          _buildReminderTile(),
          const SizedBox(height: AppSpacing.lg),

          // ── Data ──
          _sectionLabel(S.of(context, 'privacy')),
          _tile(
            _exporting ? null : Icons.download_outlined,
            S.of(context, 'exportCsv'),
            loading: _exporting,
            onTap: _exporting ? null : _exportCsv,
          ),
          _tile(Icons.shield_outlined, S.of(context, 'dataSecure'), subtitle: S.of(context, 'onlyYouCanAccess'), onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (ctx) => Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.of(ctx, 'privacy'), style: AppTextStyles.titleSmall),
                    const SizedBox(height: AppSpacing.md),
                    Text(S.of(ctx, 'privacyDetail'), style: AppTextStyles.body),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            );
          }),
          if (QuickAddParser.learnedCount > 0)
            _tile(Icons.delete_sweep_outlined, S.of(context, 'clearLearnedKeywords'),
              subtitle: '${QuickAddParser.learnedCount} ${S.of(context, 'keywords')}',
              color: AppColors.expense,
              onTap: () async { await QuickAddParser.clearLearned(); setState(() {}); },
            ),

          // Debug
          const SizedBox(height: AppSpacing.lg),
          _sectionLabel('Debug'),
          _tile(Icons.bug_report_outlined, 'Firestore reads',
            subtitle: '${ReadCounter.count} reads',
            trailing: IconButton(
              icon: const Icon(Icons.refresh, size: 16, color: AppColors.textSecondary),
              onPressed: () { ReadCounter.reset(); setState(() {}); },
            ),
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  // ── Profile card ──

  Widget _buildProfileCard(User? user, bool isAnonymous) {
    if (isAnonymous) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            const Icon(Icons.person_outline, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.sm),
            Text(S.of(context, 'anonymousExplanation'), style: AppTextStyles.hint, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata, size: 24),
                label: Text(S.of(context, 'signInWithGoogle')),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _loginExisting,
                child: Text(S.of(context, 'loginWithEmail')),
              ),
            ),
            ),
          ],
        ),
      );
    }

    if (user == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Avatar + name + email
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null
                    ? Text(
                        (user.displayName ?? '?')[0].toUpperCase(),
                        style: AppTextStyles.title.copyWith(color: AppColors.primary),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName ?? '', style: AppTextStyles.bodyBold),
                    Text(user.email ?? '', style: AppTextStyles.caption),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                onPressed: () => _editDisplayName(user),
              ),
            ],
          ),
          // Migrate to Google (for email users)
          if (sl.authService.isEmailUser && !sl.authService.isGoogleUser)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: _smallAction(Icons.g_mobiledata, S.of(context, 'linkWithGoogle'), _linkWithGoogle),
            ),
          const SizedBox(height: AppSpacing.md),
          // Actions row
          Row(
            children: [
              Expanded(
                child: _smallAction(Icons.swap_horiz, S.of(context, 'switchAccount'), () {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AccountPickerScreen()), (_) => false);
                }),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _smallAction(Icons.logout, S.of(context, 'logout'), _logout, color: AppColors.expense),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallAction(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: c),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.caption.copyWith(color: c, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Reminder ──

  Widget _buildReminderTile() {
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined, color: AppColors.primary),
          title: Text(S.of(context, 'dailyReminder'), style: AppTextStyles.body),
          value: _reminderEnabled,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: _reminderHour, minute: 0));
                if (picked == null) return;
                setState(() => _reminderHour = picked.hour);
                await sl.settingService.setSetting('reminder_hour', picked.hour.toString());
                await sl.reminderService.schedule(context, picked.hour);
              },
              child: Row(
                children: [
                  Text(S.of(context, 'reminderTime'), style: AppTextStyles.bodySmall),
                  const SizedBox(width: AppSpacing.sm),
                  Text('${_reminderHour.toString().padLeft(2, '0')}:00', style: AppTextStyles.bodyBold),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── Helpers ──

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 4),
      child: Text(text, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    );
  }

  Widget _tile(IconData? icon, String title, {String? subtitle, VoidCallback? onTap, Widget? trailing, Color? color, bool loading = false}) {
    final c = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        leading: loading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon, size: 22, color: c),
        title: Text(title, style: AppTextStyles.body),
        subtitle: subtitle != null ? Text(subtitle, style: AppTextStyles.caption) : null,
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
        dense: true,
      ),
    );
  }
}
