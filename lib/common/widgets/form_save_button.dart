import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';

class FormSaveButton extends StatelessWidget {
  final bool isEdit;
  final VoidCallback onPressed;

  const FormSaveButton({
    super.key,
    required this.isEdit,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(isEdit ? S.of(context, 'update') : S.of(context, 'save')),
      ),
    );
  }
}
