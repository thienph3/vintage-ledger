import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/features/transaction/models/dashboard_data.dart';

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

import 'package:vintage_ledger/features/account/screens/account_picker_screen.dart';
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
  int _dirtyCount = 0;

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
      _loadDirtyCount();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  int get _monthIncome => _dashboard?.monthIncome ?? 0;

  int get _monthExpense => _dashboard?.monthExpense ?? 0;

  Future<void> _loadDirtyCount() async {
    if (!sl.appState.isLoggedIn) return;
    try {
      final count = await sl.syncService.getDirtyCount(sl.appState.currentAccountId);
      setState(() => _dirtyCount = count);
    } catch (_) {}
  }

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
      showBackButton: sl.appState.isLoggedIn,
      actions: [
        if (sl.appState.isLoggedIn)
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountPickerScreen()),
                  );
                },
              ),
              if (_dirtyCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.expense,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
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
              if (_dashboard != null)
                LedgerCard(child: ChartSection(dashboard: _dashboard!)),
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
                  AmountText.fromBalance(
                    balance: _dashboard?.balance ?? 0,
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
                  type: TransactionType.income,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.arrow_upward,
                  color: AppColors.expense,
                  label: S.of(context, 'monthExpense'),
                  amount: _monthExpense,
                  type: TransactionType.expense,
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
    required TransactionType type,
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
              AmountText.fromBalance(balance: wallet.balance)
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
