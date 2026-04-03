import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final String? emoji;

  const EmptyState({super.key, required this.message, this.emoji});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(emoji!, style: const TextStyle(fontSize: 40)),
              ),
            Text(
              message,
              style: AppTextStyles.hint,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
