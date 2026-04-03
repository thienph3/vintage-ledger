import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

class AmountKeypad extends StatelessWidget {
  final Function(String) onInput;

  const AmountKeypad({super.key, required this.onInput});

  Widget _key(String value) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onInput(value),
        child: Container(
          height: 52,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(value, style: AppTextStyles.keypad),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [_key("1"), _key("2"), _key("3")]),
        Row(children: [_key("4"), _key("5"), _key("6")]),
        Row(children: [_key("7"), _key("8"), _key("9")]),
        Row(
          children: [
            _key("000"),
            _key("0"),
            Expanded(
              child: GestureDetector(
                onTap: () => onInput("BACKSPACE"),
                child: Container(
                  height: 52,
                  margin: const EdgeInsets.all(3),
                  alignment: Alignment.center,
                  child: Icon(Icons.backspace_outlined, color: AppColors.textSecondary, size: 22),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
