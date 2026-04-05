import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/async_content.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/common/widgets/app_snackbar.dart';
import 'package:vintage_ledger/features/account/models/account.dart';
import 'package:vintage_ledger/features/main_shell.dart';
import 'package:vintage_ledger/features/account/screens/family_form_screen.dart';
import 'package:vintage_ledger/features/account/screens/family_detail_screen.dart';
import 'package:vintage_ledger/features/settings/screens/setting_screen.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

class AccountPickerScreen extends StatefulWidget {
  const AccountPickerScreen({super.key});

  @override
  State<AccountPickerScreen> createState() => _AccountPickerScreenState();
}

class _AccountPickerScreenState extends State<AccountPickerScreen> {
  List<Account> _accounts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final userId = sl.appState.currentUserId;
      if (userId == null) return;
      final accounts = await sl.accountService.getAccountsForUser(userId);
      setState(() { _accounts = accounts; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _selectAccount(Account account) {
    sl.appState.currentAccountId = account.id;
    sl.settingService.setLastAccountId(account.id);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  Future<void> _acceptInvite(String inviteId) async {
    try {
      await sl.accountService.acceptInvite(inviteId);
      _load();
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.toString(), backgroundColor: AppColors.error);
    }
  }

  Future<void> _rejectInvite(String inviteId) async {
    await sl.accountService.rejectInvite(inviteId);
  }

  @override
  Widget build(BuildContext context) {
    final userId = sl.appState.currentUserId;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AsyncContent(
          loading: _loading,
          error: _error,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.lg),
                Text(S.of(context, 'chooseAccount'), style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.lg),
                // Pending invites
                if (userId != null)
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: sl.accountService.watchPendingInvites(userId),
                    builder: (context, snap) {
                      final invites = snap.data ?? [];
                      if (invites.isEmpty) return const SizedBox.shrink();
                      return Column(
                        children: invites.map((inv) => _buildInviteCard(inv)).toList(),
                      );
                    },
                  ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: ListView(
                    children: [
                      ..._accounts.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: GestureDetector(
                          onTap: () => _selectAccount(a),
                          onLongPress: a.isFamily ? () async {
                            final result = await context.pushScreen(FamilyDetailScreen(account: a));
                            if (result == true) _load();
                          } : null,
                          child: LedgerCard(
                            child: Row(
                              children: [
                                Icon(
                                  a.isPersonal ? Icons.person : Icons.family_restroom,
                                  color: AppColors.primary, size: 28,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a.name, style: AppTextStyles.bodyBold),
                                      if (a.isFamily)
                                        Text('${a.memberIds.length} ${S.of(context, 'memberCount')}', style: AppTextStyles.bodySmall),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                          ),
                        ),
                      )),
                      GestureDetector(
                        onTap: () async {
                          final result = await context.pushScreen(const FamilyFormScreen());
                          if (result == true) _load();
                        },
                        child: LedgerCard(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add, color: AppColors.primary),
                              const SizedBox(width: AppSpacing.sm),
                              Text(S.of(context, 'createFamily'), style: AppTextStyles.body),
                            ],
                          ),
                        ),
                      ),
                      if (_accounts.length <= 1) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          S.of(context, 'familyPromo'),
                          style: AppTextStyles.hint,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.pushScreen(const SettingScreen()),
                  icon: const Icon(Icons.settings, size: 18),
                  label: Text(S.of(context, 'settings')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInviteCard(Map<String, dynamic> inv) {
    final name = inv['account_name'] as String? ?? '';
    final inviteId = inv['id'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: LedgerCard(
        child: Row(
          children: [
            const Icon(Icons.mail_outline, color: AppColors.primary, size: 24),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.of(context, 'invitedToFamily'), style: AppTextStyles.bodySmall),
                  Text(name, style: AppTextStyles.bodyBold),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle, color: AppColors.income, size: 28),
              onPressed: () => _acceptInvite(inviteId),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: AppColors.divider, size: 28),
              onPressed: () => _rejectInvite(inviteId),
            ),
          ],
        ),
      ),
    );
  }
}
