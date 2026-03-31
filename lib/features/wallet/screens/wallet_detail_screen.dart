import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/features/category/services/category_service.dart';
import 'package:vintage_ledger/features/wallet/services/wallet_service.dart';
import 'package:vintage_ledger/features/transaction/services/transaction_service.dart';

import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

import 'package:vintage_ledger/common/widgets/amount_text.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/features/transaction/widgets/transaction_section.dart';
import 'package:vintage_ledger/features/transaction/widgets/chart_section.dart';

import 'package:vintage_ledger/features/transaction/screens/transaction_form_screen.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

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

  List<TransactionWithItems> recentTransactions = [];
  List<TransactionWithItems> monthTransactions = [];
  Map<int, Category> categoryMap = {};
  int balance = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final walletId = widget.wallet.id!;

    final recent = await transactionService.getRecentWithItems(
      5,
      walletId: walletId,
    );
    final month = await transactionService.getByDateRangeWithItems(
      monthStart.millisecondsSinceEpoch,
      monthEnd.millisecondsSinceEpoch,
      walletId: walletId,
    );
    final w = await walletService.getWallet(walletId);
    final c = await categoryService.getCategories();

    setState(() {
      recentTransactions = recent;
      monthTransactions = month;
      balance = w!.balance;
      categoryMap = {for (var cat in c) cat.id!: cat};
    });
  }

  Future<void> openForm() async {
    final result = await context.pushScreen(
      TransactionFormScreen(walletId: widget.wallet.id!),
    );
    if (result == true) await loadData();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.wallet.name,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            LedgerCard(
              child: Row(
                children: [
                  Text(
                    "${S.of(context, 'balance')}:",
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  AmountText(
                    amount: balance.abs(),
                    type: balance >= 0 ? "income" : "expense",
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            LedgerCard(child: ChartSection(transactions: monthTransactions, categoryMap: categoryMap)),
            const SizedBox(height: AppSpacing.md),

            LedgerCard(
              child: TransactionSection(
                walletId: widget.wallet.id!,
                transactions: recentTransactions,
                categoryMap: categoryMap,
                onAddTransaction: openForm,
                onTapTransaction: (txn) async {
                  final result = await context.pushScreen(TransactionFormScreen(
                    walletId: txn.transaction.walletId,
                    transaction: txn.transaction,
                  ));
                  if (result == true) await loadData();
                },
                onDeleteTransaction: (txn) async {
                  await transactionService.deleteTransaction(
                    txn.transaction.id!,
                  );
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
