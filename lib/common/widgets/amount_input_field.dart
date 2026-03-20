import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/common/widgets/amount_picker_sheet.dart';

class AmountInputField extends StatelessWidget {
  final TextEditingController controller;

  const AmountInputField({
    super.key,
    required this.controller,
  });

  int parseAmount() {
    final text = controller.text.replaceAll('.', '');
    return int.tryParse(text) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        int tempValue = parseAmount();

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
                    } else {
                      final add = int.tryParse(input) ?? 0;

                      if (input == "000") {
                        tempValue *= 1000;
                      } else {
                        tempValue = tempValue * 10 + add;
                      }
                    }
                    controller.text = tempValue.toString();
                  });
                }

                return AmountPickerSheet(
                  value: tempValue,
                  onInput: handleInput,
                  onDone: () {
                    Navigator.pop(context, tempValue);
                  },
                );
              },
            );
          },
        );
      },

      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            return Text(
              value.text.isEmpty ? "Nhập số tiền" : AmountFormatter.formatCurrency(int.tryParse(value.text) ?? 0),
              style: AppTextStyles.body.copyWith(color: AppColors.inkPurple),
            );
          },
        )
      ),
    );
  }
}