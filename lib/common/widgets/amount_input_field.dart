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

  const AmountInputField({super.key, required this.controller, this.currency = 'VND', this.label, this.showZero = false});

  int _parseAmount() {
    final text = controller.text.replaceAll('.', '');
    return int.tryParse(text) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        );

        int tempValue = _parseAmount();

        if (!context.mounted) return;
        await showModalBottomSheet<int>(
          context: context,
          isScrollControlled: true,
          isDismissible: true,
          builder: (_) {
            return StatefulBuilder(
              builder: (context, setState) {
                void handleInput(String input) {
                  setState(() {
                    if (input == "BACKSPACE") {
                      tempValue = tempValue ~/ 10;
                    } else if (input == "000") {
                      tempValue *= 1000;
                    } else {
                      tempValue = tempValue * 10 + (int.tryParse(input) ?? 0);
                    }
                    controller.text = tempValue.toString();
                  });
                }

                return AmountPickerSheet(
                  value: tempValue,
                  onInput: handleInput,
                  onDone: () => Navigator.pop(context, tempValue),
                  onQuickSelect: (amount) {
                    setState(() {
                      tempValue = amount;
                      controller.text = tempValue.toString();
                    });
                  },
                );
              },
            );
          },
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
