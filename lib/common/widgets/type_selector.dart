import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

class TypeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final List<String> types;

  const TypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.types = const ['income', 'expense', 'transfer_out'],
  });

  @override
  Widget build(BuildContext context) {
    final labels = {
      'income': S.of(context, 'income'),
      'expense': S.of(context, 'expense'),
      'transfer_out': S.of(context, 'transfer'),
    };

    final children = <Widget>[];
    for (var i = 0; i < types.length; i++) {
      if (i > 0) children.add(const SizedBox(width: 4));
      final type = types[i];
      final selected = value == type;
      children.add(Expanded(
        child: GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              labels[type] ?? type,
              style: AppTextStyles.buttonLabel.copyWith(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.divider.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: children),
    );
  }
}
