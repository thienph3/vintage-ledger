import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';

import 'package:vintage_ledger/features/wallet/models/wallet.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

import 'package:vintage_ledger/common/widgets/amount_text.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/common/widgets/async_content.dart';
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
  List<Wallet> wallets = [];
  DashboardData? _dashboard;
  bool _loading = true;
  String? _error;
  bool _amountVisible = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final w = await sl.walletService.getWallets();
      final dashboard = await sl.transactionService.getDashboard();
      setState(() {
        wallets = w;
        _dashboard = dashboard;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  int get _monthIncome => _dashboard?.monthly
      .where((t) => t.transaction.type.isIncome)
      .fold(0, (sum, t) => sum + t.transaction.amount) ?? 0;

  int get _monthExpense => _dashboard?.monthly
      .where((t) => t.transaction.type.isExpense)
      .fold(0, (sum, t) => sum + t.transaction.amount) ?? 0;

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
      body: AsyncContent(
        loading: _loading,
        error: _error,
        child: RefreshIndicator(
          onRefresh: loadData,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _buildBalanceCard(),
              const SizedBox(height: AppSpacing.lg),
              _buildWalletRow(),
              const SizedBox(height: AppSpacing.lg),
              LedgerCard(child: ChartSection(
                transactions: _dashboard?.monthly ?? [],
                categoryMap: _dashboard?.categoryMap ?? {},
              )),
              const SizedBox(height: AppSpacing.lg),
              LedgerCard(
                child: TransactionSection(
                  transactions: _dashboard?.recent ?? [],
                  categoryMap: _dashboard?.categoryMap ?? {},
                  onDataChanged: loadData,
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
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
                    amount: (_dashboard?.balance ?? 0).abs(),
                    type: (_dashboard?.balance ?? 0) >= 0 ? 'income' : 'expense',
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
