import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/async_content.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/common/widgets/delete_confirmation.dart';
import 'package:vintage_ledger/common/widgets/app_snackbar.dart';
import 'package:vintage_ledger/features/feed/widgets/feed_item.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';
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

  Future<void> _inviteByEmail() async {
    final ctrl = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(ctx, 'inviteMember')),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(hintText: S.of(ctx, 'enterEmail')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.of(ctx, 'cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: Text(S.of(ctx, 'send'))),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;

    try {
      await sl.accountService.sendInviteByEmail(
        accountId: widget.account.id,
        email: email,
      );
      if (!mounted) return;
      showAppSnackBar(context, S.of(context, 'inviteSent'));
    } catch (e) {
      if (!mounted) return;
      final key = e.toString().replaceFirst('Exception: ', '');
      final msg = S.of(context, key);
      showAppSnackBar(context, msg, backgroundColor: AppColors.error);
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
      showAppSnackBar(context, e.toString(), backgroundColor: AppColors.error);
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
            Text(S.of(context, 'members'), style: AppTextStyles.titleSmall),
            if (_isOwner)
              IconButton(
                icon: const Icon(Icons.share, color: AppColors.primary),
                tooltip: S.of(context, 'inviteMember'),
                onPressed: _inviteByEmail,
              ),
          ],
        ),
        const Divider(),
        ..._members.map((m) {
          final isCurrentUser = m['id'] == sl.appState.currentUserId;
          final isMemberOwner = m['id'] == widget.account.ownerId;
          final name = m['name'] ?? '';
          final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

          final photo = m['photo_url'];

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: LedgerCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isMemberOwner ? AppColors.primary.withValues(alpha: 0.12) : AppColors.divider,
                    backgroundImage: photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
                    child: photo == null || photo.isEmpty
                        ? Text(initials, style: AppTextStyles.bodyBold.copyWith(
                            color: isMemberOwner ? AppColors.primary : AppColors.textPrimary,
                          ))
                        : null,
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
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.expense),
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
        Text(S.of(context, 'activity'), style: AppTextStyles.titleSmall),
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

            final grouped = _groupActivities(activities);
            return Column(
              children: [
                ...grouped.take(30).map((a) => _buildActivityFeedItem(a)),
              ],
            );
          },
        ),
      ],
    );
  }

  // ── Activity grouping ──

  List<Map<String, dynamic>> _groupActivities(List<Map<String, dynamic>> raw) {
    final result = <Map<String, dynamic>>[];
    String? lastUserId;
    String? lastDay;
    int txnCount = 0;

    for (final a in raw) {
      final action = a['action'] as String? ?? '';
      final userId = a['user_id'] as String? ?? '';
      final ts = a['created_at'];
      final day = ts is Timestamp
          ? DateFormatter.fullDate(ts.toDate().millisecondsSinceEpoch)
          : '';

      final isTxn = action == 'expense' || action == 'income';

      if (isTxn && userId == lastUserId && day == lastDay && result.isNotEmpty) {
        txnCount++;
        result.last['_grouped_count'] = txnCount;
        continue;
      }

      result.add(Map<String, dynamic>.from(a));
      if (isTxn) {
        lastUserId = userId;
        lastDay = day;
        txnCount = 1;
        result.last['_grouped_count'] = 1;
      } else {
        lastUserId = null;
        lastDay = null;
        txnCount = 0;
      }
    }
    return result;
  }

  Widget _buildActivityFeedItem(Map<String, dynamic> a) {
    final memberName = _members.where((m) => m['id'] == a['user_id']).firstOrNull?['name'] ?? '?';
    final memberPhoto = _members.where((m) => m['id'] == a['user_id']).firstOrNull?['photo_url'];
    final timestamp = a['created_at'];
    final timeStr = timestamp != null
        ? DateFormatter.relative(timestamp is Timestamp ? timestamp.toDate() : timestamp)
        : '';
    final groupedCount = a['_grouped_count'] as int? ?? 0;

    String description;
    if (groupedCount > 1) {
      description = '$memberName ${S.of(context, 'addedTransactionsToday').replaceAll('{n}', '$groupedCount')}';
    } else {
      description = '$memberName ${a['description'] ?? ''}';
    }

    return FeedItem(
      actorName: memberName,
      text: description,
      time: timeStr,
      photoUrl: memberPhoto,
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
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.expense),
            ),
          ),
        if (_isOwner)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _delete,
              icon: const Icon(Icons.delete_forever),
              label: Text(S.of(context, 'deleteFamily')),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.expense),
            ),
          ),
      ],
    );
  }
}
