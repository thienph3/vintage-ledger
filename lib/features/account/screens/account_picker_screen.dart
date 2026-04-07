import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/async_content.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/common/widgets/swipe_list_item.dart';
import 'package:vintage_ledger/common/widgets/delete_confirmation.dart';
import 'package:vintage_ledger/common/widgets/app_snackbar.dart';
import 'package:vintage_ledger/features/account/models/account.dart';
import 'package:vintage_ledger/features/splash/splash_bootstrap_screen.dart';
import 'package:vintage_ledger/features/account/screens/family_form_screen.dart';
import 'package:vintage_ledger/features/settings/screens/setting_screen.dart';
import 'package:vintage_ledger/features/main_shell.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

class AccountPickerScreen extends StatefulWidget {
  const AccountPickerScreen({super.key});

  @override
  State<AccountPickerScreen> createState() => _AccountPickerScreenState();
}

class _AccountPickerScreenState extends State<AccountPickerScreen> {
  List<Account> _accounts = [];
  Map<String, List<Map<String, dynamic>>> _memberProfiles = {};
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

      // Preload member profiles for family accounts
      final profiles = <String, List<Map<String, dynamic>>>{};
      for (final a in accounts) {
        if (a.isFamily) {
          final rawProfiles = await sl.accountService.getMemberProfiles(a.memberIds);
          profiles[a.id] = rawProfiles.map((p) => Map<String, dynamic>.from(p)).toList();
        }
      }

      setState(() { _accounts = accounts; _memberProfiles = profiles; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _selectAccount(Account account) {
    sl.appState.currentAccountId = account.id;
    sl.settingService.setLastAccountId(account.id);
    sl.cache.clear();
    Navigator.push(
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
                        child: _buildAccountCard(a),
                      )),
                      _buildCreateButton(),
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

  Widget _buildAccountCard(Account a) {
    final photoUrl = a.isPersonal ? sl.authService.currentUser?.photoURL : null;

    final card = LedgerCard(
      child: Row(
        children: [
          if (a.isPersonal)
            _buildAvatar(photoUrl, a.name)
          else
            _buildFamilyAvatars(a),
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
          Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
        ],
      ),
    );

    if (a.isFamily) {
      final isOwner = a.ownerId == sl.appState.currentUserId;
      return SwipeListItem(
        itemKey: ValueKey(a.id),
        onTap: () => _selectAccount(a),
        confirmDelete: () => showDeleteConfirmation(
          context,
          titleKey: isOwner ? 'deleteFamily' : 'leaveFamily',
          contentKey: isOwner ? 'deleteFamilyConfirm' : 'leaveFamilyConfirm',
        ),
        onDelete: () async {
          if (isOwner) {
            await sl.accountService.deleteFamily(accountId: a.id);
          } else {
            await sl.accountService.leaveFamily(accountId: a.id, userId: sl.appState.currentUserId!);
          }
          _load();
        },
        child: card,
      );
    }

    return GestureDetector(
      onTap: () => _selectAccount(a),
      child: card,
    );
  }

  Widget _buildAvatar(String? photoUrl, String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
      backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
      child: photoUrl == null || photoUrl.isEmpty
          ? Text(initials, style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary))
          : null,
    );
  }

  Widget _buildFamilyAvatars(Account a) {
    final members = _memberProfiles[a.id] ?? [];
    final display = members.take(3).toList();
    return SizedBox(
      width: 20.0 + display.length * 14.0,
      height: 40,
      child: Stack(
        children: display.asMap().entries.map((e) {
          final m = e.value;
          final initials = (m['name'] ?? '?')[0].toUpperCase();
          final photo = m['photo_url'];
          return Positioned(
            left: e.key * 14.0,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accent.withValues(alpha: 0.2),
              backgroundImage: photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
              child: photo == null || photo.isEmpty
                  ? Text(initials, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600))
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: () async {
        final result = await context.pushScreen(const FamilyFormScreen());
        if (result == true) _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(S.of(context, 'createFamily'), style: AppTextStyles.body.copyWith(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteCard(Map<String, dynamic> inv) {
    final name = inv['account_name'] as String? ?? '';
    final senderName = inv['sender_name'] as String? ?? '';
    final inviteId = inv['id'] as String;
    final initials = senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: LedgerCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.accent.withValues(alpha: 0.2),
              child: Text(initials, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context, 'invitedToFamily'),
                    style: AppTextStyles.bodySmall,
                  ),
                  Text(name, style: AppTextStyles.bodyBold),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle, color: AppColors.income, size: 28),
              onPressed: () => _acceptInvite(inviteId),
            ),
            IconButton(
              icon: Icon(Icons.cancel, color: AppColors.textSecondary, size: 28),
              onPressed: () => _rejectInvite(inviteId),
            ),
          ],
        ),
      ),
    );
  }
}
