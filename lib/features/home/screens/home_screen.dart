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
import 'package:vintage_ledger/features/quick_add/quick_add_bar.dart';
import 'package:vintage_ledger/features/transaction/screens/transaction_form_screen.dart';
import 'package:vintage_ledger/features/transaction/repositories/transaction_repository.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';
import 'package:vintage_ledger/common/widgets/amount_text.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TransactionWithItems> _todayTxns = [];
  Map<String, String> _categoryNames = {};
  Map<String, int?> _categoryIcons = {};
  bool _loading = true;
  String? _accountName;
  String? _defaultWalletId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

      final txns = await TransactionRepository().getByDateRange(
        todayStart.millisecondsSinceEpoch,
        todayEnd.millisecondsSinceEpoch,
      );
      final cats = await sl.categoryService.getCategories();
      final account = await sl.accountService.getAccount(sl.appState.currentAccountId);
      final walletId = await sl.settingService.getLastWalletId();
      sl.settingService.recordDailyUsage();

      if (!mounted) return;
      setState(() {
        _todayTxns = txns;
        _categoryNames = {for (var c in cats) if (c.id != null) c.id!: c.name};
        _categoryIcons = {for (var c in cats) if (c.id != null) c.id!: c.icon};
        _accountName = account?.name;
        _defaultWalletId = walletId;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _todayExpense => _todayTxns
      .where((t) => t.transaction.type == TransactionType.expense)
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
          body: Column(
            children: [
              const NetworkStatusBanner(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          children: [
                            _buildTodayTotal(),
                            const SizedBox(height: AppSpacing.lg),
                            _buildFeed(),
                          ],
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
                  onAdded: _load,
                )
              else
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(S.of(context, 'firstRunHint'), style: AppTextStyles.hint, textAlign: TextAlign.center),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayTotal() {
    final locale = Localizations.localeOf(context).languageCode;
    final hasExpense = _todayExpense > 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Text(
            hasExpense
                ? S.of(context, 'todaySpent').replaceAll('{amount}', AmountFormatter.formatCompactCurrency(_todayExpense, locale))
                : S.of(context, 'noTransactions'),
            style: hasExpense
                ? AppTextStyles.title.copyWith(fontSize: 20)
                : AppTextStyles.hint,
            textAlign: TextAlign.center,
          ),
          if (_todayTxns.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                '${_todayTxns.length} ${S.of(context, 'transactionCount')}',
                style: AppTextStyles.caption,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeed() {
    if (_todayTxns.isEmpty) {
      return EmptyState(
        emoji: '📝',
        message: S.of(context, 'emptyTransactionHint'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.of(context, 'recentTransactions'), style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        ..._todayTxns.map((t) => _buildFeedItem(t)),
      ],
    );
  }

  Widget _buildFeedItem(TransactionWithItems txn) {
    final catName = _categoryNames[txn.transaction.categoryId] ?? S.of(context, 'other');
    final catIcon = _categoryIcons[txn.transaction.categoryId];
    final time = DateFormatter.time(txn.transaction.date);

    return GestureDetector(
      onTap: () async {
        final result = await context.pushScreen(TransactionFormScreen(
          walletId: txn.transaction.walletId,
          existing: txn,
        ));
        if (result == true) _load();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(getCategoryIcon(catIcon), size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(catName, style: AppTextStyles.body),
                  if (txn.transaction.note != null && txn.transaction.note!.isNotEmpty)
                    Text(txn.transaction.note!, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AmountText(amount: txn.transaction.amount, type: txn.transaction.type, compact: true),
                Text(time, style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
