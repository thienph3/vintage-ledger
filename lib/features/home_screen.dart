import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/features/wallet/services/wallet_service.dart';
import 'package:vintage_ledger/features/transaction/services/transaction_service.dart';
import 'package:vintage_ledger/features/category/services/category_service.dart';

import 'package:vintage_ledger/features/wallet/models/wallet.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

import 'package:vintage_ledger/common/widgets/amount_text.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/common/widgets/income_expense_summary_row.dart';
import 'package:vintage_ledger/features/transaction/widgets/chart_section.dart';
import 'package:vintage_ledger/features/transaction/widgets/transaction_section.dart';

import 'package:vintage_ledger/features/wallet/screens/wallet_form_screen.dart';
import 'package:vintage_ledger/features/wallet/screens/wallet_detail_screen.dart';
import 'package:vintage_ledger/features/wallet/screens/wallet_list_screen.dart';
import 'package:vintage_ledger/features/transaction/screens/transaction_form_screen.dart';
import 'package:vintage_ledger/features/settings/screens/setting_screen.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WalletService walletService = WalletService();
  final TransactionService transactionService = TransactionService();
  final CategoryService categoryService = CategoryService();

  List<Wallet> wallets = [];
  List<TransactionWithItems> recentTransactions = [];
  List<TransactionWithItems> monthTransactions = [];
  Map<int, Category> categoryMap = {};

  int totalBalance = 0;
  bool _amountVisible = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final w = await walletService.getWallets();
    final recent = await transactionService.getRecentWithItems(5);
    final month = await transactionService.getByDateRangeWithItems(
      monthStart.millisecondsSinceEpoch,
      monthEnd.millisecondsSinceEpoch,
    );
    final c = await categoryService.getCategories();

    setState(() {
      wallets = w;
      recentTransactions = recent;
      monthTransactions = month;
      categoryMap = {for (var c in c) c.id!: c};
      totalBalance = w.fold<int>(0, (sum, wallet) => sum + wallet.balance);
    });
  }

  int get _monthIncome => monthTransactions
      .where((t) => t.transaction.type == 'income')
      .fold(0, (sum, t) => sum + t.transaction.amount);

  int get _monthExpense => monthTransactions
      .where((t) => t.transaction.type == 'expense')
      .fold(0, (sum, t) => sum + t.transaction.amount);

  Future<void> _addTransaction() async {
    if (wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context, 'createWalletFirst')),
          backgroundColor: AppColors.divider,
        ),
      );
      return;
    }
    final result = await context.pushScreen(const TransactionFormScreen());
    if (result == true) loadData();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'homeTitle'),
      showBackButton: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () async {
            await context.pushScreen(const SettingScreen());
            loadData();
          },
        ),
      ],
      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _buildBalanceCard(),
            const SizedBox(height: AppSpacing.lg),
            _buildWalletRow(),
            const SizedBox(height: AppSpacing.lg),
            LedgerCard(child: ChartSection(transactions: monthTransactions, categoryMap: categoryMap)),
            const SizedBox(height: AppSpacing.lg),
            LedgerCard(
              child: TransactionSection(
                transactions: recentTransactions,
                categoryMap: categoryMap,
                onAddTransaction: _addTransaction,
                onTapTransaction: (txn) async {
                  await context.pushScreen(TransactionFormScreen(
                    walletId: txn.transaction.walletId,
                    transaction: txn.transaction,
                  ));
                  loadData();
                },
                onDeleteTransaction: (txn) async {
                  await transactionService.deleteTransaction(
                    txn.transaction.id!,
                  );
                  loadData();
                },
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      fab: FloatingActionButton(
        onPressed: _addTransaction,
        backgroundColor: AppColors.inkBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ========================
  // BALANCE CARD
  // ========================

  Widget _buildBalanceCard() {
    return LedgerCard(
      child: Column(
        children: [
          Text(S.of(context, 'totalBalance'), style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          GestureDetector(
            onTap: () => setState(() => _amountVisible = !_amountVisible),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_amountVisible)
                  AmountText(
                    amount: totalBalance.abs(),
                    type: totalBalance >= 0 ? 'income' : 'expense',
                    fontSize: 28,
                  )
                else
                  Text('••••••', style: AppTextStyles.title.copyWith(fontSize: 28)),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  _amountVisible ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                  color: AppColors.inkBlue,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.arrow_downward,
                  color: AppColors.income,
                  label: S.of(context, 'monthIncome'),
                  amount: _monthIncome,
                  type: 'income',
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.arrow_upward,
                  color: AppColors.expense,
                  label: S.of(context, 'monthExpense'),
                  amount: _monthExpense,
                  type: 'expense',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required Color color,
    required String label,
    required int amount,
    required String type,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (_amountVisible)
          AmountText(amount: amount, type: type)
        else
          Text('••••', style: AppTextStyles.amount),
      ],
    );
  }

  // ========================
  // WALLET ROW
  // ========================

  Widget _buildWalletRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(S.of(context, 'myWallets'), style: AppTextStyles.title),
            InkWell(
              onTap: () async {
                await context.pushScreen(const WalletListScreen());
                loadData();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(S.of(context, 'viewAll'), style: AppTextStyles.link),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 90,
          child: wallets.isEmpty
              ? _buildAddWalletCard()
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: wallets.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    if (index == wallets.length) return _buildAddWalletCard();
                    return _buildWalletCard(wallets[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWalletCard(Wallet wallet) {
    return GestureDetector(
      onTap: () async {
        await context.pushScreen(WalletDetailScreen(wallet: wallet));
        loadData();
      },
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  size: 16,
                  color: AppColors.inkBlue,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    wallet.name,
                    style: AppTextStyles.bodyBold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (_amountVisible)
              AmountText(
                amount: wallet.balance.abs(),
                type: wallet.balance >= 0 ? 'income' : 'expense',
              )
            else
              Text('••••', style: AppTextStyles.amount),
          ],
        ),
      ),
    );
  }

  Widget _buildAddWalletCard() {
    return GestureDetector(
      onTap: () async {
        final result = await context.pushScreen(const WalletFormScreen());
        if (result == true) loadData();
      },
      child: Container(
        width: 90,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.add, color: AppColors.inkBlue, size: 28),
        ),
      ),
    );
  }
}
