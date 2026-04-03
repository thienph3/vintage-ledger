import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/common/widgets/amount_keypad.dart';

const _quickAmounts = [10000, 20000, 50000, 100000, 200000, 500000];

class AmountPickerSheet extends StatelessWidget {
  final int value;
  final ValueChanged<String> onInput;
  final VoidCallback onDone;
  final ValueChanged<int>? onQuickSelect;

  const AmountPickerSheet({
    super.key,
    required this.value,
    required this.onInput,
    required this.onDone,
    this.onQuickSelect,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Amount display + done button
            Row(
              children: [
                Expanded(
                  child: Text(
                    value > 0
                        ? AmountFormatter.formatCurrency(value, locale)
                        : S.of(context, 'enterAmount'),
                    style: value > 0
                        ? AppTextStyles.title.copyWith(color: AppColors.primary)
                        : AppTextStyles.hint,
                  ),
                ),
                TextButton(
                  onPressed: onDone,
                  child: Text(S.of(context, 'done'), style: AppTextStyles.link),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Quick amount chips
            if (onQuickSelect != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickAmounts.map((amount) {
                    final selected = value == amount;
                    return GestureDetector(
                      onTap: () => onQuickSelect!(amount),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          AmountFormatter.formatCompact(amount, locale),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: selected ? Colors.white : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Keypad
            AmountKeypad(onInput: onInput),
          ],
        ),
      ),
    );
  }
}
