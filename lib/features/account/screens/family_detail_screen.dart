import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/async_content.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/common/widgets/delete_confirmation.dart';
import 'package:vintage_ledger/common/widgets/error_snackbar.dart';
import 'package:vintage_ledger/features/account/models/account.dart';

class FamilyDetailScreen extends StatefulWidget {
  final Account account;

  const FamilyDetailScreen({super.key, required this.account});

  @override
  State<FamilyDetailScreen> createState() => _FamilyDetailScreenState();
}

class _FamilyDetailScreenState extends State<FamilyDetailScreen> {
  List<Map<String, String>> _members = [];
  bool _loading = true;
  String? _error;

  bool get _isOwner => widget.account.ownerId == sl.appState.currentUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final members = await sl.accountService.getMemberProfiles(widget.account.memberIds);
      setState(() { _members = members; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  // ── Invite by link (#5) ──

  Future<void> _shareInvite() async {
    try {
      final tokenId = await sl.accountService.createInviteToken(
        accountId: widget.account.id,
        createdBy: sl.appState.currentUserId!,
      );
      final link = sl.accountService.buildInviteLink(tokenId);

      await Clipboard.setData(ClipboardData(text: link));

      // Notify family members
      sl.notificationService.notifyInvite(accountId: widget.account.id, tokenId: tokenId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context, 'inviteCopied'))),
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    }
  }

  Future<void> _removeMember(String memberId) async {
    final confirm = await showDeleteConfirmation(
      context, titleKey: 'leaveFamily', contentKey: 'removeMemberConfirm',
    );
    if (confirm != true) return;

    try {
      await sl.accountService.removeMember(accountId: widget.account.id, memberId: memberId);
      _load();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    }
  }

  Future<void> _leave() async {
    final confirm = await showDeleteConfirmation(
      context, titleKey: 'leaveFamily', contentKey: 'leaveFamilyConfirm',
    );
    if (confirm != true) return;

    await sl.accountService.leaveFamily(
      accountId: widget.account.id, userId: sl.appState.currentUserId!,
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirm = await showDeleteConfirmation(
      context, titleKey: 'deleteFamily', contentKey: 'deleteFamilyConfirm',
    );
    if (confirm != true) return;

    await sl.accountService.deleteFamily(accountId: widget.account.id);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.account.name,
      body: AsyncContent(
        loading: _loading,
        error: _error,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _buildMembersSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildActivitySection(),
            const SizedBox(height: AppSpacing.lg),
            _buildActionsSection(),
          ],
        ),
      ),
    );
  }

  // ── Members section (#10: avatars) ──

  Widget _buildMembersSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(S.of(context, 'members'), style: AppTextStyles.title),
            if (_isOwner)
              IconButton(
                icon: const Icon(Icons.share, color: AppColors.inkBlue),
                tooltip: S.of(context, 'shareInvite'),
                onPressed: _shareInvite,
              ),
          ],
        ),
        const Divider(),
        ..._members.map((m) {
          final isCurrentUser = m['id'] == sl.appState.currentUserId;
          final isMemberOwner = m['id'] == widget.account.ownerId;
          final name = m['name'] ?? '';
          final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: LedgerCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isMemberOwner ? AppColors.inkBlue : AppColors.divider,
                    child: Text(initials, style: AppTextStyles.bodyBold.copyWith(
                      color: isMemberOwner ? Colors.white : AppColors.inkBlack,
                    )),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: AppTextStyles.bodyBold),
                        Text(m['email'] ?? '', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  if (isMemberOwner)
                    Text(S.of(context, 'owner'), style: AppTextStyles.caption),
                  if (_isOwner && !isCurrentUser && !isMemberOwner)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.inkRed),
                      onPressed: () => _removeMember(m['id']!),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Activity feed (#7) ──

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.of(context, 'activity'), style: AppTextStyles.title),
        const Divider(),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: sl.accountService.watchActivities(widget.account.id),
          builder: (context, snap) {
            final activities = snap.data ?? [];
            if (activities.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(S.of(context, 'noActivity'), style: AppTextStyles.hint),
              );
            }

            return Column(
              children: activities.take(10).map((a) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Icon(
                        a['action'] == 'expense' ? Icons.arrow_upward
                            : a['action'] == 'income' ? Icons.arrow_downward
                            : Icons.info_outline,
                        size: 16,
                        color: a['action'] == 'expense' ? AppColors.expense
                            : a['action'] == 'income' ? AppColors.income
                            : AppColors.inkBlue,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          a['description'] ?? '',
                          style: AppTextStyles.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ── Actions ──

  Widget _buildActionsSection() {
    return Column(
      children: [
        if (!_isOwner)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _leave,
              icon: const Icon(Icons.exit_to_app),
              label: Text(S.of(context, 'leaveFamily')),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.inkRed),
            ),
          ),
        if (_isOwner)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _delete,
              icon: const Icon(Icons.delete_forever),
              label: Text(S.of(context, 'deleteFamily')),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.inkRed),
            ),
          ),
      ],
    );
  }
}
