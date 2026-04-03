import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/common/widgets/amount_picker_sheet.dart';

class AmountInputField extends StatelessWidget {
  final TextEditingController controller;
  final String currency;
  final String? label;
  final bool showZero;

  const AmountInputField({
    super.key,
    required this.controller,
    this.currency = 'VND',
    this.label,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        );

        if (!context.mounted) return;
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: true,
          builder: (_) => AmountPickerSheet(
            controller: controller,
            onDone: () => Navigator.pop(context),
          ),
        );
      },
      child: AbsorbPointer(
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final amount = int.tryParse(value.text) ?? 0;
            final locale = Localizations.localeOf(context).languageCode;
            return InputDecorator(
              decoration: InputDecoration(
                labelText: label ?? S.of(context, 'amount'),
                suffixIcon: const Icon(Icons.dialpad, size: 20),
              ),
              child: Text(
                amount > 0 || showZero
                    ? AmountFormatter.formatCurrency(amount, locale, currencyCode: currency)
                    : S.of(context, 'enterAmount'),
                style: amount > 0 || showZero ? AppTextStyles.amount : AppTextStyles.hint,
              ),
            );
          },
        ),
      ),
    );
  }
}
