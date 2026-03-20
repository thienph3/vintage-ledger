import 'package:flutter/material.dart';

import 'amount_keypad.dart';

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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AmountKeypad(onInput: onInput),
          ],
        ),
      ),
    );
  }
}