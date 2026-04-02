import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/features/insights/models/insight.dart';

class InsightCard extends StatelessWidget {
  final Insight insight;

  const InsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: LedgerCard(
        child: Row(
          children: [
            Icon(insight.icon, size: 22, color: insight.color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                _resolveMessage(context, insight.message),
                style: AppTextStyles.bodySmall.copyWith(color: insight.color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _resolveMessage(BuildContext context, String encoded) {
    final parts = encoded.split('|');
    final key = parts[0];
    final template = S.of(context, key);

    return switch (parts.length) {
      2 => template.replaceAll('{amount}', parts[1]).replaceAll('{pct}', parts[1]),
      3 => template.replaceAll('{category}', parts[1]).replaceAll('{amount}', parts[2]),
      _ => template,
    };
  }
}
