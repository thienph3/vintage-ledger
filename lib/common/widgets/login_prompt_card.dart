import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/features/auth/screens/register_screen.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

class LoginPromptCard extends StatelessWidget {
  final int transactionCount;
  final int? firstUseDayCount;

  const LoginPromptCard({super.key, required this.transactionCount, this.firstUseDayCount});

  @override
  Widget build(BuildContext context) {
    if (!sl.authService.isAnonymous) return const SizedBox.shrink();

    // Smart trigger: ≥5 transactions OR ≥3 days usage
    final shouldShow = transactionCount >= 5 || (firstUseDayCount != null && firstUseDayCount! >= 3);
    if (!shouldShow) return const SizedBox.shrink();

    return LedgerCard(
      child: Row(
        children: [
          const Icon(Icons.cloud_upload_outlined, color: AppColors.inkBlue, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(S.of(context, 'anonymousExplanation'), style: AppTextStyles.bodySmall),
          ),
          TextButton(
            onPressed: () => context.pushScreen(const RegisterScreen()),
            child: Text(S.of(context, 'register'), style: AppTextStyles.link),
          ),
        ],
      ),
    );
  }
}
