import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/app_snackbar.dart';
import 'package:vintage_ledger/features/account/models/invite_token.dart';

class JoinFamilyScreen extends StatefulWidget {
  final String tokenId;

  const JoinFamilyScreen({super.key, required this.tokenId});

  @override
  State<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends State<JoinFamilyScreen> {
  InviteToken? _token;
  String? _familyName;
  bool _loading = true;
  bool _joining = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      final token = await sl.accountService.getInviteToken(widget.tokenId);
      if (token == null) {
        setState(() { _loading = false; _error = 'Invite not found'; });
        return;
      }
      if (token.isExpired) {
        setState(() { _loading = false; _error = S.of(context, 'inviteExpired'); });
        return;
      }
      setState(() {
        _token = token;
        _familyName = token.accountName;
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _join() async {
    final userId = sl.appState.currentUserId;
    if (userId == null || _token == null) return;

    setState(() => _joining = true);
    try {
      await sl.accountService.joinByInvite(tokenId: widget.tokenId, userId: userId);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.toString(), backgroundColor: const Color(0xFF8B1E1E));
      setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'inviteMember'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: _loading
              ? const CircularProgressIndicator()
              : _error != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.inkRed),
                        const SizedBox(height: AppSpacing.md),
                        Text(_error!, style: AppTextStyles.body, textAlign: TextAlign.center),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.family_restroom, size: 64, color: AppColors.inkBlue),
                        const SizedBox(height: AppSpacing.lg),
                        Text(_familyName ?? '', style: AppTextStyles.title),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          child: _joining
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: _join,
                                  child: Text(S.of(context, 'inviteMember')),
                                ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
