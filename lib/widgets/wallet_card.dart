import 'package:flutter/material.dart';
import '../../widgets/amount_text.dart';

class WalletCard extends StatelessWidget {

  final String name;
  final int balance;
  final VoidCallback? onTap;

  const WalletCard({
    super.key,
    required this.name,
    required this.balance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text("Balance"),
        trailing: AmountText(
          amount: balance.abs(),
          type: balance >= 0 ? "income" : "expense",
        ),
        onTap: onTap,
      ),
    );
  }
}