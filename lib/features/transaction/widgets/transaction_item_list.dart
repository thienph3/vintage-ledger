import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/amount_input_field.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_item.dart';

class TransactionItemEntry {
  final TransactionItemModel item;
  final TextEditingController amountController;
  final TextEditingController noteController;

  TransactionItemEntry({
    required this.item,
    required this.amountController,
    required this.noteController,
  });

  void dispose() {
    amountController.dispose();
    noteController.dispose();
  }
}

class TransactionItemList extends StatelessWidget {
  final List<TransactionItemEntry> items;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const TransactionItemList({
    super.key,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.of(context, 'transactionDetails'), style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: e.noteController,
                    decoration: InputDecoration(
                      hintText: S.of(context, 'itemNameHint'),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: AmountInputField(controller: e.amountController),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppColors.inkRed),
                  onPressed: () => onRemove(i),
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: Text(S.of(context, 'addItem')),
          ),
        ),
      ],
    );
  }
}
