import 'package:flutter/material.dart';

import '../../models/wallet.dart';
import '../../models/category.dart';
import '../../services/category_service.dart';
import '../../services/wallet_service.dart';
import '../../services/transaction_service.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

import '../../widgets/amount_text.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/ledger_card.dart';
import '../../widgets/transaction_section.dart';
import '../../widgets/chart_section.dart'; // giả sử bạn đã có chart-section

import '../transaction/transaction_form_screen.dart';

class WalletDetailScreen extends StatefulWidget {
  final Wallet wallet;

  const WalletDetailScreen({super.key, required this.wallet});

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  final TransactionService transactionService = TransactionService();
  final WalletService walletService = WalletService();
  final CategoryService categoryService = CategoryService();

  List<TransactionWithItems> transactions = [];
  Map<int, Category> categoryMap = {};
  int balance = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final t = await transactionService.getByWalletWithItems(widget.wallet.id!);
    final w = await walletService.getWallet(widget.wallet.id!);
    final c = await categoryService.getCategories();

    setState(() {
      transactions = t;
      balance = w!.balance;
      categoryMap = {for (var cat in c) cat.id!: cat};
    });
  }

  Future<void> openForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(walletId: widget.wallet.id!),
      ),
    );

    if (result == true) {
      await loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.wallet.name,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            /// BALANCE CARD
            LedgerCard(
              child: Row(
                children: [
                  Text("Số dư:", style: AppTextStyles.body),
                  const SizedBox(width: AppSpacing.md),
                  AmountText(
                    amount: balance.abs(),
                    type: balance >= 0 ? "income" : "expense",
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            /// CHART SECTION (tóm tắt thu chi)
            LedgerCard(
              child: ChartSection(
                transactions: transactions,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            /// TRANSACTION SECTION
            LedgerCard(
              child: TransactionSection(
                walletId: widget.wallet.id!,
                transactions: transactions,
                categoryMap: categoryMap,
                onAddTransaction: openForm,
                onTapTransaction: (txn) async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionFormScreen(
                        walletId: txn.transaction.walletId,
                        transaction: txn.transaction,
                      ),
                    ),
                  );
                  if (result == true) {
                    await loadData();
                  }
                },
                onDeleteTransaction: (txn) async {
                  await transactionService.deleteTransaction(txn.transaction.id!);
                  await loadData();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}