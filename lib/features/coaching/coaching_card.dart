import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/features/coaching/coaching_tip.dart';
import 'package:vintage_ledger/features/coaching/coaching_service.dart';

class CoachingCard extends StatelessWidget {
  final CoachingTip tip;
  final VoidCallback onDismissed;

  const CoachingCard({super.key, required this.tip, required this.onDismissed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: LedgerCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(tip.icon, size: 22, color: AppColors.inkBlue),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tip.message, style: AppTextStyles.hint),
                  if (tip.actionLabel != null && tip.action != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: GestureDetector(
                        onTap: tip.action,
                        child: Text(tip.actionLabel!, style: AppTextStyles.link.copyWith(color: AppColors.inkBlue)),
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                CoachingService.dismiss(tip.dismissKey);
                onDismissed();
              },
              child: const Icon(Icons.close, size: 16, color: AppColors.divider),
            ),
          ],
        ),
      ),
    );
  }
}
