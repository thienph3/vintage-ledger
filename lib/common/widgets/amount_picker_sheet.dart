import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/common/widgets/amount_keypad.dart';

class AmountPickerSheet extends StatelessWidget {
  final int value;
  final ValueChanged<String> onInput;
  final VoidCallback onDone;

  const AmountPickerSheet({
    super.key,
    required this.value,
    required this.onInput,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    value > 0
                        ? AmountFormatter.formatCurrency(value, Localizations.localeOf(context).languageCode)
                        : S.of(context, 'enterAmount'),
                    style: value > 0
                        ? AppTextStyles.title.copyWith(color: AppColors.inkBlue)
                        : AppTextStyles.hint,
                  ),
                ),
                TextButton(
                  onPressed: onDone,
                  child: Text(S.of(context, 'done')),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            AmountKeypad(onInput: onInput),
          ],
        ),
      ),
    );
  }
}
