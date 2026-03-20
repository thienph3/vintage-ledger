import 'package:flutter/material.dart';
import 'amount_text.dart';

class TransactionTile extends StatelessWidget {

  final String category;
  final int amount;
  final String type;
  final String date;

  const TransactionTile({
    super.key,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {

    return ListTile(
      title: Text(category),
      subtitle: Text(date),
      trailing: AmountText(
        amount: amount,
        type: type,
      ),
    );
  }
}