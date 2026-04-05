import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/selection_sheet.dart';

class DropdownField<T> extends StatelessWidget {
  final String label;
  final String? value;
  final IconData? prefixIcon;
  final List<SelectionItem<T>> items;
  final T? selected;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  const DropdownField({
    super.key,
    required this.label,
    this.value,
    this.prefixIcon,
    required this.items,
    this.selected,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: selected,
      validator: validator,
      builder: (state) {
        return GestureDetector(
          onTap: () async {
            final result = await showSelectionSheet<T>(
              context: context,
              title: label,
              items: items,
              selected: selected,
            );
            if (result != null) {
              onChanged(result);
              state.didChange(result);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
              suffixIcon: const Icon(Icons.unfold_more, size: 18),
              errorText: state.errorText,
            ),
            child: Text(
              value ?? '',
              style: AppTextStyles.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}
