import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/network_status_banner.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';
import 'package:vintage_ledger/common/widgets/quick_actions_fab.dart';
import 'package:vintage_ledger/features/transaction/widgets/transaction_feed_item.dart';
import 'package:vintage_ledger/features/wallet/screens/wallet_form_screen.dart';
import 'package:vintage_ledger/features/quick_add/quick_add_bar.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _defaultWalletId;

  late final DateTime _todayStart;
  late final DateTime _todayEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _todayStart = DateTime(now.year, now.month, now.day);
    _todayEnd = _todayStart.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    _defaultWalletId = sl.cache.lastWalletId;
    sl.settingService.recordDailyUsage();
  }

  Map<String, String> get _categoryNames => sl.cache.categoryNameMap;
  String? get _accountName => sl.cache.currentAccount?.name;

  Future<void> _refresh() async {
    sl.cache.setCategories(await sl.categoryService.getCategories());
    if (mounted) setState(() {});
  }

  Stream<List<TransactionWithItems>> get _todayStream =>
      sl.transactionService.watchByDateRange(
        _todayStart.millisecondsSinceEpoch,
        _todayEnd.millisecondsSinceEpoch,
      );

  int _todayExpense(List<TransactionWithItems> txns) => txns
      .where((t) =>
          t.transaction.type == TransactionType.expense ||
          (t.transaction.type.isTransferOut && t.transaction.toAccountId != null))
      .fold(0, (s, t) => s + t.transaction.amount);

  String? _resolveDefaultWallet(List<Wallet> wallets) {
    if (_defaultWalletId != null && wallets.any((w) => w.id == _defaultWalletId)) {
      return _defaultWalletId;
    }
    return wallets.firstOrNull?.id;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Wallet>>(
      stream: sl.walletService.watchWallets(),
      builder: (context, walletSnap) {
        final wallets = walletSnap.data ?? [];

        return AppScaffold(
          title: _accountName ?? S.of(context, 'homeTitle'),
          showBackButton: false,
          fab: const QuickActionsFab(bottomOffset: 80),
          body: Column(
            children: [
              const NetworkStatusBanner(),
              Expanded(
                child: StreamBuilder<List<TransactionWithItems>>(
                        stream: _todayStream,
                        builder: (context, txnSnap) {
                          final todayTxns = txnSnap.data ?? [];
                          return RefreshIndicator(
                            onRefresh: _refresh,
                            child: ListView(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              children: [
                                _buildTodayTotal(todayTxns),
                                const SizedBox(height: AppSpacing.lg),
                                _buildFeed(todayTxns),
                              ],
                            ),
                          );
                        },
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
                  onAdded: _refresh,
                )
              else
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: EmptyState(
                    emoji: '👛',
                    message: S.of(context, 'firstRunHint'),
                    action: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await context.pushScreen(const WalletFormScreen());
                        if (result == true) _refresh();
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(S.of(context, 'addWallet')),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayTotal(List<TransactionWithItems> todayTxns) {
    final locale = Localizations.localeOf(context).languageCode;
    final expense = _todayExpense(todayTxns);
    final hasExpense = expense > 0;
    final greeting = _greeting();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        boxShadow: [AppColors.cardShadow],
      ),
      child: Column(
        children: [
          Text(greeting, style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasExpense
                ? S.of(context, 'todaySpent').replaceAll('{amount}', AmountFormatter.formatCompactCurrency(expense, locale))
                : S.of(context, 'noTransactions'),
            style: hasExpense ? AppTextStyles.headline : AppTextStyles.hint,
            textAlign: TextAlign.center,
          ),
          if (todayTxns.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                '${todayTxns.length} ${S.of(context, 'transactionCount')}',
                style: AppTextStyles.caption,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeed(List<TransactionWithItems> todayTxns) {
    if (todayTxns.isEmpty) {
      return EmptyState(
        emoji: '📝',
        message: S.of(context, 'emptyTransactionHint'),
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.of(context, 'recentTransactions'), style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          ...todayTxns.map((t) => TransactionFeedItem(
            txn: t,
            categoryName: _categoryNames[t.transaction.categoryId] ?? S.of(context, 'other'),
            onChanged: _refresh,
            timeFormatter: DateFormatter.time,
            walletNames: sl.cache.walletNameMap,
          )),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return S.of(context, 'greetingMorning');
    if (hour < 18) return S.of(context, 'greetingAfternoon');
    return S.of(context, 'greetingEvening');
  }
}
