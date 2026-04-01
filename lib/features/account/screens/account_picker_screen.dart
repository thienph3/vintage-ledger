import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/async_content.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/features/account/models/account.dart';
import 'package:vintage_ledger/features/home/screens/home_screen.dart';
import 'package:vintage_ledger/features/account/screens/family_form_screen.dart';
import 'package:vintage_ledger/features/account/screens/family_detail_screen.dart';
import 'package:vintage_ledger/features/account/screens/join_family_screen.dart';
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
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _joinByLink() async {
    final ctrl = TextEditingController();
    final link = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(ctx, 'joinByLink')),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(hintText: S.of(ctx, 'pasteInviteLink')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.of(ctx, 'cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: Text(S.of(ctx, 'done'))),
        ],
      ),
    );
    if (link == null || link.isEmpty) return;

    // Extract tokenId from link: https://vintage-ledger.web.app/invite/{tokenId}
    final tokenId = link.contains('/invite/') ? link.split('/invite/').last : link;
    if (tokenId.isEmpty) return;

    if (!mounted) return;
    final result = await context.pushScreen(JoinFamilyScreen(tokenId: tokenId));
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
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
                const SizedBox(height: AppSpacing.xl),
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
                                  color: AppColors.inkBlue, size: 28,
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
                              const Icon(Icons.add, color: AppColors.inkBlue),
                              const SizedBox(width: AppSpacing.sm),
                              Text(S.of(context, 'createFamily'), style: AppTextStyles.body),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      GestureDetector(
                        onTap: _joinByLink,
                        child: LedgerCard(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.link, color: AppColors.inkBlue),
                              const SizedBox(width: AppSpacing.sm),
                              Text(S.of(context, 'joinByLink'), style: AppTextStyles.body),
                            ],
                          ),
                        ),
                      ),
                      // Family promo for users with only personal account
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
}
