import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/common/widgets/amount_history.dart';

class AmountPickerSheet extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onDone;

  const AmountPickerSheet({
    super.key,
    required this.controller,
    required this.onDone,
  });

  List<int> _dynamicChips(String text) {
    final base = int.tryParse(text) ?? 0;
    if (base <= 0) return const [];
    final chips = <int>[];
    if (base < 1000) chips.add(base * 1000);
    if (base < 100) chips.add(base * 10000);
    if (base < 10) chips.add(base * 100000);
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Input row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.title,
                    decoration: InputDecoration(
                      hintText: S.of(context, 'enterAmount'),
                      hintStyle: AppTextStyles.hint,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onDone,
                  child: Text(S.of(context, 'done'), style: AppTextStyles.link),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Chips
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final text = value.text.trim();
                final chips = text.isEmpty
                    ? AmountHistory.topAmounts()
                    : _dynamicChips(text);

                if (chips.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: chips.map((amount) {
                      final selected = (int.tryParse(text) ?? 0) == amount;
                      return GestureDetector(
                        onTap: () {
                          controller.text = amount.toString();
                          controller.selection = TextSelection.collapsed(offset: controller.text.length);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            AmountFormatter.formatCurrency(amount, locale),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: selected ? Colors.white : AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
