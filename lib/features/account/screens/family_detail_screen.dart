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
      setState(() {
        _members = members;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _invite() async {
    final email = await _showEmailDialog();
    if (email == null || email.isEmpty) return;

    try {
      await sl.accountService.inviteMember(
        accountId: widget.account.id,
        email: email,
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<String?> _showEmailDialog() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(ctx, 'inviteMember')),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: S.of(ctx, 'email'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.of(ctx, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(S.of(ctx, 'save')),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(String memberId) async {
    final confirm = await showDeleteConfirmation(
      context,
      titleKey: 'leaveFamily',
      contentKey: 'removeMemberConfirm',
    );
    if (confirm != true) return;

    await sl.accountService.removeMember(
      accountId: widget.account.id,
      memberId: memberId,
    );
    _load();
  }

  Future<void> _leave() async {
    final confirm = await showDeleteConfirmation(
      context,
      titleKey: 'leaveFamily',
      contentKey: 'leaveFamilyConfirm',
    );
    if (confirm != true) return;

    await sl.accountService.leaveFamily(
      accountId: widget.account.id,
      userId: sl.appState.currentUserId!,
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirm = await showDeleteConfirmation(
      context,
      titleKey: 'deleteFamily',
      contentKey: 'deleteFamilyConfirm',
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
            // Members header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(S.of(context, 'members'), style: AppTextStyles.title),
                if (_isOwner)
                  IconButton(
                    icon: const Icon(Icons.person_add, color: AppColors.inkBlue),
                    onPressed: _invite,
                  ),
              ],
            ),
            const Divider(),

            // Member list
            ..._members.map((m) {
              final isCurrentUser = m['id'] == sl.appState.currentUserId;
              final isMemberOwner = m['id'] == widget.account.ownerId;
              return LedgerCard(
                child: Row(
                  children: [
                    Icon(
                      isMemberOwner ? Icons.star : Icons.person,
                      color: AppColors.inkBlue,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['name'] ?? '', style: AppTextStyles.bodyBold),
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
              );
            }),

            const SizedBox(height: AppSpacing.xl),

            // Actions
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

            if (_isOwner) ...[
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
          ],
        ),
      ),
    );
  }
}
