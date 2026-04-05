import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

class TypeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const TypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.divider.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _pill(context, 'income', S.of(context, 'income')),
          const SizedBox(width: 4),
          _pill(context, 'expense', S.of(context, 'expense')),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String type, String label) {
    final selected = value == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.buttonLabel.copyWith(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
