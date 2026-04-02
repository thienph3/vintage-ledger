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
import 'package:vintage_ledger/common/widgets/network_status_banner.dart';
import 'package:vintage_ledger/common/widgets/app_snackbar.dart';
import 'package:vintage_ledger/features/transaction/widgets/transaction_section.dart';
import 'package:vintage_ledger/features/insights/services/insight_service.dart';
import 'package:vintage_ledger/features/insights/widgets/insight_card.dart';
import 'package:vintage_ledger/features/insights/models/insight.dart';

import 'package:vintage_ledger/features/account/screens/account_picker_screen.dart';
import 'package:vintage_ledger/features/wallet/screens/wallet_form_screen.dart';
import 'package:vintage_ledger/features/wallet/screens/wallet_detail_screen.dart';
import 'package:vintage_ledger/features/wallet/screens/wallet_list_screen.dart';
import 'package:vintage_ledger/features/transaction/screens/transaction_form_screen.dart';
import 'package:vintage_ledger/features/quick_add/quick_add_bar.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/core/constants/currency.dart' as curr;
import 'package:vintage_ledger/utils/navigator_x.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DashboardData? _dashboard;
  bool _loading = true;
  String? _error;
  bool _amountVisible = false;
  String? _defaultWalletId;
  String? _accountName;
  Insight? _topInsight;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final dashboard = await sl.transactionService.getDashboard();
      final lastWalletId = await sl.settingService.getLastWalletId();
      final account = await sl.accountService.getAccount(sl.appState.currentAccountId);
      final locale = Localizations.localeOf(context).languageCode;
      final insights = InsightService.generate(dashboard, const [], locale);
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _defaultWalletId = lastWalletId;
        _accountName = account?.name;
        _topInsight = insights.isNotEmpty ? insights.first : null;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _addTransaction(List<Wallet> wallets) async {
    if (wallets.isEmpty) {
      showAppSnackBar(context, S.of(context, 'createWalletFirst'), backgroundColor: AppColors.divider);
      return;
    }
    final result = await context.pushScreen(const TransactionFormScreen());
    if (result == true) _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Wallet>>(
      stream: sl.walletService.watchWallets(),
      builder: (context, walletSnap) {
        final wallets = walletSnap.data ?? [];

        return AppScaffold(
          title: _accountName?.toUpperCase() ?? S.of(context, 'homeTitle'),
          showBackButton: false,
          actions: [
            if (sl.appState.isLoggedIn && !sl.authService.isAnonymous)
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountPickerScreen()),
                  );
                },
              ),
          ],
          body: Column(
            children: [
              const NetworkStatusBanner(),
              Expanded(
                child: AsyncContent(
                  loading: _loading && !walletSnap.hasData,
                  error: _error,
                  child: RefreshIndicator(
                    onRefresh: _loadDashboard,
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        _buildBalanceCard(wallets),
                        const SizedBox(height: AppSpacing.lg),
                        _buildWalletRow(wallets),
                        const SizedBox(height: AppSpacing.lg),
                        if (_topInsight != null)
                          InsightCard(insight: _topInsight!),
                        LedgerCard(
                          child: TransactionSection(
                            transactions: _dashboard?.recent ?? [],
                            categoryMap: _dashboard?.categoryMap ?? {},
                            onDataChanged: _loadDashboard,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),
              ),
              if (wallets.isNotEmpty)
                QuickAddBar(
                  walletId: _resolveDefaultWallet(wallets),
                  wallets: wallets,
                  onWalletChanged: (id) {
                    sl.settingService.setLastWalletId(id);
                    setState(() => _defaultWalletId = id);
                  },
                  onAdded: _loadDashboard,
                )
              else
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    S.of(context, 'firstRunHint'),
                    style: AppTextStyles.hint,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
          fab: wallets.isEmpty ? FloatingActionButton(
            onPressed: () => _addTransaction(wallets),
            backgroundColor: AppColors.inkBlue,
            child: const Icon(Icons.add, color: Colors.white),
          ) : null,
        );
      },
    );
  }

  Widget _buildBalanceCard(List<Wallet> wallets) {
    final currencies = wallets.map((w) => w.currency).toSet();
    final isMixed = currencies.length > 1;
    final currency = isMixed ? 'VND' : (currencies.firstOrNull ?? 'VND');

    int? approxBalance;
    if (isMixed && wallets.isNotEmpty) {
      approxBalance = wallets.fold<int>(0, (sum, w) => sum + curr.Currency.toVnd(w.balance, w.currency));
    }

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
                  isMixed && approxBalance != null
                      ? Text(
                          '\u2248 ${AmountFormatter.formatCurrency(approxBalance, Localizations.localeOf(context).languageCode)}',
                          style: AppTextStyles.title.copyWith(fontSize: 22),
                        )
                      : AmountText.fromBalance(balance: _dashboard?.balance ?? 0, currency: currency, fontSize: 28)
                else
                  Text('••••••', style: AppTextStyles.title.copyWith(fontSize: 28)),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  _amountVisible ? Icons.visibility : Icons.visibility_off,
                  size: 20, color: AppColors.inkBlue,
                ),
              ],
            ),
          ),
          if (_amountVisible && isMixed)
            Text(S.of(context, 'approximateTooltip'), style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.arrow_downward, color: AppColors.income,
                  label: S.of(context, 'monthIncome'),
                  amount: _dashboard?.monthIncome ?? 0,
                  type: TransactionType.income,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.arrow_upward, color: AppColors.expense,
                  label: S.of(context, 'monthExpense'),
                  amount: _dashboard?.monthExpense ?? 0,
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
    required IconData icon, required Color color,
    required String label, required int amount, required TransactionType type,
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
        if (_amountVisible) AmountText(amount: amount, type: type)
        else Text('••••', style: AppTextStyles.amount),
      ],
    );
  }

  String? _resolveDefaultWallet(List<Wallet> wallets) {
    if (_defaultWalletId != null && wallets.any((w) => w.id == _defaultWalletId)) {
      return _defaultWalletId;
    }
    return wallets.firstOrNull?.id;
  }

  Widget _buildWalletRow(List<Wallet> wallets) {
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
                _loadDashboard();
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
                  separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
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
    final isDefault = wallet.id == _defaultWalletId;

    return GestureDetector(
      onTap: () async {
        await context.pushScreen(WalletDetailScreen(wallet: wallet));
        _loadDashboard();
      },
      onLongPress: () {
        sl.settingService.setLastWalletId(wallet.id!);
        setState(() => _defaultWalletId = wallet.id);
        showAppSnackBar(context, '${wallet.name} → ${S.of(context, 'defaultWallet')}');
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
                Stack(
                  children: [
                    const Icon(Icons.account_balance_wallet, size: 16, color: AppColors.inkBlue),
                    if (isDefault)
                      const Positioned(
                        right: -4, bottom: -4,
                        child: Icon(Icons.star, size: 10, color: Color(0xFFE6A817)),
                      ),
                  ],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(wallet.name, style: AppTextStyles.bodyBold, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            if (_amountVisible)
              AmountText.fromBalance(balance: wallet.balance, currency: wallet.currency)
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
        if (result == true) _loadDashboard();
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
